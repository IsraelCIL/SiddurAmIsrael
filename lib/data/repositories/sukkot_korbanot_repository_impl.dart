import '../../domain/entities/sukkot_korban.dart';
import '../../domain/repositories/i_sukkot_korbanot_repository.dart';
import '../datasources/local/sukkot_korbanot_datasource.dart';

class SukkotKorbanotRepositoryImpl implements ISukkotKorbanotRepository {
  const SukkotKorbanotRepositoryImpl(this._datasource);

  final SukkotKorbanotDatasource _datasource;

  @override
  Future<SukkotKorban> loadDay(int day) => _datasource.loadDay(day);
}
