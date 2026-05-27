import 'package:smart_siddur/domain/entities/omer_day.dart';

/// Loads the per-day Sefirat HaOmer mapping
/// (`assets/prayers/maariv/sefirat_haomer/_omer_mapping.json`).
abstract class IOmerMappingRepository {
  /// Returns the mapping for a single counting day.
  /// [day] is 1..49. Throws if out of range.
  Future<OmerDay> loadDay(int day);
}
