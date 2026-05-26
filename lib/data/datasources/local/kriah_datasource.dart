import 'dart:convert';

import 'package:flutter/services.dart';

class KriahDatasource {
  KriahDatasource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String _manifestPath = 'assets/prayers/_manifest.json';

  final AssetBundle _bundle;
  Map<String, String>? _monThuMappingCache;

  Future<Map<String, String>> _loadMonThuMapping() async {
    if (_monThuMappingCache != null) return _monThuMappingCache!;
    final manifestRaw = await _bundle.loadString(_manifestPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final mapPath =
        (manifest['common'] as Map)['_kriah_mon_thu_mapping'] as String;
    final raw = await _bundle.loadString(mapPath);
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    return _monThuMappingCache =
        parsed.map((k, v) => MapEntry(k, v as String));
  }

  /// Loads a segment's joined text by manifest common-key. Returns null
  /// when the key is not present in manifest.common.
  Future<String?> _loadCommonSegmentText(String key) async {
    final manifestRaw = await _bundle.loadString(_manifestPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final p = (manifest['common'] as Map)[key];
    if (p is! String) return null;
    final segRaw = await _bundle.loadString(p);
    final seg = jsonDecode(segRaw) as Map<String, dynamic>;
    final sections = (seg['sections'] as List).cast<Map<String, dynamic>>();
    final lines = <String>[];
    for (final s in sections) {
      final t = s['text'];
      if (t is List) {
        lines.addAll(t.cast<String>());
      } else if (t is String) {
        lines.add(t);
      }
    }
    return lines.join(' ');
  }

  /// Resolves the parashah slug to its Mon/Thu reading text. Returns null
  /// if no mapping entry exists (which indicates an unmapped parashah
  /// name from kosher_dart — a coding bug, not a user issue).
  Future<String?> loadMonThuReading(String parashahSlug) async {
    final mapping = await _loadMonThuMapping();
    final segmentId = mapping[parashahSlug];
    if (segmentId == null) return null;
    return _loadCommonSegmentText(segmentId);
  }

  /// RC-Tevet composite: the full RC reading is collapsed into 3 olim —
  /// olim 1-2 unchanged, and the original 3rd + 4th portions
  /// (וּבְרָאשֵׁי חָדְשֵׁיכֶם …) are merged into oleh 3. The new oleh 4
  /// reads the Chanukah day-N passage. We achieve this by stripping the
  /// original "— רביעי —" marker (joining its text to shlishi) and
  /// appending a fresh marker + Chanukah text.
  Future<String?> loadRcTevetComposite(int chanukahDay) async {
    final rcText = await _loadCommonSegmentText('kriah_rc');
    final chanText =
        await _loadCommonSegmentText('kriah_chanukah_day_$chanukahDay');
    if (rcText == null || chanText == null) return null;
    final reviiMarkerRe = RegExp(r'\s*<b>—?\s*רביעי[^<]*—?</b>\s*');
    final rcMerged = rcText.replaceFirst(reviiMarkerRe, ' ').trimRight();
    // Strip internal oleh division markers from the Chanukah portion —
    // it serves as a single 4th oleh with no internal divisions.
    final internalMarkerRe = RegExp(r'\s*<b>(כהן|לוי|ישראל|שני|שלישי|רביעי)</b>\s*');
    final chanClean = chanText.replaceAll(internalMarkerRe, ' ').trim();
    return '$rcMerged <b>רביעי</b> $chanClean';
  }
}
