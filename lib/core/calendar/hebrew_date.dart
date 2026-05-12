import 'package:kosher_dart/kosher_dart.dart';

/// Thin facade over [JewishCalendar] that exposes the Hebrew date fields
/// needed by the rest of the app. All calendar arithmetic is delegated to
/// the kosher_dart library.
class HebrewDate {
  const HebrewDate({
    required this.year,
    required this.month,
    required this.day,
    required this.dayOfWeek,
  });

  final int year;
  final int month; // JewishDate month constants: NISSAN=1 … TISHREI=7 … ADAR=12, ADAR_II=13
  final int day;
  final int dayOfWeek; // Dart DateTime convention: 1=Monday … 7=Sunday

  // ── Month constants (mirrors JewishDate statics) ─────────────────────────
  static const nisan   = JewishDate.NISSAN;   // 1
  static const iyar    = JewishDate.IYAR;     // 2
  static const sivan   = JewishDate.SIVAN;    // 3
  static const tammuz  = JewishDate.TAMMUZ;   // 4
  static const av      = JewishDate.AV;       // 5
  static const elul    = JewishDate.ELUL;     // 6
  static const tishri  = JewishDate.TISHREI;  // 7
  static const cheshvan = JewishDate.CHESHVAN; // 8
  static const kislev  = JewishDate.KISLEV;   // 9
  static const tevet   = JewishDate.TEVES;    // 10
  static const shvat   = JewishDate.SHEVAT;   // 11
  static const adar    = JewishDate.ADAR;     // 12 (also Adar I in leap year)
  static const adarI   = JewishDate.ADAR;     // 12
  static const adarII  = JewishDate.ADAR_II;  // 13

  bool get isShabbat => dayOfWeek == DateTime.saturday;

  // ── Factory: Gregorian → Hebrew (via kosher_dart) ────────────────────────
  factory HebrewDate.fromGregorian(DateTime gregorian) {
    final cal = JewishCalendar.fromDateTime(gregorian);
    return HebrewDate(
      year: cal.getJewishYear(),
      month: cal.getJewishMonth(),
      day: cal.getJewishDayOfMonth(),
      dayOfWeek: gregorian.weekday,
    );
  }

  // ── Calendar helpers ──────────────────────────────────────────────────────

  // Metonic cycle: 7 of every 19 years are leap years
  static bool isLeapYear(int year) => ((7 * year) + 1) % 19 < 7;

  static int monthsInYear(int year) => isLeapYear(year) ? 13 : 12;

  // Delegate to library for correct Cheshvan/Kislev variable lengths
  static int daysInMonth(int month, int year) {
    final jd = JewishDate()..setJewishDate(year, month, 1);
    return jd.getDaysInJewishMonth();
  }

  @override
  String toString() => '$day/$month/$year (dow:$dayOfWeek)';
}
