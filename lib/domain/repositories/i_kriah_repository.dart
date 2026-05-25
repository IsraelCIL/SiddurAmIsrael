/// Resolves the Torah-reading text for a given calendar context.
///
/// Phase E.8b only handles Monday/Thursday weekly-parashah readings;
/// future phases will extend with RC / CHM / Chanukah / Purim / fasts.
abstract class IKriahRepository {
  /// Returns the joined reading text for the upcoming parashah (Mon/Thu
  /// reading). `parashahSlug` is the lowercase enum name from kosher_dart
  /// (combined → first single — see HalachicCalendarService).
  Future<String?> loadMonThuReading(String parashahSlug);

  /// Returns a composite RC-Tevet reading: RC olim 1-3 (Bamidbar 28),
  /// truncated before the רביעי marker, immediately followed by the
  /// Chanukah day-N reading prefaced by a fresh "— רביעי —" marker.
  /// `chanukahDay` is 1..8.
  Future<String?> loadRcTevetComposite(int chanukahDay);
}
