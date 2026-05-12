import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_context.freezed.dart';

enum Gender { male, female }

@freezed
class UserContext with _$UserContext {
  const factory UserContext({
    required String nusach,
    @Default(true) bool isInIsrael,
    @Default(Gender.male) Gender gender,
    // Calendar + situational flags: 'shabbat', 'rosh_chodesh', 'skip_tachanun',
    // 'monday_thursday_mincha', nusach-scoped variants like 'skip_tachanun_sfard', etc.
    @Default([]) List<String> activeFlags,
  }) = _UserContext;
}
