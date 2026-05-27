import 'package:smart_siddur/data/datasources/local/sukkot_korbanot_datasource.dart';
import 'package:smart_siddur/domain/entities/sukkot_korban.dart';
import 'package:smart_siddur/domain/repositories/i_sukkot_korbanot_repository.dart';

class SukkotKorbanotRepositoryImpl implements ISukkotKorbanotRepository {
  const SukkotKorbanotRepositoryImpl(this._datasource);

  final SukkotKorbanotDatasource _datasource;

  @override
  Future<SukkotKorban> loadDay(int day) => _datasource.loadDay(day);
}
