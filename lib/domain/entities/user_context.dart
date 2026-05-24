import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_context.freezed.dart';

enum Gender { male, female }

/// Which Purim date(s) the user observes.
/// Fourteenth = regular cities (everywhere except walled cities).
/// Fifteenth  = walled cities (Jerusalem, etc.).
/// Both       = celebrates both days (e.g. living near a walled city).
enum PurimDate { fourteenth, fifteenth, both }

@freezed
class UserContext with _$UserContext {
  const factory UserContext({
    required String nusach,
    @Default(true) bool isInIsrael,
    @Default(Gender.male) Gender gender,
    @Default(PurimDate.fourteenth) PurimDate purimDate,
    // Populated by HalachicCalendarService each day.
    // Examples: 'shabbat', 'rosh_chodesh', 'skip_tachanun',
    // 'aseret_yemei_teshuva', 'skip_lamenatzeach', 'yaaleh_veyavo', etc.
    @Default([]) List<String> activeFlags,
    // 1..49 during the 49 days of Sefirat HaOmer (16 Nisan through 5 Sivan).
    // Null on every other day. The PrayerAssembler uses this to fetch the
    // matching row from `_omer_mapping.json` (text per nusach, sefira, and
    // the words/letter to bold in Ana BeKoach / Lamenatzeach / Yismechu).
    int? omerDay,
    // 1..7 during Sukkot (15–21 Tishrei). 1 = first day (Yom Tov),
    // 2..6 = Chol HaMoed, 7 = Hoshana Raba. Used to resolve the daily korban
    // in Musaf and other day-specific content. Null outside Sukkot.
    int? sukkotDay,
    // User is davening with a minyan. Drives the [DayFlag.withMinyan] flag,
    // which gates Kaddish / Chazarat HaShatz / Kriat HaTorah / Barchu /
    // Yud-Gimel Middot. Default true.
    @Default(true) bool withMinyan,
  }) = _UserContext;
}
