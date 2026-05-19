import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/entities/nusach_segment_text.dart';
import '../../../domain/entities/prayer_segment.dart';
import '../../../domain/entities/prayer_template.dart';

class PrayerLocalDatasource {
  PrayerLocalDatasource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<PrayerTemplate> loadTemplate(String templateId) async {
    final json = await _readJson('assets/prayers/templates/$templateId.json');
    return PrayerTemplate.fromJson(json);
  }

  Future<PrayerSegment> loadSegment(String segmentId) async {
    final json = await _readJson('assets/prayers/segments/$segmentId.json');
    return PrayerSegment.fromJson(json);
  }

  Future<NusachSegmentText?> loadNusachSegmentText(
    String nusach,
    String segmentId,
  ) async {
    try {
      final json = await _readJson(
        'assets/prayers/nusach/$nusach/$segmentId.json',
      );
      return NusachSegmentText.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _readJson(String path) async {
    final raw = await _bundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
