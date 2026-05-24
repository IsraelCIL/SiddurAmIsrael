import 'package:kosher_dart/kosher_dart.dart';

import '../entities/day_flags.dart';
import '../entities/user_context.dart';
import 'i_calendar_flag_provider.dart';

/// Computes the full set of Halachic flags for a given Gregorian date
/// and user context. All Hebrew calendar arithmetic is handled by the
/// kosher_dart library (JewishCalendar).
class HalachicCalendarService implements ICalendarFlagProvider {
  const HalachicCalendarService();

  @override
  DayFlags flagsFor(DateTime date, UserContext context) {
    final cal = JewishCalendar.fromDateTime(date);
    cal.inIsrael = context.isInIsrael;

    final flags = <String>{};

    _addDayIdentification(cal, date, context, flags);
    _addSeasonFlags(cal, date, context, flags);
    _addTachanunFlags(cal, flags);
    _addLamenatzeachFlag(context, flags);
    _addAsaretYemeiTeshuva(cal, flags);
    _addAvinoMalkeinu(flags);
    _addYaalehVeyavo(flags);
    _addAlHaNisim(flags);
    _addMizmorLetodahFlag(context, flags);
    _addTefillinFlag(context, flags);
    _addShemaHotzaahFlag(flags);
    _addKriatHatorahFlag(flags);
    _addMusafDayFlag(flags);
    _addHallelFlags(cal, flags);
    _addLulavDayFlag(flags);
    _addGenderAndIsrael(context, flags);

    // Sefirat HaOmer day: kosher_dart returns 1..49 during the count
    // (16 Nisan through 5 Sivan), or -1 outside that window.
    final int rawOmer = cal.getDayOfOmer();
    final int? omerDay = (rawOmer >= 1 && rawOmer <= 49) ? rawOmer : null;
    if (omerDay != null) flags.add(DayFlag.omerPeriod);

    // Sukkot day (1..7): set only during 15–21 Tishrei.
    final int? sukkotDay = _computeSukkotDay(cal);

    return DayFlags(
      flags: flags.toList(),
      omerDay: omerDay,
      sukkotDay: sukkotDay,
    );
  }

  // ── Hallel ────────────────────────────────────────────────────────────────

  void _addHallelFlags(JewishCalendar cal, Set<String> f) {
    final tr = TefilaRules();
    if (!tr.isHallelRecited(cal)) return;
    if (tr.isHallelShalemRecited(cal)) {
      f.add(DayFlag.fullHallel);
    } else {
      f.add(DayFlag.halfHallel);
    }
    // Derived: hallel_with_musaf — Hallel said on a Musaf day.
    if (f.contains(DayFlag.musafDay)) f.add(DayFlag.hallelWithMusaf);
  }

  // ── Lulav day ────────────────────────────────────────────────────────────
  // Set when lulav is taken: any Sukkot day (incl. CHM + Hoshana Raba),
  // unless overridden by Shabbat. SA + Simchat Torah have no `sukkot` flag
  // so they are already excluded.
  void _addLulavDayFlag(Set<String> f) {
    if (!f.contains(DayFlag.sukkot)) return;
    if (f.contains(DayFlag.shabbat)) return;
    f.add(DayFlag.lulavDay);
  }

  // ── Sukkot day (1..7) ────────────────────────────────────────────────────
  // Returns the day-of-Sukkot (1 = 15 Tishrei, ..., 7 = 21 Tishrei / Hoshana
  // Raba), or null if today is outside Sukkot.
  int? _computeSukkotDay(JewishCalendar cal) {
    if (cal.getJewishMonth() != JewishDate.TISHREI) return null;
    final d = cal.getJewishDayOfMonth();
    if (d < 15 || d > 21) return null;
    return d - 14;
  }

  // ── 1. Day identification ─────────────────────────────────────────────────

  void _addDayIdentification(
    JewishCalendar cal,
    DateTime date,
    UserContext ctx,
    Set<String> f,
  ) {
    final yomTov = cal.getYomTovIndex();
    final m = cal.getJewishMonth();
    final d = cal.getJewishDayOfMonth();
    final dow = date.weekday; // Dart: 1=Mon…6=Sat…7=Sun

    if (dow == DateTime.saturday) f.add(DayFlag.shabbat);
    if (dow == DateTime.monday || dow == DateTime.thursday) {
      f.add(DayFlag.mondayThursday);
    }

    // Day-of-week flags — used for shir_shel_yom and other day-specific content
    switch (dow) {
      case DateTime.sunday:    f.add(DayFlag.daySunday);    break;
      case DateTime.monday:    f.add(DayFlag.dayMonday);    break;
      case DateTime.tuesday:   f.add(DayFlag.dayTuesday);   break;
      case DateTime.wednesday: f.add(DayFlag.dayWednesday); break;
      case DateTime.thursday:  f.add(DayFlag.dayThursday);  break;
      case DateTime.friday:    f.add(DayFlag.dayFriday);    break;
      case DateTime.saturday:  f.add(DayFlag.dayShabbat);   break;
    }

    // Rosh Chodesh (days 1 and 30 of applicable months)
    if (cal.isRoshChodesh()) f.add(DayFlag.roshChodesh);

    // Aseret Yemei Teshuva (1–10 Tishri)
    if (cal.isAseresYemeiTeshuva()) f.add(DayFlag.asaretYemeiTeshuva);

    // Tishri — specific days
    if (yomTov == JewishCalendar.ROSH_HASHANA) f.add(DayFlag.roshHashanah);
    if (yomTov == JewishCalendar.EREV_YOM_KIPPUR) f.add(DayFlag.erevYomKippur);
    if (yomTov == JewishCalendar.YOM_KIPPUR) f.add(DayFlag.yomKippur);

    // Sukkot season
    if (yomTov == JewishCalendar.SUCCOS) {
      f.add(DayFlag.sukkot);
    }
    if (yomTov == JewishCalendar.CHOL_HAMOED_SUCCOS) {
      f.add(DayFlag.sukkot);
      f.add(DayFlag.cholHamoedSukkot);
    }
    if (yomTov == JewishCalendar.HOSHANA_RABBA) {
      f.add(DayFlag.sukkot);
      f.add(DayFlag.hoshanahRaba);
      f.add(DayFlag.cholHamoedSukkot);
    }
    if (yomTov == JewishCalendar.SHEMINI_ATZERES) {
      f.add(DayFlag.sheminiAtzeret);
      // In Israel, Shemini Atzeret and Simchat Torah are the same day
      if (ctx.isInIsrael) f.add(DayFlag.simchatTorah);
    }
    if (yomTov == JewishCalendar.SIMCHAS_TORAH) {
      f.add(DayFlag.simchatTorah);
    }

    // 11–14 Tishri — between YK and Sukkot (no explicit flag needed here;
    // handled in tachanun logic via manual month/day check)

    // Erev Rosh Hashanah (29 Elul)
    if (yomTov == JewishCalendar.EREV_ROSH_HASHANA) f.add(DayFlag.erevRoshHashanah);

    // Chanukah
    if (cal.isChanukah()) f.add(DayFlag.chanukah);

    // Tu BiShvat
    if (yomTov == JewishCalendar.TU_BESHVAT) f.add(DayFlag.tuBishvat);

    // Purim / Adar
    _addPurimFlags(cal, ctx, f, yomTov, m);

    // Pesach season
    if (yomTov == JewishCalendar.EREV_PESACH) {
      f.add(DayFlag.pesach);
      f.add(DayFlag.erevPesach);
    }
    if (yomTov == JewishCalendar.PESACH) f.add(DayFlag.pesach);
    if (cal.isCholHamoedPesach()) f.add(DayFlag.cholHamoedPesach);

    // Iyar
    if (yomTov == JewishCalendar.PESACH_SHENI) f.add(DayFlag.pesachSheni);
    if (m == JewishDate.IYAR && d == 13) f.add(DayFlag.erevPesachSheni);
    if (yomTov == JewishCalendar.LAG_BAOMER) f.add(DayFlag.lagBaomer);

    // Sivan — Shavuot
    if (yomTov == JewishCalendar.EREV_SHAVUOS) f.add(DayFlag.erevShavuot);
    if (yomTov == JewishCalendar.SHAVUOS) f.add(DayFlag.shavuot);

    // Av
    if (yomTov == JewishCalendar.TU_BEAV) f.add(DayFlag.tuBav);

    // Isru Chag (day after last Yom Tov of Pesach / Shavuot / Sukkot)
    if (_isIsruChag(cal)) f.add(DayFlag.isruChag);

    // Fast days (covers 10 Tevet, Tzom Gedaliah, Taanit Esther, 17 Tammuz, 9 Av, YK)
    if (cal.isTaanis()) f.add(DayFlag.fastDay);

    // Elul flag: Elul month, excluding Erev Rosh Hashana (29 Elul)
    if (m == JewishDate.ELUL && !f.contains(DayFlag.erevRoshHashanah)) {
      f.add(DayFlag.elul);
    }

    // ladavid_season: Elul (all days) + 1–10 Tishri
    if (m == JewishDate.ELUL) f.add(DayFlag.ladavid_season);
    if (m == JewishDate.TISHREI && d <= 10) f.add(DayFlag.ladavid_season);

    // erev_shabbat: Friday
    if (date.weekday == DateTime.friday) f.add(DayFlag.erevShabbat);
  }

  void _addPurimFlags(
    JewishCalendar cal,
    UserContext ctx,
    Set<String> f,
    int yomTov,
    int m,
  ) {
    // Purim Katan / Shushan Purim Katan (leap year Adar I)
    if (yomTov == JewishCalendar.PURIM_KATAN) f.add(DayFlag.purimKatan);
    if (yomTov == JewishCalendar.SHUSHAN_PURIM_KATAN) {
      f.add(DayFlag.shushanPurimKatan);
    }

    // Erev Purim (13 Adar / 13 Adar II) = Taanit Esther day
    if (yomTov == JewishCalendar.FAST_OF_ESTHER) f.add(DayFlag.erevPurim);

    // Purim proper (14 Adar) — respects PurimDate setting
    if (yomTov == JewishCalendar.PURIM) {
      if (ctx.purimDate == PurimDate.fourteenth ||
          ctx.purimDate == PurimDate.both) {
        f.add(DayFlag.purim);
      }
    }

    // Shushan Purim (15 Adar)
    if (yomTov == JewishCalendar.SHUSHAN_PURIM) {
      f.add(DayFlag.shushanPurim);
      if (ctx.purimDate == PurimDate.fifteenth ||
          ctx.purimDate == PurimDate.both) {
        f.add(DayFlag.purim);
      }
    }
  }

  bool _isIsruChag(JewishCalendar cal) {
    final m = cal.getJewishMonth();
    final d = cal.getJewishDayOfMonth();
    final inIsrael = cal.inIsrael;
    if (m == JewishDate.TISHREI && d == (inIsrael ? 23 : 24)) return true;
    if (m == JewishDate.NISSAN && d == (inIsrael ? 22 : 23)) return true;
    if (m == JewishDate.SIVAN && d == (inIsrael ? 7 : 8)) return true;
    return false;
  }

  // ── 2. Season / precipitation flags ──────────────────────────────────────

  void _addSeasonFlags(
    JewishCalendar cal,
    DateTime date,
    UserContext ctx,
    Set<String> f,
  ) {
    final m = cal.getJewishMonth();
    final d = cal.getJewishDayOfMonth();

    // mashiv_haruach: 22 Tishrei (Shemini Atzeret) through 14 Nisan (Erev Pesach)
    if (_isMashivHaruachPeriod(m, d)) f.add(DayFlag.mashivHaruach);

    // tal_umatar: Israel from 7 Cheshvan; Diaspora from Dec 4/5; both through 14 Nisan
    if (_isTalUmatarPeriod(m, d, date, ctx.isInIsrael)) f.add(DayFlag.talUmatar);

    // tisha_beav
    if (cal.getYomTovIndex() == JewishCalendar.TISHA_BEAV) f.add(DayFlag.tishaBaav);
  }

  bool _isMashivHaruachPeriod(int m, int d) {
    if (m == JewishDate.TISHREI && d >= 22) return true;
    if (m >= JewishDate.CHESHVAN) return true;
    if (m == JewishDate.NISSAN && d <= 14) return true;
    return false;
  }

  bool _isTalUmatarPeriod(int m, int d, DateTime date, bool inIsrael) {
    // Summer months: no tal u'matar
    if (m >= JewishDate.IYAR && m < JewishDate.TISHREI) return false;
    if (m == JewishDate.TISHREI && d < 22) return false;
    // Ends before 15 Nisan
    if (m == JewishDate.NISSAN && d >= 15) return false;

    if (inIsrael) {
      if (m == JewishDate.CHESHVAN && d < 7) return false;
      return true;
    }

    // Diaspora: starts December 4 or 5
    if (date.month == 12) return date.day >= _diasporaTalUmatarStartDay(date.year);
    if (date.month <= 5) return true; // Jan–May: past December start
    return false; // Oct–Nov: before December start
  }

  int _diasporaTalUmatarStartDay(int year) {
    final nextYear = year + 1;
    final nextIsLeap =
        (nextYear % 4 == 0 && nextYear % 100 != 0) || nextYear % 400 == 0;
    return nextIsLeap ? 5 : 4;
  }

  // ── 3. Tachanun ───────────────────────────────────────────────────────────

  void _addTachanunFlags(JewishCalendar cal, Set<String> f) {
    final m = cal.getJewishMonth();
    final d = cal.getJewishDayOfMonth();

    bool skipAll = false;
    bool skipMinchaOnly = false;

    // Whole Nisan (1–30)
    if (m == JewishDate.NISSAN) skipAll = true;

    // Standard skip-tachanun days — all identified via their flags
    if (f.contains(DayFlag.chanukah)) skipAll = true;
    if (f.contains(DayFlag.roshChodesh)) skipAll = true;
    if (f.contains(DayFlag.purim) ||
        f.contains(DayFlag.shushanPurim) ||
        f.contains(DayFlag.erevPurim) ||
        f.contains(DayFlag.purimKatan) ||
        f.contains(DayFlag.shushanPurimKatan)) {
      skipAll = true;
    }
    if (f.contains(DayFlag.pesachSheni)) skipAll = true;
    if (f.contains(DayFlag.tuBishvat) ||
        f.contains(DayFlag.lagBaomer) ||
        f.contains(DayFlag.tuBav)) {
      skipAll = true;
    }
    if (f.contains(DayFlag.roshHashanah) ||
        f.contains(DayFlag.yomKippur) ||
        f.contains(DayFlag.erevYomKippur) ||
        f.contains(DayFlag.sukkot) ||
        f.contains(DayFlag.cholHamoedSukkot) ||
        f.contains(DayFlag.hoshanahRaba) ||
        f.contains(DayFlag.sheminiAtzeret) ||
        f.contains(DayFlag.simchatTorah) ||
        f.contains(DayFlag.pesach) ||
        f.contains(DayFlag.cholHamoedPesach) ||
        f.contains(DayFlag.shavuot) ||
        f.contains(DayFlag.isruChag)) {
      skipAll = true;
    }

    // 11–14 Tishri (between Yom Kippur and Sukkot)
    if (m == JewishDate.TISHREI && d >= 11 && d <= 14) skipAll = true;

    // Erev Shavuot (5 Sivan) — Mincha only
    if (f.contains(DayFlag.erevShavuot)) skipMinchaOnly = true;

    // EXPLICIT EXCEPTIONS — no skip flag set:
    //   29 Elul (Erev Rosh Hashanah) — Mincha HAS tachanun
    //   13 Iyar (Erev Pesach Sheni)  — Mincha HAS tachanun
    // (simply do not set skipMinchaOnly for these)

    if (skipAll) f.add(DayFlag.skipTachanun);
    if (!skipAll && skipMinchaOnly) f.add(DayFlag.skipTachanunMincha);
  }

  // ── 3. Lamenatzeach ───────────────────────────────────────────────────────

  void _addLamenatzeachFlag(UserContext ctx, Set<String> f) {
    // All nusachim: skip Lamenatzeach on any day that skips Tachanun.
    // (Edot HaMizrach explicitly mirrors Tachanun; Ashkenaz/Sfard effectively the same.)
    if (f.contains(DayFlag.skipTachanun)) f.add(DayFlag.skipLamenatzeach);
  }

  // ── 4. Aseret Yemei Teshuva text additions ────────────────────────────────

  void _addAsaretYemeiTeshuva(JewishCalendar cal, Set<String> f) {
    if (!f.contains(DayFlag.asaretYemeiTeshuva)) return;
    f.add(DayFlag.hamelech_hakadosh);
    f.add(DayFlag.hamelech_hamishpat);
    f.add(DayFlag.zochrenu);
    f.add(DayFlag.miChamochaAyt);
    f.add(DayFlag.uchtov);
    f.add(DayFlag.bseferChaim);
  }

  // ── 5. Avinu Malkeinu ─────────────────────────────────────────────────────

  void _addAvinoMalkeinu(Set<String> f) {
    final isAyt = f.contains(DayFlag.asaretYemeiTeshuva);
    final isFast = f.contains(DayFlag.fastDay);
    final isShabbat = f.contains(DayFlag.shabbat);
    final isYomKippur = f.contains(DayFlag.yomKippur);
    final isTishaBaav = f.contains(DayFlag.tishaBaav);

    // Tisha B'Av: NOT said, even though it's a fast day (Halachic exception).
    if ((isAyt || isFast) && !isShabbat && !isTishaBaav) {
      f.add(DayFlag.avinoMalkeinu);
    }
    // Yom Kippur: always said, even on Shabbat
    if (isYomKippur) f.add(DayFlag.avinoMalkeinu);
  }

  // ── 6. Ya'aleh Ve'yavo ────────────────────────────────────────────────────

  void _addYaalehVeyavo(Set<String> f) {
    const yyvDays = {
      DayFlag.roshChodesh,
      DayFlag.roshHashanah,
      DayFlag.pesach,
      DayFlag.cholHamoedPesach,
      DayFlag.shavuot,
      DayFlag.sukkot,
      DayFlag.cholHamoedSukkot,
      DayFlag.hoshanahRaba,
      DayFlag.sheminiAtzeret,
      DayFlag.simchatTorah,
    };
    if (f.any(yyvDays.contains)) f.add(DayFlag.yaalehVeyavo);
  }

  // ── 7. Al HaNisim ─────────────────────────────────────────────────────────

  void _addAlHaNisim(Set<String> f) {
    if (f.contains(DayFlag.chanukah) || f.contains(DayFlag.purim)) {
      f.add(DayFlag.alHaNisim);
    }
  }

  // ── 8. Mizmor LeTodah ─────────────────────────────────────────────────────

  void _addMizmorLetodahFlag(UserContext ctx, Set<String> f) {
    if (ctx.nusach == 'edot_mizrach') return;
    if (f.contains(DayFlag.erevPesach) ||
        f.contains(DayFlag.cholHamoedPesach) ||
        f.contains(DayFlag.erevYomKippur)) {
      f.add(DayFlag.skipMizmorLetodah);
    }
  }

  // ── 9. Tefillin on Chol HaMoed ────────────────────────────────────────────

  void _addTefillinFlag(UserContext ctx, Set<String> f) {
    final isCholHaMoed = f.contains(DayFlag.cholHamoedPesach) ||
        f.contains(DayFlag.cholHamoedSukkot);
    if (!isCholHaMoed) return;
    if (ctx.isInIsrael) {
      f.add(DayFlag.skipTefillin);
    } else {
      f.add(DayFlag.tefillinOptionalAccordion);
    }
  }

  // ── 10. Shema at Hotzaat HaTorah ─────────────────────────────────────────

  void _addShemaHotzaahFlag(Set<String> f) {
    // Shema + proclamations are said during hotzaat sefer Torah only on
    // Shabbat, Yom Tov (all days), and Hoshana Raba — not on weekdays,
    // Rosh Chodesh, or Chol HaMoed.
    final isYomTovLevel =
        f.contains(DayFlag.shabbat) ||
        f.contains(DayFlag.roshHashanah) ||
        f.contains(DayFlag.yomKippur) ||
        f.contains(DayFlag.hoshanahRaba) ||
        f.contains(DayFlag.sheminiAtzeret) ||
        f.contains(DayFlag.simchatTorah) ||
        f.contains(DayFlag.shavuot) ||
        (f.contains(DayFlag.pesach) &&
            !f.contains(DayFlag.cholHamoedPesach) &&
            !f.contains(DayFlag.erevPesach)) ||
        (f.contains(DayFlag.sukkot) && !f.contains(DayFlag.cholHamoedSukkot));
    if (isYomTovLevel) f.add(DayFlag.shemaHotzaah);
  }

  // ── 10b. Kriat HaTorah ────────────────────────────────────────────────────

  void _addKriatHatorahFlag(Set<String> f) {
    // Torah is read on: Monday/Thursday, Rosh Chodesh, public fast days
    // (Tisha B'Av at Mincha too, but that's the fast_day flag), Chanukah,
    // Purim, Chol HaMoed Pesach/Sukkot, Yom Tov, Shabbat.
    final hasKriah = f.contains(DayFlag.mondayThursday) ||
        f.contains(DayFlag.roshChodesh) ||
        f.contains(DayFlag.fastDay) ||
        f.contains(DayFlag.chanukah) ||
        f.contains(DayFlag.purim) ||
        f.contains(DayFlag.shushanPurim) ||
        f.contains(DayFlag.cholHamoedPesach) ||
        f.contains(DayFlag.cholHamoedSukkot) ||
        f.contains(DayFlag.shabbat) ||
        f.contains(DayFlag.roshHashanah) ||
        f.contains(DayFlag.yomKippur) ||
        f.contains(DayFlag.pesach) ||
        f.contains(DayFlag.shavuot) ||
        f.contains(DayFlag.sukkot) ||
        f.contains(DayFlag.sheminiAtzeret) ||
        f.contains(DayFlag.simchatTorah) ||
        f.contains(DayFlag.hoshanahRaba);
    if (hasKriah) f.add(DayFlag.kriatHatorah);
  }

  // ── 10c. Musaf day ────────────────────────────────────────────────────────

  void _addMusafDayFlag(Set<String> f) {
    // Musaf is recited on: Rosh Chodesh, Chol HaMoed Pesach/Sukkot, Yom Tov,
    // Shabbat. (Hoshana Raba is Chol HaMoed Sukkot — already covered.)
    final hasMusaf = f.contains(DayFlag.roshChodesh) ||
        f.contains(DayFlag.cholHamoedPesach) ||
        f.contains(DayFlag.cholHamoedSukkot) ||
        f.contains(DayFlag.shabbat) ||
        f.contains(DayFlag.roshHashanah) ||
        f.contains(DayFlag.yomKippur) ||
        f.contains(DayFlag.pesach) ||
        f.contains(DayFlag.shavuot) ||
        f.contains(DayFlag.sukkot) ||
        f.contains(DayFlag.sheminiAtzeret) ||
        f.contains(DayFlag.simchatTorah);
    if (hasMusaf) f.add(DayFlag.musafDay);
    // Musaf days for which the app currently has content (RC + CHM). Yom Tov
    // and Shabbat are deliberately excluded for now.
    final hasMusafContent = f.contains(DayFlag.roshChodesh) ||
        f.contains(DayFlag.cholHamoedPesach) ||
        f.contains(DayFlag.cholHamoedSukkot);
    if (hasMusafContent) f.add(DayFlag.musafContent);
  }

  // ── 11. Gender + Israel flags ─────────────────────────────────────────────

  void _addGenderAndIsrael(UserContext ctx, Set<String> f) {
    f.add(ctx.gender == Gender.male ? DayFlag.genderMale : DayFlag.genderFemale);
    f.add(ctx.isInIsrael ? DayFlag.inIsrael : DayFlag.notInIsrael);
  }
}
