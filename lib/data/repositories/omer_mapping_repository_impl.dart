import 'package:siddur_am_israel_chai/data/datasources/local/omer_mapping_datasource.dart';
import 'package:siddur_am_israel_chai/domain/entities/omer_day.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_omer_mapping_repository.dart';

class OmerMappingRepositoryImpl implements IOmerMappingRepository {
  const OmerMappingRepositoryImpl(this._datasource);

  final OmerMappingDatasource _datasource;

  @override
  Future<OmerDay> loadDay(int day) => _datasource.loadDay(day);
}
