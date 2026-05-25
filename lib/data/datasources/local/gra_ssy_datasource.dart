import 'dart:convert';

import 'package:flutter/services.dart';

class GraSsyDatasource {
  GraSsyDatasource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String _manifestPath = 'assets/prayers/_manifest.json';

  final AssetBundle _bundle;
  Map<String, dynamic>? _mappingCache;
  String? _mappingPath;

  Future<Map<String, dynamic>> _loadMapping() async {
    if (_mappingCache != null) return _mappingCache!;
    if (_mappingPath == null) {
      final raw = await _bundle.loadString(_manifestPath);
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      _mappingPath = (manifest['common'] as Map)['_gra_ssy_mapping'] as String;
    }
    final raw = await _bundle.loadString(_mappingPath!);
    _mappingCache = jsonDecode(raw) as Map<String, dynamic>;
    return _mappingCache!;
  }

  /// Looks up the Gr"a SSY segmentId for (chag, yt1Weekday, dayInChag).
  /// Returns null if no entry exists for that tuple.
  Future<String?> resolveSegmentId({
    required String chag,
    required int yt1Weekday,
    required int dayInChag,
  }) async {
    final mapping = await _loadMapping();
    final byChag = mapping[chag];
    if (byChag is! Map) return null;
    final byWeekday = byChag['$yt1Weekday'];
    if (byWeekday is! Map) return null;
    final segId = byWeekday['$dayInChag'];
    return segId is String ? segId : null;
  }

  /// Loads the resolved Tehillim text by segment_id (e.g. "tehillim_gra_78").
  /// Joins all sections of the segment file's `text` arrays with newlines.
  Future<String?> loadChapterText(String segmentId) async {
    final raw = await _bundle.loadString(_manifestPath);
    final manifest = jsonDecode(raw) as Map<String, dynamic>;
    final p = (manifest['common'] as Map)[segmentId];
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
}
