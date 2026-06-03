import 'package:flutter_test/flutter_test.dart';
import 'package:siddur_am_israel_chai/core/calendar/hebrew_date.dart';
import 'package:siddur_am_israel_chai/core/utils/hebrew_formatter.dart';

void main() {
  group('toHebrewNumeral', () {
    test('single letter gets geresh', () {
      expect(HebrewFormatter.toHebrewNumeral(1), 'א׳');
      expect(HebrewFormatter.toHebrewNumeral(5), 'ה׳');
      expect(HebrewFormatter.toHebrewNumeral(9), 'ט׳');
      expect(HebrewFormatter.toHebrewNumeral(10), 'י׳');
      expect(HebrewFormatter.toHebrewNumeral(100), 'ק׳');
    });

    test('15 avoids divine name יה', () {
      expect(HebrewFormatter.toHebrewNumeral(15), 'ט״ו');
    });

    test('16 avoids divine name יו', () {
      expect(HebrewFormatter.toHebrewNumeral(16), 'ט״ז');
    });

    test('two-letter numbers get gershayim before last letter', () {
      expect(HebrewFormatter.toHebrewNumeral(11), 'י״א');
      expect(HebrewFormatter.toHebrewNumeral(21), 'כ״א');
      expect(HebrewFormatter.toHebrewNumeral(23), 'כ״ג');
      expect(HebrewFormatter.toHebrewNumeral(29), 'כ״ט');
    });

    test('three-letter numbers get gershayim before last letter', () {
      expect(HebrewFormatter.toHebrewNumeral(785), 'תשפ״ה');
      expect(HebrewFormatter.toHebrewNumeral(784), 'תשפ״ד');
    });

    test('round hundreds', () {
      expect(HebrewFormatter.toHebrewNumeral(200), 'ר׳');
      expect(HebrewFormatter.toHebrewNumeral(500), 'ת״ק');
    });
  });

  group('formatHebrewYear', () {
    test('drops thousands prefix', () {
      expect(HebrewFormatter.formatHebrewYear(5785), 'תשפ״ה');
      expect(HebrewFormatter.formatHebrewYear(5784), 'תשפ״ד');
    });
  });

  group('monthName', () {
    test('returns correct Hebrew month names', () {
      expect(HebrewFormatter.monthName(1), 'ניסן');
      expect(HebrewFormatter.monthName(7), 'תשרי');
      expect(HebrewFormatter.monthName(12), 'אדר');
      expect(HebrewFormatter.monthName(13), "אדר ב׳");
    });

    test('returns empty string for invalid month', () {
      expect(HebrewFormatter.monthName(0), '');
      expect(HebrewFormatter.monthName(14), '');
    });
  });

  group('dayOfWeekName', () {
    test('sunday → יום ראשון', () {
      expect(HebrewFormatter.dayOfWeekName(DateTime.sunday), 'יום ראשון');
    });

    test('saturday → שבת קודש', () {
      expect(HebrewFormatter.dayOfWeekName(DateTime.saturday), 'שבת קודש');
    });

    test('monday → יום שני', () {
      expect(HebrewFormatter.dayOfWeekName(DateTime.monday), 'יום שני');
    });

    test('friday → יום שישי', () {
      expect(HebrewFormatter.dayOfWeekName(DateTime.friday), 'יום שישי');
    });
  });

  group('nusachName', () {
    test('maps known nusachim to Hebrew names', () {
      expect(HebrewFormatter.nusachName('ashkenaz'), 'אשכנז');
      expect(HebrewFormatter.nusachName('sfard'), 'ספרד');
      expect(HebrewFormatter.nusachName('edot_mizrach'), 'עדות המזרח');
      expect(HebrewFormatter.nusachName('chabad'), 'חב״ד');
    });

    test('falls back to raw string for unknown nusach', () {
      expect(HebrewFormatter.nusachName('unknown'), 'unknown');
    });
  });

  group('formatFullDate', () {
    test('includes day-of-week, day numeral, month name, and year', () {
      const date = HebrewDate(
        year: 5785,
        month: 7,
        day: 1,
        dayOfWeek: DateTime.wednesday,
      );
      final formatted = HebrewFormatter.formatFullDate(date);
      expect(formatted, contains('יום רביעי'));
      expect(formatted, contains('א׳'));
      expect(formatted, contains('תשרי'));
      expect(formatted, contains('תשפ״ה'));
    });

    test('day 15 uses ט״ו form', () {
      const date = HebrewDate(
        year: 5785,
        month: 7,
        day: 15,
        dayOfWeek: DateTime.thursday,
      );
      final formatted = HebrewFormatter.formatFullDate(date);
      expect(formatted, contains('ט״ו'));
    });
  });
}
