import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_siddur/domain/entities/assembled_segment.dart';
import 'package:smart_siddur/domain/entities/nusach_segment_text.dart';
import 'package:smart_siddur/domain/entities/prayer_segment.dart';
import 'package:smart_siddur/domain/entities/prayer_template.dart';
import 'package:smart_siddur/domain/entities/user_context.dart';
import 'package:smart_siddur/domain/repositories/i_prayer_repository.dart';
import 'package:smart_siddur/domain/services/prayer_assembler.dart';

class MockPrayerRepository extends Mock implements IPrayerRepository {}

void main() {
  late MockPrayerRepository repository;
  late PrayerAssembler assembler;

  setUp(() {
    repository = MockPrayerRepository();
    assembler = PrayerAssembler(repository);
  });

  const ashkUser = UserContext(nusach: 'ashkenaz');
  const sfardUser = UserContext(nusach: 'sfard');
  const edotUser = UserContext(nusach: 'edot_mizrach');

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void stubTemplate(String id, List<TemplateEntry> entries) {
    when(() => repository.loadTemplate(id)).thenAnswer(
      (_) async => PrayerTemplate(id: id, name: id, segments: entries),
    );
  }

  void stubSegment(String id,
      {String text = 'default', Map<String, String> variants = const {}}) {
    when(() => repository.loadSegment(id)).thenAnswer(
      (_) async => PrayerSegment(id: id, defaultText: text, variants: variants),
    );
  }

  void stubNoNusachText(String nusach) {
    when(() => repository.loadNusachSegmentText(nusach, any()))
        .thenAnswer((_) async => null);
  }

  // ---------------------------------------------------------------------------
  // Text resolution priorities
  // ---------------------------------------------------------------------------

  group('text resolution', () {
    test('P4 — returns default_text when nothing else matches', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubSegment('ashrei', text: 'default ashrei');
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result,
          [const AssembledSegment(id: 'ashrei', resolvedText: 'default ashrei')]);
    });

    test('P3 — segment variant wins over default_text', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubSegment('ashrei',
          text: 'default', variants: {'rosh_chodesh': 'rosh chodesh ashrei'});
      stubNoNusachText('sfard');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(nusach: 'sfard', activeFlags: ['rosh_chodesh']),
      );

      expect(result.single.resolvedText, 'rosh chodesh ashrei');
    });

    test('P2 — nusach text wins over segment variant', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubSegment('ashrei',
          text: 'default', variants: {'rosh_chodesh': 'rosh chodesh ashrei'});
      when(() => repository.loadNusachSegmentText('ashkenaz', 'ashrei'))
          .thenAnswer((_) async => const NusachSegmentText(
                id: 'ashrei',
                nusach: 'ashkenaz',
                text: 'ashkenaz ashrei',
              ));

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(nusach: 'ashkenaz', activeFlags: ['rosh_chodesh']),
      );

      expect(result.single.resolvedText, 'ashkenaz ashrei');
    });

    test('P1 — nusach variant wins over plain nusach text', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubSegment('ashrei', text: 'default');
      when(() => repository.loadNusachSegmentText('ashkenaz', 'ashrei'))
          .thenAnswer((_) async => const NusachSegmentText(
                id: 'ashrei',
                nusach: 'ashkenaz',
                text: 'ashkenaz ashrei',
                variants: {'rosh_chodesh': 'ashkenaz rosh chodesh ashrei'},
              ));

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(nusach: 'ashkenaz', activeFlags: ['rosh_chodesh']),
      );

      expect(result.single.resolvedText, 'ashkenaz rosh chodesh ashrei');
    });
  });

  // ---------------------------------------------------------------------------
  // Flag filtering — template level
  // ---------------------------------------------------------------------------

  group('template-level flag filtering', () {
    test('skips segment when exclude_flag is active', () async {
      stubTemplate('mincha', [
        const TemplateEntry(segmentId: 'tachanun', excludeFlags: ['skip_tachanun']),
      ]);
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(nusach: 'ashkenaz', activeFlags: ['skip_tachanun']),
      );

      expect(result, isEmpty);
    });

    test('includes segment when exclude_flag is NOT active', () async {
      stubTemplate('mincha', [
        const TemplateEntry(segmentId: 'tachanun', excludeFlags: ['skip_tachanun']),
      ]);
      stubSegment('tachanun', text: 'tachanun text');
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.id, 'tachanun');
    });

    test('skips segment when condition_flag is absent', () async {
      stubTemplate('mincha', [
        const TemplateEntry(
          segmentId: 'kriat_hatorah',
          conditionFlags: ['monday_thursday_mincha'],
        ),
      ]);
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result, isEmpty);
    });

    test('includes segment when all condition_flags are active', () async {
      stubTemplate('mincha', [
        const TemplateEntry(
          segmentId: 'kriat_hatorah',
          conditionFlags: ['monday_thursday_mincha'],
        ),
      ]);
      stubSegment('kriat_hatorah', text: 'torah reading');
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(
          nusach: 'ashkenaz',
          activeFlags: ['monday_thursday_mincha'],
        ),
      );

      expect(result.single.id, 'kriat_hatorah');
    });
  });

  // ---------------------------------------------------------------------------
  // allowed_nusach gating
  // ---------------------------------------------------------------------------

  group('allowed_nusach', () {
    test('skips segment when user nusach is not in allowed_nusach', () async {
      stubTemplate('mincha', [
        const TemplateEntry(
          segmentId: 'petihat_eliyahu',
          allowedNusach: ['edot_mizrach'],
        ),
      ]);
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result, isEmpty);
    });

    test('skips for sfard when only edot_mizrach is allowed', () async {
      stubTemplate('mincha', [
        const TemplateEntry(
          segmentId: 'petihat_eliyahu',
          allowedNusach: ['edot_mizrach'],
        ),
      ]);
      stubNoNusachText('sfard');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: sfardUser,
      );

      expect(result, isEmpty);
    });

    test('includes segment when user nusach matches allowed_nusach', () async {
      stubTemplate('mincha', [
        const TemplateEntry(
          segmentId: 'petihat_eliyahu',
          allowedNusach: ['edot_mizrach'],
        ),
      ]);
      stubSegment('petihat_eliyahu', text: 'eliyahu text');
      stubNoNusachText('edot_mizrach');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: edotUser,
      );

      expect(result.single.id, 'petihat_eliyahu');
    });

    test('includes segment for all nusachim when allowed_nusach is empty', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubSegment('ashrei', text: 'ashrei text');
      stubNoNusachText('ashkenaz');
      stubNoNusachText('sfard');
      stubNoNusachText('edot_mizrach');

      for (final user in [ashkUser, sfardUser, edotUser]) {
        final result = await assembler.assemble(
          templateId: 'mincha',
          userContext: user,
        );
        expect(result.single.id, 'ashrei', reason: 'nusach: ${user.nusach}');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // UserContext — gender and Israel
  // ---------------------------------------------------------------------------

  group('user context keys', () {
    test('gender_female resolves to female variant', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'modeh_ani')]);
      stubSegment('modeh_ani',
          text: 'מוֹדֶה אֲנִי',
          variants: {'gender_female': 'מוֹדָה אֲנִי'});
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(nusach: 'ashkenaz', gender: Gender.female),
      );

      expect(result.single.resolvedText, 'מוֹדָה אֲנִי');
    });

    test('gender_male resolves to default when no male variant defined', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'modeh_ani')]);
      stubSegment('modeh_ani',
          text: 'מוֹדֶה אֲנִי',
          variants: {'gender_female': 'מוֹדָה אֲנִי'});
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(nusach: 'ashkenaz', gender: Gender.male),
      );

      expect(result.single.resolvedText, 'מוֹדֶה אֲנִי');
    });

    test('not_in_israel context key is active when isInIsrael is false', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'musaf_note')]);
      stubSegment('musaf_note',
          text: 'tefila b\'israel',
          variants: {'not_in_israel': 'tefila b\'chutz laaretz'});
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(nusach: 'ashkenaz', isInIsrael: false),
      );

      expect(result.single.resolvedText, "tefila b'chutz laaretz");
    });
  });

  // ---------------------------------------------------------------------------
  // Segment-level flag filtering
  // ---------------------------------------------------------------------------

  group('segment-level flag filtering', () {
    test('skips segment when segment exclude_flag is active', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'special')]);
      when(() => repository.loadSegment('special')).thenAnswer((_) async =>
          const PrayerSegment(
            id: 'special',
            defaultText: 'text',
            excludeFlags: ['some_flag'],
          ));
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(nusach: 'ashkenaz', activeFlags: ['some_flag']),
      );

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // optional flag propagation
  // ---------------------------------------------------------------------------

  group('optional flag', () {
    test('assembled segment is optional when template entry is optional', () async {
      stubTemplate('mincha', [
        const TemplateEntry(segmentId: 'ashrei', optional: true),
      ]);
      stubSegment('ashrei', text: 'ashrei');
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.optional, isTrue);
    });

    test('assembled segment is optional when segment itself is optional', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      when(() => repository.loadSegment('ashrei')).thenAnswer((_) async =>
          const PrayerSegment(id: 'ashrei', defaultText: 'text', optional: true));
      stubNoNusachText('ashkenaz');

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.optional, isTrue);
    });
  });
}
