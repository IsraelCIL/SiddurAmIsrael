import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/blessing_section.dart';
import 'package:siddur_am_israel_chai/domain/entities/prayer_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/prayer_template.dart';
import 'package:siddur_am_israel_chai/domain/entities/user_context.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_prayer_repository.dart';
import 'package:siddur_am_israel_chai/domain/services/prayer_assembler.dart';

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
  // Stub helpers
  // ---------------------------------------------------------------------------

  void stubTemplate(String id, List<TemplateEntry> entries) {
    when(() => repository.loadTemplate(id)).thenAnswer(
      (_) async => PrayerTemplate(id: id, name: id, segments: entries),
    );
  }

  void stubNusachSegment(String nusach, String id, PrayerSegment segment) {
    when(() => repository.loadNusachSegment(nusach, id))
        .thenAnswer((_) async => segment);
  }

  void stubSegmentForAllNusachim(String id, {String text = 'default'}) {
    for (final nusach in ['ashkenaz', 'sfard', 'edot_mizrach']) {
      stubNusachSegment(
        nusach,
        id,
        PrayerSegment(
          id: id,
          sections: [BlessingSection(text: text)],
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Template-level flag filtering
  // ---------------------------------------------------------------------------

  group('template-level flag filtering', () {
    test('skips segment when exclude_flag is active', () async {
      stubTemplate('mincha', [
        const TemplateEntry(segmentId: 'tachanun', excludeFlags: ['skip_tachanun']),
      ]);

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
      stubNusachSegment(
        'ashkenaz', 'tachanun',
        const PrayerSegment(
          id: 'tachanun',
          sections: [BlessingSection(text: 'tachanun text')],
        ),
      );

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
      stubNusachSegment(
        'ashkenaz', 'kriat_hatorah',
        const PrayerSegment(id: 'kriat_hatorah', sections: []),
      );

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
      stubNusachSegment(
        'edot_mizrach', 'petihat_eliyahu',
        const PrayerSegment(
          id: 'petihat_eliyahu',
          sections: [BlessingSection(text: 'eliyahu text')],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: edotUser,
      );

      expect(result.single.id, 'petihat_eliyahu');
    });

    test('includes segment for all nusachim when allowed_nusach is empty', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubSegmentForAllNusachim('ashrei', text: 'ashrei text');

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
  // Section-level conditional assembly
  // ---------------------------------------------------------------------------

  group('section-level conditional assembly', () {
    test('includes section when its condition_flag is active', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'modim')]);
      stubNusachSegment(
        'ashkenaz', 'modim',
        const PrayerSegment(
          id: 'modim',
          sections: [
            BlessingSection(text: 'main text'),
            BlessingSection(
                text: 'al hanisim', conditionFlags: ['al_hanisim']),
          ],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(nusach: 'ashkenaz', activeFlags: ['al_hanisim']),
      );

      expect(result.single.resolvedText, 'main text\nal hanisim');
    });

    test('excludes section when its condition_flag is absent', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'modim')]);
      stubNusachSegment(
        'ashkenaz', 'modim',
        const PrayerSegment(
          id: 'modim',
          sections: [
            BlessingSection(text: 'main text'),
            BlessingSection(
                text: 'al hanisim', conditionFlags: ['al_hanisim']),
          ],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.resolvedText, 'main text');
    });

    test('excludes section when its exclude_flag is active', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'shalom')]);
      stubNusachSegment(
        'ashkenaz', 'shalom',
        const PrayerSegment(
          id: 'shalom',
          sections: [
            BlessingSection(text: 'shalom rav', excludeFlags: ['fast_day']),
            BlessingSection(
                text: 'sim shalom', conditionFlags: ['fast_day']),
          ],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: UserContext(nusach: 'ashkenaz', activeFlags: ['fast_day']),
      );

      expect(result.single.resolvedText, 'sim shalom');
    });

    test('gender_female section is included when Gender.female is set', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'modeh_ani')]);
      stubNusachSegment(
        'ashkenaz', 'modeh_ani',
        const PrayerSegment(
          id: 'modeh_ani',
          sections: [
            BlessingSection(
                text: 'מוֹדֶה אֲנִי',
                excludeFlags: ['gender_female']),
            BlessingSection(
                text: 'מוֹדָה אֲנִי',
                conditionFlags: ['gender_female']),
          ],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(nusach: 'ashkenaz', gender: Gender.female),
      );

      expect(result.single.resolvedText, 'מוֹדָה אֲנִי');
    });

    test('not_in_israel section is included when isInIsrael is false', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'musaf_note')]);
      stubNusachSegment(
        'ashkenaz', 'musaf_note',
        const PrayerSegment(
          id: 'musaf_note',
          sections: [
            BlessingSection(
                text: 'tefila b\'chutz laaretz',
                conditionFlags: ['not_in_israel']),
          ],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(nusach: 'ashkenaz', isInIsrael: false),
      );

      expect(result.single.resolvedText, "tefila b'chutz laaretz");
    });

    test('empty sections produce empty resolved text', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'placeholder')]);
      stubNusachSegment(
        'ashkenaz', 'placeholder',
        const PrayerSegment(id: 'placeholder', sections: []),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.resolvedText, '');
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
      stubNusachSegment(
        'ashkenaz', 'ashrei',
        const PrayerSegment(
          id: 'ashrei',
          sections: [BlessingSection(text: 'ashrei')],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.optional, isTrue);
    });

    test('assembled segment is optional when segment itself is optional', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubNusachSegment(
        'ashkenaz', 'ashrei',
        const PrayerSegment(
          id: 'ashrei',
          sections: [BlessingSection(text: 'text')],
          optional: true,
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.optional, isTrue);
    });

    test('assembled segment is not optional by default', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubNusachSegment(
        'ashkenaz', 'ashrei',
        const PrayerSegment(
          id: 'ashrei',
          sections: [BlessingSection(text: 'text')],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.optional, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // AssembledSegment value equality
  // ---------------------------------------------------------------------------

  group('AssembledSegment', () {
    test('resolves single section text correctly', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'ashrei')]);
      stubNusachSegment(
        'ashkenaz', 'ashrei',
        const PrayerSegment(
          id: 'ashrei',
          sections: [BlessingSection(text: 'אַשְׁרֵי יוֹשְׁבֵי בֵיתֶֽךָ')],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result,
          [const AssembledSegment(id: 'ashrei', resolvedText: 'אַשְׁרֵי יוֹשְׁבֵי בֵיתֶֽךָ')]);
    });

    test('joins multiple active sections with newline', () async {
      stubTemplate('mincha', [const TemplateEntry(segmentId: 'test')]);
      stubNusachSegment(
        'ashkenaz', 'test',
        const PrayerSegment(
          id: 'test',
          sections: [
            BlessingSection(text: 'section one'),
            BlessingSection(text: 'section two'),
          ],
        ),
      );

      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: ashkUser,
      );

      expect(result.single.resolvedText, 'section one\nsection two');
    });
  });
}
