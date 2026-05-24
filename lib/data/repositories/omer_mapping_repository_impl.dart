import '../../domain/entities/omer_day.dart';
import '../../domain/repositories/i_omer_mapping_repository.dart';
import '../datasources/local/omer_mapping_datasource.dart';

class OmerMappingRepositoryImpl implements IOmerMappingRepository {
  const OmerMappingRepositoryImpl(this._datasource);

  final OmerMappingDatasource _datasource;

  @override
  Future<OmerDay> loadDay(int day) => _datasource.loadDay(day);
}
