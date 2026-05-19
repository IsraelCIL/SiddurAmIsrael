import '../entities/assembled_segment.dart';
import '../entities/nusach_segment_text.dart';
import '../entities/prayer_segment.dart';
import '../entities/prayer_template.dart';
import '../entities/user_context.dart';
import '../repositories/i_prayer_repository.dart';
import 'i_prayer_assembler.dart';

class PrayerAssembler implements IPrayerAssembler {
  const PrayerAssembler(this._repository);

  final IPrayerRepository _repository;

  @override
  Future<List<AssembledSegment>> assemble({
    required String templateId,
    required UserContext userContext,
  }) async {
    final template = await _repository.loadTemplate(templateId);
    final contextKeys = _buildContextKeys(userContext);
    final results = <AssembledSegment>[];

    for (final entry in template.segments) {
      if (!_entryPassesFilters(entry, userContext, contextKeys)) continue;

      final segment = await _repository.loadSegment(entry.segmentId);

      if (!_segmentPassesFilters(segment, contextKeys)) continue;

      final nusachText = await _repository.loadNusachSegmentText(
        userContext.nusach,
        entry.segmentId,
      );

      results.add(AssembledSegment(
        id: segment.id,
        resolvedText: _resolveText(segment, nusachText, contextKeys),
        optional: entry.optional || segment.optional,
      ));
    }

    return results;
  }

  List<String> _buildContextKeys(UserContext ctx) => [
        ...ctx.activeFlags,
        ctx.gender == Gender.male ? 'gender_male' : 'gender_female',
        ctx.isInIsrael ? 'in_israel' : 'not_in_israel',
      ];

  bool _entryPassesFilters(
    TemplateEntry entry,
    UserContext userContext,
    List<String> contextKeys,
  ) {
    if (entry.allowedNusach.isNotEmpty &&
        !entry.allowedNusach.contains(userContext.nusach)) {
      return false;
    }
    if (!entry.conditionFlags.every(contextKeys.contains)) return false;
    if (entry.excludeFlags.any(contextKeys.contains)) return false;
    return true;
  }

  bool _segmentPassesFilters(PrayerSegment segment, List<String> contextKeys) {
    if (!segment.conditionFlags.every(contextKeys.contains)) return false;
    if (segment.excludeFlags.any(contextKeys.contains)) return false;
    return true;
  }

  // Priority resolution (highest to lowest):
  //   P1 — nusach segment variant keyed by context flag
  //   P2 — nusach segment text (nusach-specific default)
  //   P3 — base segment variant keyed by context flag
  //   P4 — base segment default_text
  String _resolveText(
    PrayerSegment segment,
    NusachSegmentText? nusachText,
    List<String> contextKeys,
  ) {
    if (nusachText != null) {
      for (final ctx in contextKeys) {
        if (nusachText.variants.containsKey(ctx)) return nusachText.variants[ctx]!;
      }
      return nusachText.text;
    }
    for (final ctx in contextKeys) {
      if (segment.variants.containsKey(ctx)) return segment.variants[ctx]!;
    }
    return segment.defaultText;
  }
}
