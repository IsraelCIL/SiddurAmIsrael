import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Referential-integrity audit of the prayer asset graph.
///
/// Walks every prayer template reachable from the top-level roots
/// (assets/prayers/templates/*.json) and verifies — with the exact same
/// resolution rules as [PrayerLocalDatasource] — that:
///
///  1. every `sub_template_id` resolves to an existing template file
///     (manifest `templates` entry, or the implicit
///     `assets/prayers/templates/<id>.json` fallback);
///  2. every `segment_id` resolves for every nusach under which the entry
///     is reachable (nusach map, falling back to `common`);
///  3. every resolved asset path is covered by a `pubspec.yaml` assets
///     declaration (Flutter directory declarations are NON-recursive);
///  4. every manifest path points to a file that exists;
///  5. every reachable `segment_id` has an entry in `segment_labels.dart`
///     (CLAUDE.md rule: the raw English id must never reach the user).
///
/// Regression guard for the 17 Tammuz 5786 production crash, where selichot
/// templates existed on disk but were unregistered in the manifest and the
/// fallback path pointed at the wrong directory.
void main() {
  const nuschaot = ['ashkenaz', 'sfard', 'edot_mizrach'];
  final root = Directory.current.path;

  Map<String, dynamic> readJson(String relPath) =>
      jsonDecode(File('$root/$relPath').readAsStringSync())
          as Map<String, dynamic>;

  final manifest = readJson('assets/prayers/_manifest.json');
  final templatesMap =
      (manifest['templates'] as Map<String, dynamic>? ?? {}).cast<String, String>();
  final commonMap = (manifest['common'] as Map<String, dynamic>).cast<String, String>();
  final nusachMaps = (manifest['nusach'] as Map<String, dynamic>).map(
    (n, m) => MapEntry(n, (m as Map<String, dynamic>).cast<String, String>()),
  );

  // pubspec asset declarations: directories end with '/', files do not.
  final assetDecls = RegExp(r'^\s*-\s+(assets/\S+)\s*$', multiLine: true)
      .allMatches(File('$root/pubspec.yaml').readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();
  final assetDirs = assetDecls.where((d) => d.endsWith('/')).toSet();
  final assetFiles = assetDecls.where((d) => !d.endsWith('/')).toSet();
  bool covered(String path) =>
      assetDirs.contains(path.substring(0, path.lastIndexOf('/') + 1)) ||
      assetFiles.contains(path);

  final labelKeys = RegExp(r"'([a-z0-9_]+)'\s*:")
      .allMatches(
          File('$root/lib/presentation/constants/segment_labels.dart')
              .readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();

  bool exists(String relPath) => File('$root/$relPath').existsSync();

  // Same resolution as PrayerLocalDatasource.loadTemplate.
  String templatePath(String id) =>
      templatesMap[id] ?? 'assets/prayers/templates/$id.json';

  // Same resolution as PrayerLocalDatasource.loadNusachSegment.
  String? segmentPath(String nusach, String id) =>
      nusachMaps[nusach]?[id] ?? commonMap[id];

  final brokenTemplates = <String>[];
  final brokenSegments = <String>[];
  final uncovered = <String>[];
  final missingLabels = <String>{};
  final visited = <String>{};

  void visit(String templateId, List<String> reachableNuschaot, String via) {
    final key = '$templateId|${reachableNuschaot.join(',')}';
    if (!visited.add(key)) return;

    final path = templatePath(templateId);
    if (!exists(path)) {
      brokenTemplates.add('$templateId -> $path (referenced by $via)');
      return;
    }
    if (!covered(path)) uncovered.add('template $path (via $via)');

    final template = readJson(path);
    for (final raw in (template['segments'] as List<dynamic>? ?? [])) {
      final entry = raw as Map<String, dynamic>;
      var applicable = reachableNuschaot;
      final allowed =
          (entry['allowed_nusach'] as List<dynamic>? ?? []).cast<String>();
      if (allowed.isNotEmpty) {
        applicable = applicable.where(allowed.contains).toList();
      }
      if (applicable.isEmpty) continue;

      final subId = entry['sub_template_id'] as String? ?? '';
      if (subId.isNotEmpty) {
        visit(subId, applicable, templateId);
        continue;
      }

      final segId = entry['segment_id'] as String? ?? '';
      if (segId.isEmpty) continue;
      if (!labelKeys.contains(segId)) missingLabels.add(segId);
      for (final n in applicable) {
        final segPath = segmentPath(n, segId);
        if (segPath == null) {
          brokenSegments
              .add('"$segId" unresolvable for $n (template $templateId)');
        } else if (!exists(segPath)) {
          brokenSegments.add('"$segId" ($n) -> $segPath missing file');
        } else if (!covered(segPath)) {
          uncovered.add('segment $segPath (template $templateId, $n)');
        }
      }
    }
  }

  // Roots: top-level template files; nusach inferred from the id suffix.
  final rootFiles = Directory('$root/assets/prayers/templates')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));
  for (final f in rootFiles) {
    final id = f.uri.pathSegments.last.replaceAll('.json', '');
    final ns = id.endsWith('_edot_mizrach')
        ? ['edot_mizrach']
        : id.endsWith('_ashkenaz')
            ? ['ashkenaz']
            : id.endsWith('_sfard')
                ? ['sfard']
                : nuschaot;
    visit(id, ns, 'ROOT');
  }

  test('every reachable sub_template_id resolves to an existing template', () {
    expect(brokenTemplates, isEmpty,
        reason: 'Broken template refs (app crash):\n${brokenTemplates.join('\n')}');
  });

  test('every reachable segment_id resolves for its reachable nuschaot', () {
    expect(brokenSegments, isEmpty,
        reason: 'Broken segment refs (app crash):\n${brokenSegments.join('\n')}');
  });

  test('every reachable asset is covered by a pubspec assets declaration', () {
    expect(uncovered, isEmpty,
        reason: 'Bundled-asset gaps (crash in release build):\n${uncovered.join('\n')}');
  });

  test('every manifest path points to an existing file', () {
    final dead = <String>[
      for (final e in templatesMap.entries)
        if (!exists(e.value)) 'templates.${e.key} -> ${e.value}',
      for (final e in commonMap.entries)
        if (!exists(e.value)) 'common.${e.key} -> ${e.value}',
      for (final n in nusachMaps.entries)
        for (final e in n.value.entries)
          if (!exists(e.value)) 'nusach.${n.key}.${e.key} -> ${e.value}',
    ];
    expect(dead, isEmpty, reason: 'Manifest entries -> missing files:\n${dead.join('\n')}');
  });

  test('every reachable segment_id has a Hebrew label entry', () {
    expect(missingLabels, isEmpty,
        reason: 'Segment ids missing from segment_labels.dart '
            '(raw English id would reach the user):\n${missingLabels.join('\n')}');
  });
}
