import '../entities/assembled_segment.dart';
import '../entities/nusach_override.dart';
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
    final nusachOverride = await _repository.loadNusachOverride(
      userContext.nusach,
      templateId,
    );

    final results = <AssembledSegment>[];

    for (final entry in template.segments) {
      if (!_entryPassesFilters(entry, userContext, contextKeys)) continue;

      final segment = await _repository.loadSegment(entry.segmentId);

      if (!_segmentPassesFilters(segment, contextKeys)) continue;

      results.add(AssembledSegment(
        id: segment.id,
        resolvedText: _resolveText(segment, nusachOverride, contextKeys),
        optional: entry.optional || segment.optional,
      ));
    }

    return results;
  }

  // Derives the full set of context keys used for flag checks and text resolution.
  // Gender and Israel-status are normalized into flat strings so the resolution
  // algorithm treats them identically to calendar flags.
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
    // Nusach-specific segments: skip entirely when the user's nusach is not listed.
    if (entry.allowedNusach.isNotEmpty &&
        !entry.allowedNusach.contains(userContext.nusach)) {
      return false;
    }
    // All condition_flags must be present.
    if (!entry.conditionFlags.every(contextKeys.contains)) return false;
    // No exclude_flag may be present.
    if (entry.excludeFlags.any(contextKeys.contains)) return false;
    return true;
  }

  bool _segmentPassesFilters(PrayerSegment segment, List<String> contextKeys) {
    if (!segment.conditionFlags.every(contextKeys.contains)) return false;
    if (segment.excludeFlags.any(contextKeys.contains)) return false;
    return true;
  }

  // Priority resolution (highest to lowest):
  //   P1 — nusach override keyed as '{id}:{context}'
  //   P2 — nusach override keyed as '{id}'
  //   P3 — segment variant keyed by context string
  //   P4 — segment default_text
  String _resolveText(
    PrayerSegment segment,
    NusachOverride? override,
    List<String> contextKeys,
  ) {
    if (override != null) {
      for (final ctx in contextKeys) {
        final key = '${segment.id}:$ctx';
        if (override.overrides.containsKey(key)) return override.overrides[key]!;
      }
      if (override.overrides.containsKey(segment.id)) {
        return override.overrides[segment.id]!;
      }
    }
    for (final ctx in contextKeys) {
      if (segment.variants.containsKey(ctx)) return segment.variants[ctx]!;
    }
    return segment.defaultText;
  }
}
