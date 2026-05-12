import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_segment.freezed.dart';
part 'prayer_segment.g.dart';

@freezed
class PrayerSegment with _$PrayerSegment {
  const factory PrayerSegment({
    required String id,
    @JsonKey(name: 'default_text') required String defaultText,
    // Keys are flat context strings: 'shabbat_mincha', 'gender_female', etc.
    @Default({}) Map<String, String> variants,
    @Default([]) @JsonKey(name: 'condition_flags') List<String> conditionFlags,
    @Default([]) @JsonKey(name: 'exclude_flags') List<String> excludeFlags,
    @Default(false) bool optional,
  }) = _PrayerSegment;

  factory PrayerSegment.fromJson(Map<String, dynamic> json) =>
      _$PrayerSegmentFromJson(json);
}
