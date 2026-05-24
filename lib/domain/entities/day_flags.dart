import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_flags.freezed.dart';

/// The computed set of Halachic flags for a specific day + nusach combination.
/// Produced by [ICalendarFlagProvider] and merged into [UserContext.activeFlags].
@freezed
class DayFlags with _$DayFlags {
  const DayFlags._();

  const factory DayFlags({
    @Default([]) List<String> flags,
    // 1..49 during Sefirat HaOmer (16 Nisan through 5 Sivan). Null otherwise.
    // When set, the [DayFlag.omerPeriod] flag is also added to [flags].
    int? omerDay,
    // 1..7 during the 7 days of Sukkot (15–21 Tishrei).
    // 1 = Yom Tov (first day), 2..6 = Chol HaMoed, 7 = Hoshana Raba.
    // Used to resolve the daily korban in Musaf and other day-specific
    // content (Hoshanot, Daily Torah Reading, Gr"a Shir Shel Yom). Null
    // outside Sukkot.
    int? sukkotDay,
  }) = _DayFlags;

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get isShabbat => flags.contains(DayFlag.shabbat);
  bool get isRoshChodesh => flags.contains(DayFlag.roshChodesh);
  bool get isChanukah => flags.contains(DayFlag.chanukah);
  bool get isPurim => flags.contains(DayFlag.purim);
  bool get isFastDay => flags.contains(DayFlag.fastDay);
  bool get isAsaretYemeiTeshuva => flags.contains(DayFlag.asaretYemeiTeshuva);

  bool get isElul => flags.contains(DayFlag.elul);
  bool get isLadavidSeason => flags.contains(DayFlag.ladavid_season);
  bool get isErevShabbat => flags.contains(DayFlag.erevShabbat);

  bool get skipTachanun => flags.contains(DayFlag.skipTachanun);
  bool get skipTachanunMincha => flags.contains(DayFlag.skipTachanunMincha);
  bool get skipLamenatzeach => flags.contains(DayFlag.skipLamenatzeach);
  bool get sayAvinu => flags.contains(DayFlag.avinoMalkeinu);
  bool get sayYaalehVeyavo => flags.contains(DayFlag.yaalehVeyavo);
  bool get sayAlHaNisim => flags.contains(DayFlag.alHaNisim);

  DayFlags operator +(DayFlags other) => DayFlags(
        flags: {...flags, ...other.flags}.toList(),
        omerDay: other.omerDay ?? omerDay,
        sukkotDay: other.sukkotDay ?? sukkotDay,
      );
}

/// Canonical flag string constants — single source of truth.
/// Use these instead of raw strings to avoid typos.
abstract final class DayFlag {
  // ── Day identification ────────────────────────────────────────────────────
  static const shabbat = 'shabbat';
  static const roshChodesh = 'rosh_chodesh';
  static const chanukah = 'chanukah';
  static const purim = 'purim';
  static const shushanPurim = 'shushan_purim';
  static const purimKatan = 'purim_katan';
  static const shushanPurimKatan = 'shushan_purim_katan';
  static const erevPurim = 'erev_purim';
  static const tuBishvat = 'tu_bishvat';
  static const pesachSheni = 'pesach_sheni';
  static const erevPesachSheni = 'erev_pesach_sheni';
  static const lagBaomer = 'lag_baomer';
  static const tuBav = 'tu_bav';
  static const erevRoshHashanah = 'erev_rosh_hashanah';
  static const roshHashanah = 'rosh_hashanah';
  static const asaretYemeiTeshuva = 'aseret_yemei_teshuva';
  static const erevYomKippur = 'erev_yom_kippur';
  static const yomKippur = 'yom_kippur';
  static const sukkot = 'sukkot';
  static const hoshanahRaba = 'hoshana_raba';
  static const sheminiAtzeret = 'shemini_atzeret';
  static const simchatTorah = 'simchat_torah';
  static const cholHamoedPesach = 'chol_hamoed_pesach';
  static const cholHamoedSukkot = 'chol_hamoed_sukkot';
  static const isruChag = 'isru_chag';
  static const pesach = 'pesach';
  static const erevPesach = 'erev_pesach';
  static const shavuot = 'shavuot';
  static const erevShavuot = 'erev_shavuot';
  static const fastDay = 'fast_day';
  static const mondayThursday = 'monday_thursday';

  // ── Tachanun ──────────────────────────────────────────────────────────────
  // skip_tachanun     → both Shacharit AND Mincha skip
  // skip_tachanun_mincha → only Mincha skips (Shacharit still says it)
  // Note: 29 Elul and 13 Iyar get NO skip flag (explicit Halachic exception)
  static const skipTachanun = 'skip_tachanun';
  static const skipTachanunMincha = 'skip_tachanun_mincha';

  // ── Lamenatzeach ─────────────────────────────────────────────────────────
  static const skipLamenatzeach = 'skip_lamenatzeach';

  // ── Mizmor LeTodah ───────────────────────────────────────────────────────
  static const skipMizmorLetodah = 'skip_mizmor_letodah';

  // ── Tefillin on Chol HaMoed ───────────────────────────────────────────────
  static const skipTefillin = 'skip_tefillin';
  static const tefillinOptionalAccordion = 'tefillin_optional_accordion';
  // hefsek_tefillin: user makes a hefsek (interruption) between yad and rosh
  // tefillin — relevant for EM's optional second bracha on rosh.
  static const hefsekTefillin = 'hefsek_tefillin';

  // ── Tzitzit / Tallit ──────────────────────────────────────────────────────
  // wears_tallit_gadol: user wears a Tallit Gadol (vs. only the small under-
  // garment). Determines which bracha is recited:
  //   - true  → "להתעטף בציצית" (birkat_tzitzit_gadol)
  //   - false → "על מצות ציצית" (birkat_tzitzit_katan)
  static const wearsTallitGadol = 'wears_tallit_gadol';

  // ── Aseret Yemei Teshuva text changes ────────────────────────────────────
  static const hamelech_hakadosh = 'hamelech_hakadosh';
  static const hamelech_hamishpat = 'hamelech_hamishpat';

  // ── Season / precipitation ────────────────────────────────────────────────
  static const mashivHaruach = 'mashiv_haruach';
  static const talUmatar = 'tal_umatar';

  // ── Seasonal customs ──────────────────────────────────────────────────────
  static const elul = 'elul';                          // Elul month (shofar blowing period, excl. Erev RH)
  static const ladavid_season = 'ladavid_season';       // Elul through Yom Kippur (ladavid / psalm 27)
  static const erevShabbat = 'erev_shabbat';            // Friday (for Avinu Malkeinu exclusion at Mincha)

  // ── Specific fast days ────────────────────────────────────────────────────
  static const tishaBaav = 'tisha_beav';
  // tisha_beav_mincha: injected by the Mincha provider when today is Tisha B'Av.
  // Triggers Nachem insertion in amidah_yerushalayim (and EM's TB'A-specific
  // chatima). Not a calendar-derived day flag — set only when the caller knows
  // the current prayer is Mincha.
  static const tishaBavMincha = 'tisha_beav_mincha';

  // ── Injected segments ─────────────────────────────────────────────────────
  static const avinoMalkeinu = 'avinu_malkeinu';
  static const yaalehVeyavo = 'yaaleh_veyavo';
  static const alHaNisim = 'al_hanisim';
  static const zochrenu = 'zochrenu';
  static const miChamochaAyt = 'mi_chamocha_ayt';
  static const uchtov = 'uchtov';
  static const bseferChaim = 'bsefer_chaim';

  // ── Day of week (for shir_shel_yom and similar day-specific content) ────
  static const daySunday = 'day_sunday';
  static const dayMonday = 'day_monday';
  static const dayTuesday = 'day_tuesday';
  static const dayWednesday = 'day_wednesday';
  static const dayThursday = 'day_thursday';
  static const dayFriday = 'day_friday';
  static const dayShabbat = 'day_shabbat';

  // ── Gender (mirrors UserContext, re-emitted as flags) ────────────────────
  static const genderMale = 'gender_male';
  static const genderFemale = 'gender_female';

  // ── Israel ────────────────────────────────────────────────────────────────
  static const inIsrael = 'in_israel';
  static const notInIsrael = 'not_in_israel';

  // ── Kriat HaTorah ────────────────────────────────────────────────────────
  // kriat_hatorah: Torah is read in this prayer (Monday/Thursday, Rosh
  // Chodesh, public fast days, Chanukah, Purim, Chol HaMoed — plus
  // Shabbat / Yom Tov when the siddur covers them).
  static const kriatHatorah = 'kriat_hatorah';

  // ── Sefirat HaOmer ────────────────────────────────────────────────────────
  // omer_period: today is one of the 49 counting days (16 Nisan – 5 Sivan).
  // The actual day number (1..49) lives on [DayFlags.omerDay] and
  // [UserContext.omerDay], not as a flag.
  static const omerPeriod = 'omer_period';

  // ── Hallel ────────────────────────────────────────────────────────────────
  // full_hallel: complete (shalem) Hallel — Sukkot (all 7 days), Shemini
  //   Atzeret + Simchat Torah, first day(s) of Pesach, Shavuot, Chanukah
  //   (all 8 days).
  // half_hallel: half Hallel — Rosh Chodesh (not RH), Chol HaMoed Pesach,
  //   last day(s) of Pesach.
  static const fullHallel = 'full_hallel';
  static const halfHallel = 'half_hallel';
  // hallel_with_musaf: Hallel (full or half) IS recited AND today is a
  // Musaf day. Triggers the post-Hallel Kaddish Titkabal sequence and,
  // for Sfard, the Shir Shel Yom (+ Barchi Nafshi on RC) + Kaddish Yatom
  // block that comes between Hallel and Kriat HaTorah on RC / Chol HaMoed.
  // On Chanukah (Hallel without Musaf) and Shabbat (Musaf without Hallel)
  // this flag is NOT set, leaving the regular flow intact.
  static const hallelWithMusaf = 'hallel_with_musaf';

  // ── Musaf ────────────────────────────────────────────────────────────────
  // musaf_day: a day on which Musaf is recited — Rosh Chodesh, Chol HaMoed,
  // Yom Tov, Shabbat. Affects sequencing after Hallel (Kaddish Titkabal +
  // Shir Shel Yom for Sfard before Kriat HaTorah) and triggers Brich Shmei
  // in EM Hotzaat Sefer Torah.
  static const musafDay = 'musaf_day';
  // musaf_content: a Musaf day for which the app currently has Musaf
  // content available — Rosh Chodesh, Chol HaMoed Pesach, Chol HaMoed
  // Sukkot. Yom Tov and Shabbat are intentionally excluded from D.12 scope
  // (per user). Gates the pre-Musaf Chatzi Kaddish + musaf sub-template
  // insertion in sof_hatfila, and excludes the standard closing Kaddish
  // Titkabal at end of acharei_amidah (since on Musaf-content days the
  // closing kaddish is recited AFTER Musaf, not before).
  static const musafContent = 'musaf_content';
  // shema_hotzaah: Shabbat, Yom Tov, or Hoshana Raba — days when the Shema
  // declaration is recited during hotzaat sefer Torah.
  static const shemaHotzaah = 'shema_hotzaah';

  // ── Nusach (mirrors UserContext.nusach, re-emitted as flags) ─────────────
  static const nusachAshkenaz = 'nusach_ashkenaz';
  static const nusachSfard = 'nusach_sfard';
  static const nusachEdotMizrach = 'nusach_edot_mizrach';

  // ── Lulav ────────────────────────────────────────────────────────────────
  // lulav_day: a day on which lulav is taken — Sukkot (incl. CHM + Hoshana
  // Raba), excluding Shabbat. Shemini Atzeret + Simchat Torah are
  // intentionally excluded (no lulav after 7th day). Gates the pre-Hallel
  // Birkat HaLulav + L'shem Yichud insertion in acharei_amidah.
  static const lulavDay = 'lulav_day';

  // ── Minyan ───────────────────────────────────────────────────────────────
  // with_minyan: user is davening with a minyan. Gates devarim shebikdushah:
  // Kaddish (all forms), Chazarat HaShatz (and Kedushah / Birkat Kohanim /
  // Modim deRabbanan inside it), Kriat HaTorah and Barchu, and Yud-Gimel
  // Middot inside Tachanun / Selichot. Default true in UserContext —
  // user toggles off when davening b'yechidut.
  static const withMinyan = 'with_minyan';
}
