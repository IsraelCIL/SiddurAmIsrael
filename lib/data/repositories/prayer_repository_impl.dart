import 'package:siddur_am_israel_chai/data/datasources/local/prayer_local_datasource.dart';
import 'package:siddur_am_israel_chai/domain/entities/prayer_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/prayer_template.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_prayer_repository.dart';

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
