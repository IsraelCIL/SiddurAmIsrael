import '../../domain/entities/prayer_segment.dart';
import '../../domain/entities/prayer_template.dart';
import '../../domain/repositories/i_prayer_repository.dart';
import '../datasources/local/prayer_local_datasource.dart';

class PrayerRepositoryImpl implements IPrayerRepository {
  const PrayerRepositoryImpl(this._datasource);

  final PrayerLocalDatasource _datasource;

  @override
  Future<PrayerTemplate> loadTemplate(String templateId) =>
      _datasource.loadTemplate(templateId);

  @override
  Future<PrayerSegment> loadNusachSegment(String nusach, String segmentId) =>
      _datasource.loadNusachSegment(nusach, segmentId);
}
