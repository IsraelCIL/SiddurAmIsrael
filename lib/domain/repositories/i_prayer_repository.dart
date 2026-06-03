import 'package:siddur_am_israel_chai/domain/entities/prayer_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/prayer_template.dart';

abstract class IPrayerRepository {
  Future<PrayerTemplate> loadTemplate(String templateId);
  Future<PrayerSegment> loadNusachSegment(String nusach, String segmentId);
}
