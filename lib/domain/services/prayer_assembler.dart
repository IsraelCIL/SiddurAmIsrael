import '../entities/assembled_segment.dart';
import '../entities/blessing_section.dart';
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

      if (entry.subTemplateId.isNotEmpty) {
        final subSegments = await assemble(
          templateId: entry.subTemplateId,
          userContext: userContext,
        );
        results.addAll(subSegments);
        continue;
      }

      final segment = await _repository.loadNusachSegment(
        userContext.nusach,
        entry.segmentId,
      );

      results.add(AssembledSegment(
        id: segment.id,
        resolvedText: _assembleSections(segment.sections, contextKeys),
        optional: entry.optional || segment.optional,
      ));
    }

    return results;
  }

  List<String> _buildContextKeys(UserContext ctx) => [
        ...ctx.activeFlags,
        ctx.gender == Gender.male ? 'gender_male' : 'gender_female',
        ctx.isInIsrael ? 'in_israel' : 'not_in_israel',
        'nusach_${ctx.nusach}',
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

  String _assembleSections(List<BlessingSection> sections, List<String> contextKeys) {
    return sections
        .where((s) => s.conditionFlags.every(contextKeys.contains))
        .where((s) => !s.excludeFlags.any(contextKeys.contains))
        .map((s) => s.text)
        .where((t) => t.isNotEmpty)
        .join('\n');
  }
}
