import 'package:smart_siddur/core/calendar/hebrew_date.dart';

abstract final class HebrewFormatter {
  // ── Numeral conversion ──────────────────────────────────────────────────────

  static const _units = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
  static const _tens = ['', 'י', 'כ', 'ל', 'מ', 'נ', 'ס', 'ע', 'פ', 'צ'];
  static const _hundreds = [
    '', 'ק', 'ר', 'ש', 'ת', 'תק', 'תר', 'תש', 'תת', 'תתק'
  ];

  // Returns a Gematria string with geresh (׳) for 1 letter, gershayim (״)
  // before the last letter for 2+.  Special-cases 15 and 16 to avoid the
  // divine name combinations יה / יו.
  static String toHebrewNumeral(int n) {
    if (n == 15) return 'ט״ו';
    if (n == 16) return 'ט״ז';

    final buf = StringBuffer();
    var rem = n;
    if (rem >= 100) {
      buf.write(_hundreds[rem ~/ 100]);
      rem = rem % 100;
    }
    if (rem >= 10) {
      buf.write(_tens[rem ~/ 10]);
      rem = rem % 10;
    }
    if (rem > 0) {
      buf.write(_units[rem]);
    }

    final s = buf.toString();
    if (s.length == 1) return '$s׳';
    return '${s.substring(0, s.length - 1)}״${s[s.length - 1]}';
  }

  // Uses last 3 digits of the Hebrew year (drops the thousands).
  static String formatHebrewYear(int year) => toHebrewNumeral(year % 1000);

  // ── Month names ─────────────────────────────────────────────────────────────

  static String monthName(int month) => switch (month) {
        1 => 'ניסן',
        2 => 'אייר',
        3 => 'סיון',
        4 => 'תמוז',
        5 => 'אב',
        6 => 'אלול',
        7 => 'תשרי',
        8 => 'חשון',
        9 => 'כסלו',
        10 => 'טבת',
        11 => 'שבט',
        12 => 'אדר',
        13 => 'אדר ב׳',
        _ => '',
      };

  // ── Day of week ─────────────────────────────────────────────────────────────

  static String dayOfWeekName(int weekday) => switch (weekday) {
        DateTime.sunday => 'יום ראשון',
        DateTime.monday => 'יום שני',
        DateTime.tuesday => 'יום שלישי',
        DateTime.wednesday => 'יום רביעי',
        DateTime.thursday => 'יום חמישי',
        DateTime.friday => 'יום שישי',
        DateTime.saturday => 'שבת קודש',
        _ => '',
      };

  // ── Full date string ─────────────────────────────────────────────────────────

  // Returns e.g. "יום שלישי, כ״א תשרי תשפ״ה"
  static String formatFullDate(HebrewDate date) {
    final dow = dayOfWeekName(date.dayOfWeek);
    final day = toHebrewNumeral(date.day);
    final month = monthName(date.month);
    final year = formatHebrewYear(date.year);
    return '$dow, $day $month $year';
  }

  // ── Nusach display names ─────────────────────────────────────────────────────

  static String nusachName(String nusach) => switch (nusach) {
        'ashkenaz' => 'אשכנז',
        'sfard' => 'ספרד',
        'edot_mizrach' => 'עדות המזרח',
        'chabad' => 'חב״ד',
        _ => nusach,
      };
}
