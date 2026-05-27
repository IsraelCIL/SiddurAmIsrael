import 'package:smart_siddur/domain/entities/prayer_segment.dart';
import 'package:smart_siddur/domain/entities/prayer_template.dart';

abstract class IPrayerRepository {
  Future<PrayerTemplate> loadTemplate(String templateId);
  Future<PrayerSegment> loadNusachSegment(String nusach, String segmentId);
}
