import 'package:freezed_annotation/freezed_annotation.dart';

part 'blessing_section.freezed.dart';
part 'blessing_section.g.dart';

@freezed
class BlessingSection with _$BlessingSection {
  const factory BlessingSection({
    required String text,
    @Default([]) @JsonKey(name: 'condition_flags') List<String> conditionFlags,
    @Default([]) @JsonKey(name: 'exclude_flags') List<String> excludeFlags,
  }) = _BlessingSection;

  factory BlessingSection.fromJson(Map<String, dynamic> json) =>
      _$BlessingSectionFromJson(json);
}
