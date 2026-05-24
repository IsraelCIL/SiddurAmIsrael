import '../entities/sukkot_korban.dart';

/// Loads the per-day Sukkot Musaf korban mapping
/// (`assets/prayers/musaf/sukkot/_sukkot_korbanot_mapping.json`).
abstract class ISukkotKorbanotRepository {
  /// Returns the mapping for a single Sukkot day.
  /// [day] is 1..7. Throws if out of range.
  Future<SukkotKorban> loadDay(int day);
}
