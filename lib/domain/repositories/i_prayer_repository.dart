import '../entities/prayer_segment.dart';
import '../entities/prayer_template.dart';

abstract class IPrayerRepository {
  Future<PrayerTemplate> loadTemplate(String templateId);
  Future<PrayerSegment> loadNusachSegment(String nusach, String segmentId);
}
