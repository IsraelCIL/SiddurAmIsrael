import 'package:smart_siddur/data/datasources/local/omer_mapping_datasource.dart';
import 'package:smart_siddur/domain/entities/omer_day.dart';
import 'package:smart_siddur/domain/repositories/i_omer_mapping_repository.dart';

class OmerMappingRepositoryImpl implements IOmerMappingRepository {
  const OmerMappingRepositoryImpl(this._datasource);

  final OmerMappingDatasource _datasource;

  @override
  Future<OmerDay> loadDay(int day) => _datasource.loadDay(day);
}
