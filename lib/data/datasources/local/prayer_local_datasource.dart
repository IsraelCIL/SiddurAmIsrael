import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/entities/nusach_override.dart';
import '../../../domain/entities/prayer_segment.dart';
import '../../../domain/entities/prayer_template.dart';

class PrayerLocalDatasource {
  Future<PrayerTemplate> loadTemplate(String templateId) async {
    final json = await _readJson('assets/prayers/templates/$templateId.json');
    return PrayerTemplate.fromJson(json);
  }

  Future<PrayerSegment> loadSegment(String segmentId) async {
    final json = await _readJson('assets/prayers/segments/$segmentId.json');
    return PrayerSegment.fromJson(json);
  }

  Future<NusachOverride?> loadNusachOverride(
    String nusach,
    String prayerId,
  ) async {
    try {
      final json =
          await _readJson('assets/prayers/nusach/$nusach/$prayerId.json');
      return NusachOverride.fromJson(json);
    } catch (_) {
      // Asset is optional; return null when the file does not exist.
      return null;
    }
  }

  Future<Map<String, dynamic>> _readJson(String path) async {
    final raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
