/// Resolves the Gr"a Shir Shel Yom Tehillim text for a given
/// (chag, weekday-of-YT1, day-in-chag) tuple.
///
/// `chag` ∈ {'pesach', 'sukkot'}. `yt1Weekday` is Dart's Mon=1..Sun=7.
/// `dayInChag` is 1-based from YT1.
///
/// Returns the resolved Hebrew text (verses joined with newlines), or
/// null if no entry exists for that tuple. A null return on a day where
/// the `gra_ssy_day` flag is set indicates a calendar bug.
abstract class IGraSsyRepository {
  Future<String?> resolveChapter({
    required String chag,
    required int yt1Weekday,
    required int dayInChag,
  });
}
