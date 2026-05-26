import 'package:freezed_annotation/freezed_annotation.dart';

part 'assembled_segment.freezed.dart';

@freezed
class AssembledSegment with _$AssembledSegment {
  const factory AssembledSegment({
    required String id,
    required String resolvedText,
    @Default(false) bool optional,
    // Non-empty when this segment belongs to a collapsible group (e.g.
    // 'chazarat_hashatz'). Consecutive segments with the same groupId are
    // rendered as a single accordion by the presentation layer.
    @Default('') String groupId,
  }) = _AssembledSegment;
}
