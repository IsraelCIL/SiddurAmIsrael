import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:siddur_am_israel_chai/domain/entities/blessing_section.dart';

part 'prayer_segment.freezed.dart';
part 'prayer_segment.g.dart';

@freezed
class PrayerSegment with _$PrayerSegment {
  const factory PrayerSegment({
    required String id,
    @Default([]) List<BlessingSection> sections,
    @Default([]) @JsonKey(name: 'condition_flags') List<String> conditionFlags,
    @Default([]) @JsonKey(name: 'exclude_flags') List<String> excludeFlags,
    @Default(false) bool optional,
  }) = _PrayerSegment;

  factory PrayerSegment.fromJson(Map<String, dynamic> json) =>
      _$PrayerSegmentFromJson(json);
}
