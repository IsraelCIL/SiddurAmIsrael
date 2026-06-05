import 'package:flutter_test/flutter_test.dart';
import 'package:siddur_am_israel_chai/domain/entities/blessing_section.dart';
import 'package:siddur_am_israel_chai/domain/entities/prayer_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/prayer_template.dart';
import 'package:siddur_am_israel_chai/domain/entities/user_context.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_prayer_repository.dart';
import 'package:siddur_am_israel_chai/domain/services/prayer_assembler.dart';

// ---------------------------------------------------------------------------
// IDs for the 21 Amidah blessings in order
// ---------------------------------------------------------------------------

const _amidahSegmentIds = [
  'amidah_intro',
  'amidah_avot',
  'amidah_gevurot',
  'amidah_kedushah_hashem',
  'amidah_daat',
  'amidah_teshuva',
  'amidah_selicha',
  'amidah_geula',
  'amidah_refuah',
  'amidah_shanim',
  'amidah_galuyot',
  'amidah_mishpat',
  'amidah_minim',
  'amidah_tzaddikim',
  'amidah_yerushalayim',
  'amidah_david',
  'amidah_shema_koleinu',
  'amidah_retzeh',
  'amidah_modim',
  'amidah_shalom',
  'amidah_conclusion',
];

// Simple stub texts — enough to distinguish nusachim in assertions.
const _sfardDaat = '[Sfard daat — חכמה בינה ודעת]';
const _emDaat = '[EM daat — חכמה בינה ודעת (EM)]';

const _sfardShanim = '[Sfard shanim — summer כי אל טוב ומטיב]';
const _emShanimSummer = '[EM shanim — summer ברכנו]';
const _emShanimWinter = '[EM shanim — winter ברך עלינו + שמרה]';

const _ashkTachanun = '[Ashkenaz Tachanun — Psalm 6 + Shomer Yisrael]';
const _sfardTachanun = '[Sfard Tachanun — Vidui + 13 Middot + Psalm 6]';
const _emTachanun = '[Edot HaMizrach Tachanun — Vidui + 13 Middot + Psalm 25]';

const _ashkAleinu = '[Ashkenaz Aleinu]';
const _sfardAleinu = '[Sfard Aleinu]';
const _emAleinu = '[Edot HaMizrach Aleinu]';

const _emKaddish = '[Edot HaMizrach Kaddish Yatom]';

// ---------------------------------------------------------------------------
// Template matching assets/prayers/templates/mincha.json
// ---------------------------------------------------------------------------

const _minchaTemplate = PrayerTemplate(
  id: 'mincha',
  name: 'מנחה',
  segments: [
    TemplateEntry(segmentId: 'ashrei'),
    TemplateEntry(segmentId: 'petihat_eliyahu', allowedNusach: ['edot_mizrach']),
    TemplateEntry(
      segmentId: 'kriat_hatorah_mincha',
      conditionFlags: ['monday_thursday_mincha'],
      optional: true,
    ),
    TemplateEntry(segmentId: 'amidah_intro'),
    TemplateEntry(segmentId: 'amidah_avot'),
    TemplateEntry(segmentId: 'amidah_gevurot'),
    TemplateEntry(segmentId: 'amidah_kedushah_hashem'),
    TemplateEntry(segmentId: 'amidah_daat'),
    TemplateEntry(segmentId: 'amidah_teshuva'),
    TemplateEntry(segmentId: 'amidah_selicha'),
    TemplateEntry(segmentId: 'amidah_geula'),
    TemplateEntry(segmentId: 'amidah_refuah'),
    TemplateEntry(segmentId: 'amidah_shanim'),
    TemplateEntry(segmentId: 'amidah_galuyot'),
    TemplateEntry(segmentId: 'amidah_mishpat'),
    TemplateEntry(segmentId: 'amidah_minim'),
    TemplateEntry(segmentId: 'amidah_tzaddikim'),
    TemplateEntry(segmentId: 'amidah_yerushalayim'),
    TemplateEntry(segmentId: 'amidah_david'),
    TemplateEntry(segmentId: 'amidah_shema_koleinu'),
    TemplateEntry(segmentId: 'amidah_retzeh'),
    TemplateEntry(segmentId: 'amidah_modim'),
    TemplateEntry(segmentId: 'amidah_shalom'),
    TemplateEntry(segmentId: 'amidah_conclusion'),
    TemplateEntry(segmentId: 'tachanun', excludeFlags: ['skip_tachanun']),
    TemplateEntry(segmentId: 'aleinu'),
    TemplateEntry(segmentId: 'kaddish_yatom', allowedNusach: ['edot_mizrach']),
  ],
);

// ---------------------------------------------------------------------------
// Fake repository — flat per-nusach lookup, zero fallback logic
// ---------------------------------------------------------------------------

class _FakePrayerRepository implements IPrayerRepository {
  @override
  Future<PrayerTemplate> loadTemplate(String id) async => _minchaTemplate;

  @override
  Future<PrayerSegment> loadNusachSegment(
    String nusach,
    String id,
  ) async {
    return switch ((nusach, id)) {
      // ── amidah_daat nusach variants ──────────────────────────────────────
      ('sfard', 'amidah_daat') => PrayerSegment(
          id: 'amidah_daat',
          sections: [BlessingSection(text: _sfardDaat)]),
      ('edot_mizrach', 'amidah_daat') => PrayerSegment(
          id: 'amidah_daat',
          sections: [BlessingSection(text: _emDaat)]),

      // ── amidah_shanim with section-based condition flags ─────────────────
      ('sfard', 'amidah_shanim') => PrayerSegment(
          id: 'amidah_shanim',
          sections: [
            BlessingSection(text: _sfardShanim, excludeFlags: ['tal_umatar']),
            BlessingSection(
                text: '[Sfard shanim — winter]',
                conditionFlags: ['tal_umatar']),
          ]),
      ('edot_mizrach', 'amidah_shanim') => PrayerSegment(
          id: 'amidah_shanim',
          sections: [
            BlessingSection(
                text: _emShanimSummer, excludeFlags: ['tal_umatar']),
            BlessingSection(
                text: _emShanimWinter, conditionFlags: ['tal_umatar']),
          ]),

      // ── tachanun ─────────────────────────────────────────────────────────
      ('ashkenaz', 'tachanun') => PrayerSegment(
          id: 'tachanun',
          sections: [BlessingSection(text: _ashkTachanun)]),
      ('sfard', 'tachanun') => PrayerSegment(
          id: 'tachanun',
          sections: [BlessingSection(text: _sfardTachanun)]),
      ('edot_mizrach', 'tachanun') => PrayerSegment(
          id: 'tachanun',
          sections: [BlessingSection(text: _emTachanun)]),

      // ── aleinu ───────────────────────────────────────────────────────────
      ('ashkenaz', 'aleinu') => PrayerSegment(
          id: 'aleinu',
          sections: [BlessingSection(text: _ashkAleinu)]),
      ('sfard', 'aleinu') => PrayerSegment(
          id: 'aleinu',
          sections: [BlessingSection(text: _sfardAleinu)]),
      ('edot_mizrach', 'aleinu') => PrayerSegment(
          id: 'aleinu',
          sections: [BlessingSection(text: _emAleinu)]),

      // ── kaddish_yatom (edot_mizrach only) ────────────────────────────────
      ('edot_mizrach', 'kaddish_yatom') => PrayerSegment(
          id: 'kaddish_yatom',
          sections: [BlessingSection(text: _emKaddish)]),

      // ── all other segments (generic per-nusach stub) ──────────────────────
      _ => PrayerSegment(
          id: id,
          sections: [BlessingSection(text: '[$id — $nusach]')]),
    };
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late PrayerAssembler assembler;

  setUp(() => assembler = PrayerAssembler(_FakePrayerRepository()));

  const ashkUser = UserContext(nusach: 'ashkenaz');
  const sfardUser = UserContext(nusach: 'sfard');
  const emUser = UserContext(nusach: 'edot_mizrach');

  // ── Ashkenaz ─────────────────────────────────────────────────────────────

  group('Mincha — Ashkenaz weekday', () {
    test('includes ashrei, all 21 amidah blessings, tachanun, aleinu', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final ids = result.map((s) => s.id).toList();
      expect(ids.first, 'ashrei');
      for (final id in _amidahSegmentIds) {
        expect(ids, contains(id), reason: 'Missing $id');
      }
      expect(ids, contains('tachanun'));
      expect(ids, contains('aleinu'));
    });

    test('does NOT include petihat_eliyahu or kaddish_yatom', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final ids = result.map((s) => s.id).toSet();
      expect(ids, isNot(contains('petihat_eliyahu')));
      expect(ids, isNot(contains('kaddish_yatom')));
    });

    test('amidah_daat resolves to Ashkenaz text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final daat = result.firstWhere((s) => s.id == 'amidah_daat');
      expect(daat.resolvedText, '[amidah_daat — ashkenaz]');
    });

    test('tachanun resolves to Ashkenaz text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final tachanun = result.firstWhere((s) => s.id == 'tachanun');
      expect(tachanun.resolvedText, _ashkTachanun);
    });
  });

  // ── Sfard ─────────────────────────────────────────────────────────────────

  group('Mincha — Sfard weekday', () {
    test('includes ashrei, all 21 amidah blessings, tachanun, aleinu', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: sfardUser);
      final ids = result.map((s) => s.id).toList();
      for (final id in _amidahSegmentIds) {
        expect(ids, contains(id), reason: 'Missing $id');
      }
    });

    test('amidah_daat resolves to Sfard text (חכמה בינה ודעת)', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: sfardUser);
      final daat = result.firstWhere((s) => s.id == 'amidah_daat');
      expect(daat.resolvedText, _sfardDaat);
    });

    test('amidah_shanim resolves to Sfard summer text (no tal_umatar)', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: sfardUser);
      final shanim = result.firstWhere((s) => s.id == 'amidah_shanim');
      expect(shanim.resolvedText, _sfardShanim);
    });

    test('tachanun resolves to Sfard text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: sfardUser);
      final tachanun = result.firstWhere((s) => s.id == 'tachanun');
      expect(tachanun.resolvedText, _sfardTachanun);
    });
  });

  // ── Edot HaMizrach ────────────────────────────────────────────────────────

  group('Mincha — Edot HaMizrach weekday', () {
    test('includes petihat_eliyahu, all 21 amidah blessings, kaddish_yatom',
        () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final ids = result.map((s) => s.id).toList();
      expect(ids, contains('petihat_eliyahu'));
      for (final id in _amidahSegmentIds) {
        expect(ids, contains(id), reason: 'Missing $id');
      }
      expect(ids, contains('kaddish_yatom'));
    });

    test('amidah_daat resolves to EM text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final daat = result.firstWhere((s) => s.id == 'amidah_daat');
      expect(daat.resolvedText, _emDaat);
    });

    test('amidah_shanim resolves to EM summer text (no tal_umatar)', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final shanim = result.firstWhere((s) => s.id == 'amidah_shanim');
      expect(shanim.resolvedText, _emShanimSummer);
    });

    test('amidah_shanim resolves to EM winter text when tal_umatar is active',
        () async {
      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(
          nusach: 'edot_mizrach',
          activeFlags: ['tal_umatar'],
        ),
      );
      final shanim = result.firstWhere((s) => s.id == 'amidah_shanim');
      expect(shanim.resolvedText, _emShanimWinter);
    });

    test('tachanun resolves to EM text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final tachanun = result.firstWhere((s) => s.id == 'tachanun');
      expect(tachanun.resolvedText, _emTachanun);
    });

    test('kaddish_yatom resolves to EM text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final kaddish = result.firstWhere((s) => s.id == 'kaddish_yatom');
      expect(kaddish.resolvedText, _emKaddish);
    });
  });

  // ── Section-based conditional assembly ───────────────────────────────────

  group('Section-based conditional assembly', () {
    test('amidah_shanim: Ashkenaz summer (no tal_umatar) uses ashkenaz section',
        () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final shanim = result.firstWhere((s) => s.id == 'amidah_shanim');
      expect(shanim.resolvedText, '[amidah_shanim — ashkenaz]');
    });

    test('amidah_shanim: Sfard winter (tal_umatar active) uses winter section',
        () async {
      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(
          nusach: 'sfard',
          activeFlags: ['tal_umatar'],
        ),
      );
      final shanim = result.firstWhere((s) => s.id == 'amidah_shanim');
      expect(shanim.resolvedText, '[Sfard shanim — winter]');
    });
  });

  // ── Tachanun exclusion ────────────────────────────────────────────────────

  group('Tachanun exclusion', () {
    test('tachanun is absent for all nusachim when skip_tachanun is active',
        () async {
      for (final nusach in ['ashkenaz', 'sfard', 'edot_mizrach']) {
        final result = await assembler.assemble(
          templateId: 'mincha',
          userContext:
              UserContext(nusach: nusach, activeFlags: ['skip_tachanun']),
        );
        expect(result.map((s) => s.id), isNot(contains('tachanun')),
            reason:
                '$nusach: tachanun must be absent when skip_tachanun is active');
      }
    });

    test('tachanun is present when skip_tachanun is NOT active', () async {
      for (final nusach in ['ashkenaz', 'sfard', 'edot_mizrach']) {
        final result = await assembler.assemble(
          templateId: 'mincha',
          userContext: UserContext(nusach: nusach),
        );
        expect(result.map((s) => s.id), contains('tachanun'),
            reason: '$nusach: tachanun must be present on a regular weekday');
      }
    });
  });

  // ── Monday/Thursday Torah reading ─────────────────────────────────────────

  group('Kriat HaTorah (Monday/Thursday)', () {
    test('kriat_hatorah_mincha is absent on a regular weekday', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      expect(result.map((s) => s.id), isNot(contains('kriat_hatorah_mincha')));
    });

    test(
        'kriat_hatorah_mincha is included when monday_thursday_mincha is active',
        () async {
      final result = await assembler.assemble(
        templateId: 'mincha',
        userContext: const UserContext(
          nusach: 'ashkenaz',
          activeFlags: ['monday_thursday_mincha'],
        ),
      );
      expect(result.map((s) => s.id), contains('kriat_hatorah_mincha'));
    });
  });
}
