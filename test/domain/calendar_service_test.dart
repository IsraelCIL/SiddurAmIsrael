import 'package:flutter_test/flutter_test.dart';

import 'package:siddur_am_israel_chai/core/data/cities.dart';
import 'package:siddur_am_israel_chai/domain/services/calendar_service.dart';

void main() {
  const svc = CalendarService();
  final jerusalem = cityById('jerusalem');

  group('CalendarService', () {
    test('builds a day with the core zmanim populated (Jerusalem)', () {
      final day = svc.dayFor(DateTime(2025, 1, 15), jerusalem); // Wednesday

      expect(day.hebrewDateLabel, isNotEmpty);
      expect(day.dayOfWeekLabel, isNotEmpty);
      expect(day.gregorianLabel, '15 January 2025');
      expect(day.zmanim.length, greaterThanOrEqualTo(14));

      bool present(String label) =>
          day.zmanim.any((z) => z.label == label && z.time != null);
      expect(present('הנץ החמה'), isTrue);
      expect(present('חצות היום'), isTrue);
      expect(present('שקיעת החמה'), isTrue);
    });

    test('exposes both מג״א and גר״א for סוף זמן ק״ש', () {
      final day = svc.dayFor(DateTime(2025, 1, 15), jerusalem);
      final shma = day.zmanim.where((z) => z.label == 'סוף זמן ק״ש').toList();
      expect(shma.length, 2);
      expect(shma.map((z) => z.note), containsAll(['מג״א', 'גר״א']));
    });

    test('a regular weekday has no candle-lighting / havdalah rows', () {
      final day = svc.dayFor(DateTime(2025, 1, 15), jerusalem); // Wednesday
      expect(day.shabbatZmanim, isEmpty);
    });

    test('Friday shows candle lighting', () {
      final day = svc.dayFor(DateTime(2025, 1, 17), jerusalem); // Friday
      expect(day.gregorian.weekday, DateTime.friday);
      expect(day.shabbatZmanim.any((z) => z.label == 'הדלקת נרות'), isTrue);
    });

    test('Shabbat shows havdalah for two opinions, incl. Rabbeinu Tam', () {
      final day = svc.dayFor(DateTime(2025, 1, 18), jerusalem); // Saturday
      expect(day.isShabbat, isTrue);
      final havdalah =
          day.shabbatZmanim.where((z) => z.label == 'הבדלה').toList();
      expect(havdalah.length, 2);
      expect(havdalah.any((z) => z.note == 'רבינו תם'), isTrue);
    });

    test('candle-lighting offset: 40 min Jerusalem, 20 min elsewhere', () {
      expect(jerusalem.candleLightingMinutes, 40);
      expect(cityById('tel_aviv').candleLightingMinutes, 20);

      final fri = svc.dayFor(DateTime(2025, 1, 17), jerusalem);
      final candle =
          fri.shabbatZmanim.firstWhere((z) => z.label == 'הדלקת נרות');
      expect(candle.note, contains('40'));
    });

    test('cityById falls back to Jerusalem for an unknown id', () {
      expect(cityById('nope').id, 'jerusalem');
    });

    test('extra info includes Daf Yomi (modern date)', () {
      final day = svc.dayFor(DateTime(2025, 1, 15), jerusalem);
      expect(day.extraInfo.any((r) => r.label == 'דף יומי'), isTrue);
    });

    test('upcoming events: present, distinct, ordered by days-until', () {
      final day = svc.dayFor(DateTime(2025, 1, 15), jerusalem);
      expect(day.upcoming, isNotEmpty);
      expect(day.upcoming.length, lessThanOrEqualTo(5));
      for (var i = 1; i < day.upcoming.length; i++) {
        expect(day.upcoming[i].daysUntil,
            greaterThanOrEqualTo(day.upcoming[i - 1].daysUntil));
      }
      final names = day.upcoming.map((e) => e.name).toSet();
      expect(names.length, day.upcoming.length); // distinct labels
    });

    test('molad is announced on a Shabbat Mevarchim (within ~5 weeks)', () {
      // Every Hebrew month has a Shabbat Mevarchim, so a 40-day scan must hit one.
      var found = false;
      final start = DateTime(2025, 1, 1);
      for (var i = 0; i < 40; i++) {
        final day = svc.dayFor(start.add(Duration(days: i)), jerusalem);
        if (day.extraInfo.any((r) => r.label.startsWith('מולד'))) {
          found = true;
          break;
        }
      }
      expect(found, isTrue);
    });

    group('upcoming pinned to upcomingBase', () {
      final today = DateTime(2025, 1, 15);

      test('browsing a different day keeps the upcoming list of today', () {
        final pinnedFromToday = svc.dayFor(today, jerusalem).upcoming;
        final browsedFarAway = svc
            .dayFor(DateTime(2025, 3, 2), jerusalem, upcomingBase: today)
            .upcoming;

        expect(
          browsedFarAway.map((e) => '${e.name}|${e.hebrewDate}|${e.daysUntil}'),
          pinnedFromToday.map((e) => '${e.name}|${e.hebrewDate}|${e.daysUntil}'),
        );
      });

      test('days-until is measured from the base, not the browsed day', () {
        final browsed = svc
            .dayFor(DateTime(2025, 6, 20), jerusalem, upcomingBase: today)
            .upcoming;
        final direct = svc.dayFor(today, jerusalem).upcoming;
        expect(browsed.first.daysUntil, direct.first.daysUntil);
      });

      test('without upcomingBase the browsed day remains the reference', () {
        final a = svc.dayFor(today, jerusalem).upcoming;
        final b = svc.dayFor(DateTime(2025, 3, 2), jerusalem).upcoming;
        expect(a.map((e) => e.name), isNot(equals(b.map((e) => e.name))));
      });
    });
  });
}
