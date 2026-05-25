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

  /// Resolves the parashah slug to its Mon/Thu reading text. Returns null
  /// if no mapping entry exists (which indicates an unmapped parashah
  /// name from kosher_dart — a coding bug, not a user issue).
  Future<String?> loadMonThuReading(String parashahSlug) async {
    final mapping = await _loadMonThuMapping();
    final segmentId = mapping[parashahSlug];
    if (segmentId == null) return null;

    final manifestRaw = await _bundle.loadString(_manifestPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
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
