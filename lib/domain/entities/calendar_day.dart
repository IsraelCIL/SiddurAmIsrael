import 'package:siddur_am_israel_chai/core/calendar/hebrew_date.dart';

/// A single labeled zman row (e.g. "סוף זמן ק״ש" · "מג״א" · 08:33).
class ZmanEntry {
  const ZmanEntry(this.label, this.time, {this.note});

  final String label;

  /// Computed time, or null if undefined for the location/date (polar edge).
  final DateTime? time;

  /// Optional shita / qualifier, e.g. "מג״א", "גר״א", "רבינו תם".
  final String? note;
}

/// A label/value row for the "מידע נוסף ליום" section (e.g. Daf Yomi).
class InfoRow {
  const InfoRow(this.label, this.value);
  final String label;
  final String value;
}

/// An upcoming event for the "מועדים קרובים" list.
class UpcomingEvent {
  const UpcomingEvent(this.name, this.hebrewDate, this.daysUntil);
  final String name;

  /// e.g. "א׳ כסלו".
  final String hebrewDate;
  final int daysUntil;
}

/// All information for a single calendar day at a given location: the Hebrew
/// date, holiday/parsha/omer tags, Daf Yomi, and the full zmanim list.
class CalendarDay {
  const CalendarDay({
    required this.gregorian,
    required this.hebrew,
    required this.dayOfWeekLabel,
    required this.hebrewDateLabel,
    required this.gregorianLabel,
    required this.tags,
    required this.isShabbat,
    required this.isYomTov,
    required this.zmanim,
    required this.shabbatZmanim,
    required this.shabbatNotes,
    required this.extraInfo,
    required this.upcoming,
    this.parsha,
    this.dafYomi,
  });

  final DateTime gregorian;
  final HebrewDate hebrew;

  /// e.g. "שבת קודש" / "יום שלישי".
  final String dayOfWeekLabel;

  /// e.g. "י״ז תשרי תשפ״ו".
  final String hebrewDateLabel;

  /// e.g. "9 October 2025".
  final String gregorianLabel;

  /// Holiday / Chol HaMoed / Rosh Chodesh / Omer labels (may be empty).
  final List<String> tags;

  final bool isShabbat;
  final bool isYomTov;

  /// Weekly parsha (Shabbat) prefixed with "פרשת", or null.
  final String? parsha;

  /// Daf Yomi (Bavli) label, or null.
  final String? dafYomi;

  /// Full day zmanim (always populated).
  final List<ZmanEntry> zmanim;

  /// Candle-lighting / havdalah rows — non-empty only on erev/Shabbat/Yom Tov.
  final List<ZmanEntry> shabbatZmanim;

  /// Special-Shabbat notes (שבת מברכים, שבת זכור/פרה/החדש…), may be empty.
  final List<String> shabbatNotes;

  /// Extra per-day info rows (Daf Yomi, …), may be empty.
  final List<InfoRow> extraInfo;

  /// Upcoming events (next holidays / Rosh Chodesh / fasts).
  final List<UpcomingEvent> upcoming;
}
