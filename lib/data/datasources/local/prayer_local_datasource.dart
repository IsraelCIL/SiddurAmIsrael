import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/entities/prayer_segment.dart';
import '../../../domain/entities/prayer_template.dart';

class PrayerLocalDatasource {
  PrayerLocalDatasource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<PrayerTemplate> loadTemplate(String templateId) async {
    final json = await _readJson('assets/prayers/templates/$templateId.json');
    return PrayerTemplate.fromJson(json);
  }

  Future<PrayerSegment> loadNusachSegment(
    String nusach,
    String segmentId,
  ) async {
    try {
      final json = await _readJson(
        'assets/prayers/nusach/$nusach/$segmentId.json',
      );
      return PrayerSegment.fromJson(json);
    } catch (_) {
      // Fall back to common/ for segments identical across all nusachim
      // (biblical texts, shared psalms, kriat shema, etc.)
      final json = await _readJson(
        'assets/prayers/common/$segmentId.json',
      );
      return PrayerSegment.fromJson(json);
    }
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
