import '../../domain/repositories/i_kriah_repository.dart';
import '../datasources/local/kriah_datasource.dart';

class KriahRepositoryImpl implements IKriahRepository {
  KriahRepositoryImpl(this._ds);

  final KriahDatasource _ds;

  @override
  Future<String?> loadMonThuReading(String parashahSlug) =>
      _ds.loadMonThuReading(parashahSlug);

  @override
  Future<String?> loadRcTevetComposite(int chanukahDay) =>
      _ds.loadRcTevetComposite(chanukahDay);
}
