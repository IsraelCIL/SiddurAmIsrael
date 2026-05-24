import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/entities/prayer_segment.dart';
import '../../../domain/entities/prayer_template.dart';

class PrayerLocalDatasource {
  PrayerLocalDatasource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String _manifestPath = 'assets/prayers/_manifest.json';

  final AssetBundle _bundle;
  Future<_Manifest>? _manifestFuture;

  Future<_Manifest> _manifest() {
    return _manifestFuture ??= _loadManifest();
  }

  Future<_Manifest> _loadManifest() async {
    final raw = await _bundle.loadString(_manifestPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _Manifest.fromJson(json);
  }

  Future<PrayerTemplate> loadTemplate(String templateId) async {
    final manifest = await _manifest();
    final path = manifest.templates[templateId] ??
        'assets/prayers/templates/$templateId.json';
    final json = await _readJson(path);
    return PrayerTemplate.fromJson(json);
  }

  Future<PrayerSegment> loadNusachSegment(
    String nusach,
    String segmentId,
  ) async {
    final manifest = await _manifest();
    final nusachPath = manifest.nusach[nusach]?[segmentId];
    if (nusachPath != null) {
      final json = await _readJson(nusachPath);
      return PrayerSegment.fromJson(json);
    }
    final commonPath = manifest.common[segmentId];
    if (commonPath != null) {
      final json = await _readJson(commonPath);
      return PrayerSegment.fromJson(json);
    }
    throw Exception(
      'Segment "$segmentId" not found in manifest for nusach "$nusach" '
      'and not present under common/.',
    );
  }

  Future<Map<String, dynamic>> _readJson(String path) async {
    final raw = await _bundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _normalizeTextFields(json);
  }

  static Map<String, dynamic> _normalizeTextFields(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);
    for (final key in ['text', 'default_text']) {
      final value = result[key];
      if (value is List) {
        result[key] = (value as List<dynamic>).map((e) => e as String).join(' ');
      }
    }
    if (result['variants'] is Map) {
      final variants = Map<String, dynamic>.from(result['variants'] as Map);
      for (final k in variants.keys.toList()) {
        final value = variants[k];
        if (value is List) {
          variants[k] = (value as List<dynamic>).map((e) => e as String).join(' ');
        }
      }
      result['variants'] = variants;
    }
    if (result['sections'] is List) {
      result['sections'] = (result['sections'] as List<dynamic>).map((s) {
        if (s is Map<String, dynamic>) return _normalizeTextFields(s);
        return s;
      }).toList();
    }
    return result;
  }
}

class _Manifest {
  _Manifest({
    required this.templates,
    required this.nusach,
    required this.common,
  });

  final Map<String, String> templates;
  final Map<String, Map<String, String>> nusach;
  final Map<String, String> common;

  factory _Manifest.fromJson(Map<String, dynamic> json) {
    Map<String, String> asStringMap(dynamic raw) {
      if (raw is! Map) return <String, String>{};
      return raw.map((k, v) => MapEntry(k as String, v as String));
    }

    final nusachRaw = json['nusach'];
    final nusach = <String, Map<String, String>>{};
    if (nusachRaw is Map) {
      for (final entry in nusachRaw.entries) {
        nusach[entry.key as String] = asStringMap(entry.value);
      }
    }

    return _Manifest(
      templates: asStringMap(json['templates']),
      nusach: nusach,
      common: asStringMap(json['common']),
    );
  }
}
