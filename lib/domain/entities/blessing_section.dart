import 'package:freezed_annotation/freezed_annotation.dart';

part 'blessing_section.freezed.dart';
part 'blessing_section.g.dart';

@freezed
class BlessingSection with _$BlessingSection {
  const factory BlessingSection({
    required String text,
    @Default([]) @JsonKey(name: 'condition_flags') List<String> conditionFlags,
    @Default([]) @JsonKey(name: 'exclude_flags') List<String> excludeFlags,
    /// When true, the section is rendered as a rubric/instruction:
    /// system font, smaller, muted colour — separate from prayer body text.
    @Default(false) @JsonKey(name: 'is_rubric') bool isRubric,
  }) = _BlessingSection;

  factory BlessingSection.fromJson(Map<String, dynamic> json) =>
      _$BlessingSectionFromJson(json);
}
