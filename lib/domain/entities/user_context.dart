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
  }) = _UserContext;
}
