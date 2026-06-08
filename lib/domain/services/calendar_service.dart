import 'package:kosher_dart/kosher_dart.dart';

import 'package:siddur_am_israel_chai/core/calendar/hebrew_date.dart';
import 'package:siddur_am_israel_chai/core/utils/hebrew_formatter.dart';
import 'package:siddur_am_israel_chai/domain/entities/calendar_day.dart';
import 'package:siddur_am_israel_chai/domain/entities/city.dart';

/// Builds a [CalendarDay] (Hebrew date, holidays, parsha, Daf Yomi, and all
/// zmanim) for a Gregorian date at a given [City]. A pure wrapper over
/// `kosher_dart` — no Flutter, no I/O — so it is fully unit-testable.
///
/// Zmanim shitot follow standard Orthodox opinions:
///   • סוף זמן ק״ש / תפילה shown for both מג״א and הגר״א.
///   • צאת הכוכבים: the Geonim 8.5° opinion; רבינו תם shown as 72 minutes.
///   • הדלקת נרות: [City.candleLightingMinutes] before sunset (40 Jerusalem / 20 else).
class CalendarService {
  const CalendarService();

  CalendarDay dayFor(DateTime date, City city) {
    // Normalize to local noon — avoids DST / midnight edge cases in arithmetic.
    final day = DateTime(date.year, date.month, date.day, 12);

    final jc = JewishCalendar.fromDateTime(day)..inIsrael = city.inIsrael;
    final fmt = HebrewDateFormatter()..hebrewFormat = true;
    final hebrew = HebrewDate.fromGregorian(day);

    // ── Tags: Yom Tov / Chol HaMoed / Rosh Chodesh / Omer ──
    final tags = <String>[];
    final yomTov = fmt.formatYomTov(jc);
    if (yomTov.isNotEmpty) tags.add(yomTov);
    if (jc.isRoshChodesh()) {
      final rc = fmt.formatRoshChodesh(jc);
      if (rc.isNotEmpty && !tags.contains(rc)) tags.add(rc);
    }
    if (jc.getDayOfOmer() > 0) {
      final omer = fmt.formatOmer(jc);
      if (omer.isNotEmpty) tags.add(omer);
    }

    // ── Weekly parsha ──
    String? parsha;
    final p = fmt.formatParsha(jc);
    if (p.isNotEmpty) parsha = 'פרשת $p';

    // ── Daf Yomi (Bavli) — undefined before the first cycle (1923) ──
    String? dafYomi;
    try {
      final daf = jc.getDafYomiBavli();
      final s = fmt.formatDafYomiBavli(daf);
      if (s.isNotEmpty) dafYomi = s;
    } catch (_) {
      dafYomi = null;
    }

    final isShabbat = day.weekday == DateTime.saturday;
    final isYomTov = jc.isYomTov();

    // ── Zmanim ──
    final geo = GeoLocation.setLocation(
      city.name,
      city.latitude,
      city.longitude,
      day,
    );
    final zc = ComplexZmanimCalendar.intGeoLocation(geo)
      ..setCandleLightingOffset(city.candleLightingMinutes.toDouble());

    final chatzos = zc.getChatzos();
    final zmanim = <ZmanEntry>[
      ZmanEntry('עלות השחר', zc.getAlos72(), note: '72 ד׳'),
      ZmanEntry('זמן טלית ותפילין', zc.getMisheyakir11Degrees()),
      ZmanEntry('הנץ החמה', zc.getSunrise()),
      ZmanEntry('סוף זמן ק״ש', zc.getSofZmanShmaMGA(), note: 'מג״א'),
      ZmanEntry('סוף זמן ק״ש', zc.getSofZmanShmaGRA(), note: 'גר״א'),
      ZmanEntry('סוף זמן תפילה', zc.getSofZmanTfilaMGA(), note: 'מג״א'),
      ZmanEntry('סוף זמן תפילה', zc.getSofZmanTfilaGRA(), note: 'גר״א'),
      ZmanEntry('חצות היום', chatzos),
      ZmanEntry('מנחה גדולה', zc.getMinchaGedola()),
      ZmanEntry('מנחה קטנה', zc.getMinchaKetana()),
      ZmanEntry('פלג המנחה', zc.getPlagHamincha()),
      ZmanEntry('שקיעת החמה', zc.getSunset()),
      ZmanEntry('צאת הכוכבים', zc.getTzaisGeonim8Point5Degrees()),
      ZmanEntry('צאת הכוכבים', zc.getTzais72(), note: 'רבינו תם'),
      ZmanEntry('חצות הלילה', chatzos?.add(const Duration(hours: 12))),
    ];

    // ── Candle lighting / Havdalah (erev + Shabbat/Yom Tov) ──
    final shabbatZmanim = <ZmanEntry>[];
    final isErev = day.weekday == DateTime.friday || jc.isErevYomTov();
    if (isErev) {
      shabbatZmanim.add(ZmanEntry(
        'הדלקת נרות',
        zc.getCandleLighting(),
        note: '${city.candleLightingMinutes} ד׳',
      ));
    }
    if (isShabbat || isYomTov) {
      shabbatZmanim.add(
        ZmanEntry('הבדלה', zc.getTzaisGeonim8Point5Degrees(), note: 'צאת הכוכבים'),
      );
      shabbatZmanim.add(
        ZmanEntry('הבדלה', zc.getTzais72(), note: 'רבינו תם'),
      );
    }

    // ── Special-Shabbat notes, extra info, upcoming events ──
    final shabbatNotes = <String>[];
    if (jc.isShabbosMevorchim()) shabbatNotes.add('שבת מברכים');
    final specialParsha = fmt.formatSpecialParsha(jc);
    if (specialParsha.isNotEmpty) shabbatNotes.add(specialParsha);

    final extraInfo = <InfoRow>[
      if (dafYomi != null) InfoRow('דף יומי', dafYomi),
    ];
    // On Shabbat Mevarchim, announce the molad of the upcoming month. +8 days
    // lands safely inside the next month, whose getMolad() we then read.
    if (jc.isShabbosMevorchim()) {
      final nextJc =
          JewishCalendar.fromDateTime(day.add(const Duration(days: 8)))
            ..inIsrael = city.inIsrael;
      extraInfo.add(InfoRow(
        'מולד ${HebrewFormatter.monthName(nextJc.getJewishMonth())}',
        _formatMolad(nextJc.getMolad()),
      ));
    }

    final upcoming = _upcoming(day, city.inIsrael, fmt);

    final monthName = HebrewFormatter.monthName(hebrew.month);
    final dayNum = HebrewFormatter.toHebrewNumeral(hebrew.day);
    final yearStr = HebrewFormatter.formatHebrewYear(hebrew.year);

    return CalendarDay(
      gregorian: day,
      hebrew: hebrew,
      dayOfWeekLabel: HebrewFormatter.dayOfWeekName(hebrew.dayOfWeek),
      hebrewDateLabel: '$dayNum $monthName $yearStr',
      gregorianLabel: _gregorianLabel(day),
      tags: tags,
      isShabbat: isShabbat,
      isYomTov: isYomTov,
      parsha: parsha,
      dafYomi: dafYomi,
      zmanim: zmanim,
      shabbatZmanim: shabbatZmanim,
      shabbatNotes: shabbatNotes,
      extraInfo: extraInfo,
      upcoming: upcoming,
    );
  }

  /// Scans forward up to ~4 months for the next distinct holidays / Rosh
  /// Chodesh / fast days (skipping Chol HaMoed and erev days), with days-until.
  List<UpcomingEvent> _upcoming(
      DateTime base, bool inIsrael, HebrewDateFormatter fmt) {
    final out = <UpcomingEvent>[];
    final seen = <String>{};
    for (var i = 1; i <= 120 && out.length < 5; i++) {
      final d = base.add(Duration(days: i));
      final jc = JewishCalendar.fromDateTime(d)..inIsrael = inIsrael;
      if (jc.isCholHamoed() || jc.isErevYomTov()) continue;
      var label = '';
      if (jc.getYomTovIndex() >= 0) {
        label = fmt.formatYomTov(jc);
      } else if (jc.isRoshChodesh()) {
        label = fmt.formatRoshChodesh(jc);
      }
      if (label.isEmpty || seen.contains(label)) continue;
      seen.add(label);
      final hd = HebrewDate.fromGregorian(d);
      final hebDate =
          '${HebrewFormatter.toHebrewNumeral(hd.day)} ${HebrewFormatter.monthName(hd.month)}';
      out.add(UpcomingEvent(label, hebDate, i));
    }
    return out;
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _gregorianLabel(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  // Molad day-of-week names (kosher_dart getDayOfWeek: 1=Sunday … 7=Saturday).
  static const _moladDows = [
    '', 'יום ראשון', 'יום שני', 'יום שלישי', 'יום רביעי', 'יום חמישי',
    'יום שישי', 'שבת קודש',
  ];

  /// Formats a molad [JewishDate] as "יום W, H:MM ו-C חלקים".
  String _formatMolad(JewishDate molad) {
    final dow = _moladDows[molad.getDayOfWeek()];
    final h = molad.getMoladHours();
    final m = molad.getMoladMinutes().toString().padLeft(2, '0');
    final c = molad.getMoladChalakim();
    return '$dow, $h:$m ו-$c חלקים';
  }
}
