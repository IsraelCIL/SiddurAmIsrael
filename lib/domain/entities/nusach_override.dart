import 'package:freezed_annotation/freezed_annotation.dart';

part 'nusach_override.freezed.dart';
part 'nusach_override.g.dart';

@freezed
class NusachOverride with _$NusachOverride {
  const factory NusachOverride({
    required String nusach,
    @JsonKey(name: 'prayer_id') required String prayerId,
    // Keys are either '{segment_id}' (P2) or '{segment_id}:{context}' (P1).
    @Default({}) Map<String, String> overrides,
  }) = _NusachOverride;

  factory NusachOverride.fromJson(Map<String, dynamic> json) =>
      _$NusachOverrideFromJson(json);
}
