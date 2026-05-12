import '../entities/nusach_override.dart';
import '../entities/prayer_segment.dart';
import '../entities/prayer_template.dart';

abstract class IPrayerRepository {
  Future<PrayerTemplate> loadTemplate(String templateId);
  Future<PrayerSegment> loadSegment(String segmentId);
  Future<NusachOverride?> loadNusachOverride(String nusach, String prayerId);
}
