import 'package:siddur_am_israel_chai/data/datasources/local/gra_ssy_datasource.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_gra_ssy_repository.dart';

class GraSsyRepositoryImpl implements IGraSsyRepository {
  GraSsyRepositoryImpl(this._ds);

  final GraSsyDatasource _ds;

  @override
  Future<String?> resolveChapter({
    required String chag,
    required int yt1Weekday,
    required int dayInChag,
  }) async {
    final segId = await _ds.resolveSegmentId(
      chag: chag,
      yt1Weekday: yt1Weekday,
      dayInChag: dayInChag,
    );
    if (segId == null) return null;
    return _ds.loadChapterText(segId);
  }
}
