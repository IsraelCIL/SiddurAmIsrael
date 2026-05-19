import '../entities/nusach_segment_text.dart';
import '../entities/prayer_segment.dart';
import '../entities/prayer_template.dart';

abstract class IPrayerRepository {
  Future<PrayerTemplate> loadTemplate(String templateId);
  Future<PrayerSegment> loadSegment(String segmentId);
  Future<NusachSegmentText?> loadNusachSegmentText(String nusach, String segmentId);
}
