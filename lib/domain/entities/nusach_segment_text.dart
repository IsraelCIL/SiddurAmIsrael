import 'package:freezed_annotation/freezed_annotation.dart';

part 'nusach_segment_text.freezed.dart';
part 'nusach_segment_text.g.dart';

@freezed
class NusachSegmentText with _$NusachSegmentText {
  const factory NusachSegmentText({
    required String id,
    required String nusach,
    required String text,
    @Default({}) Map<String, String> variants,
    @JsonKey(name: 'has_nikud') @Default(false) bool hasNikud,
    @JsonKey(name: 'gender_tagged') @Default(false) bool genderTagged,
    @Default([]) List<String> sources,
  }) = _NusachSegmentText;

  factory NusachSegmentText.fromJson(Map<String, dynamic> json) =>
      _$NusachSegmentTextFromJson(json);
}
