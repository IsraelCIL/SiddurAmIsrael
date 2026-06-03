import 'package:siddur_am_israel_chai/data/datasources/local/sukkot_korbanot_datasource.dart';
import 'package:siddur_am_israel_chai/domain/entities/sukkot_korban.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_sukkot_korbanot_repository.dart';

class SukkotKorbanotRepositoryImpl implements ISukkotKorbanotRepository {
  const SukkotKorbanotRepositoryImpl(this._datasource);

  final SukkotKorbanotDatasource _datasource;

  @override
  Future<SukkotKorban> loadDay(int day) => _datasource.loadDay(day);
}
