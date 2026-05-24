import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_flags.freezed.dart';

/// The computed set of Halachic flags for a specific day + nusach combination.
/// Produced by [ICalendarFlagProvider] and merged into [UserContext.activeFlags].
@freezed
class DayFlags with _$DayFlags {
  const DayFlags._();

  const factory DayFlags({
    @Default([]) List<String> flags,
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

  DayFlags operator +(DayFlags other) =>
      DayFlags(flags: {...flags, ...other.flags}.toList());
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
  // shema_hotzaah: Shabbat, Yom Tov, or Hoshana Raba — days when the Shema
  // declaration is recited during hotzaat sefer Torah.
  static const shemaHotzaah = 'shema_hotzaah';

  // ── Nusach (mirrors UserContext.nusach, re-emitted as flags) ─────────────
  static const nusachAshkenaz = 'nusach_ashkenaz';
  static const nusachSfard = 'nusach_sfard';
  static const nusachEdotMizrach = 'nusach_edot_mizrach';
}
