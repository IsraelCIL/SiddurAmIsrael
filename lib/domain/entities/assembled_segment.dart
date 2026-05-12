import 'package:freezed_annotation/freezed_annotation.dart';

part 'assembled_segment.freezed.dart';

@freezed
class AssembledSegment with _$AssembledSegment {
  const factory AssembledSegment({
    required String id,
    required String resolvedText,
    @Default(false) bool optional,
  }) = _AssembledSegment;
}
