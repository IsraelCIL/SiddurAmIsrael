import '../entities/assembled_segment.dart';
import '../entities/blessing_section.dart';
import '../entities/prayer_template.dart';
import '../entities/user_context.dart';
import '../repositories/i_gra_ssy_repository.dart';
import '../repositories/i_kriah_repository.dart';
import '../repositories/i_omer_mapping_repository.dart';
import '../repositories/i_prayer_repository.dart';
import '../repositories/i_sukkot_korbanot_repository.dart';
import 'i_prayer_assembler.dart';
import 'omer_post_processor.dart';
import 'sukkot_korbanot_post_processor.dart';

class PrayerAssembler implements IPrayerAssembler {
  const PrayerAssembler(
    this._repository, {
    IOmerMappingRepository? omerRepository,
    ISukkotKorbanotRepository? sukkotRepository,
    IGraSsyRepository? graSsyRepository,
    IKriahRepository? kriahRepository,
    OmerPostProcessor omerProcessor = const OmerPostProcessor(),
    SukkotKorbanotPostProcessor sukkotProcessor = const SukkotKorbanotPostProcessor(),
  })  : _omerRepository = omerRepository,
        _omerProcessor = omerProcessor,
        _sukkotRepository = sukkotRepository,
        _sukkotProcessor = sukkotProcessor,
        _graSsyRepository = graSsyRepository,
        _kriahRepository = kriahRepository;

  final IPrayerRepository _repository;
  final IOmerMappingRepository? _omerRepository;
  final OmerPostProcessor _omerProcessor;
  final ISukkotKorbanotRepository? _sukkotRepository;
  final SukkotKorbanotPostProcessor _sukkotProcessor;
  final IGraSsyRepository? _graSsyRepository;
  final IKriahRepository? _kriahRepository;

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

    var out = results;

    // Sefirat HaOmer post-processing: fill {{omer_day_count}} / {{omer_sefira}}
    // placeholders and inject <b>...</b> bold tokens into Lamenatzeach + Ana
    // BeKoach for the day's word/letter highlights.
    if (userContext.omerDay != null && _omerRepository != null) {
      final day = await _omerRepository!.loadDay(userContext.omerDay!);
      out = [for (final s in out) _omerProcessor.process(s, day, userContext.nusach)];
    }

    // Sukkot daily korban: fill {{daily_korban}} in
    // amidah_musaf_intermediate_chm_sukkot with the day's pasuk from
    // Numbers 29 (per sukkotDay and isInIsrael).
    if (userContext.sukkotDay != null && _sukkotRepository != null) {
      final day = await _sukkotRepository!.loadDay(userContext.sukkotDay!);
      out = [
        for (final s in out)
          _sukkotProcessor.process(s, day, isInIsrael: userContext.isInIsrael),
      ];
    }

    // Kriat HaTorah Mon/Thu: resolve the upcoming parashah's reading text
    // and inject into the `kriat_hatorah_reading_text` placeholder. Only
    // fires when kriat_hatorah_mon_thu is in activeFlags (gate is also
    // applied at the template level — this is a defensive guard).
    if (userContext.upcomingParshah != null &&
        userContext.activeFlags.contains('kriat_hatorah_mon_thu') &&
        _kriahRepository != null) {
      final text =
          await _kriahRepository!.loadMonThuReading(userContext.upcomingParshah!);
      if (text != null) {
        out = [
          for (final s in out)
            s.id == 'kriat_hatorah_reading_text'
                ? s.copyWith(resolvedText: text)
                : s,
        ];
      }
    }

    // Gr"a Shir Shel Yom: resolve and inject the day's Tehillim chapter
    // into the `shir_shel_yom_gra` segment (optional accordion). Only
    // runs on CHM Pesach + CHM Sukkot where the chag-day flags are set.
    if (userContext.chagYt1Weekday != null && _graSsyRepository != null) {
      final chag = userContext.sukkotDay != null ? 'sukkot' : 'pesach';
      final dayInChag = userContext.sukkotDay ?? userContext.pesachDay;
      if (dayInChag != null) {
        final text = await _graSsyRepository!.resolveChapter(
          chag: chag,
          yt1Weekday: userContext.chagYt1Weekday!,
          dayInChag: dayInChag,
        );
        if (text != null) {
          out = [
            for (final s in out)
              s.id == 'shir_shel_yom_gra' ? s.copyWith(resolvedText: text) : s,
          ];
        }
      }
    }

    return out;
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
