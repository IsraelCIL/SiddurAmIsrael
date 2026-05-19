import 'package:flutter_test/flutter_test.dart';
import 'package:smart_siddur/domain/entities/nusach_segment_text.dart';
import 'package:smart_siddur/domain/entities/prayer_segment.dart';
import 'package:smart_siddur/domain/entities/prayer_template.dart';
import 'package:smart_siddur/domain/entities/user_context.dart';
import 'package:smart_siddur/domain/repositories/i_prayer_repository.dart';
import 'package:smart_siddur/domain/services/prayer_assembler.dart';

// ---------------------------------------------------------------------------
// Fake repository with realistic Mincha data
// ---------------------------------------------------------------------------

// Abbreviated representative texts — enough to distinguish nusachim in tests.
const _ashkAmidah = '[Ashkenaz Amida — 18 blessings weekday]';
const _sfardAmidah = '[Sfard Amida — weekday]';
const _emAmidah = '[Edot HaMizrach Amida — weekday]';

const _ashkTachanun = '[Ashkenaz Tachanun — Psalm 6 + Shomer Yisrael]';
const _sfardTachanun = '[Sfard Tachanun — Vidui + 13 Middot + Psalm 6]';
const _emTachanun = '[Edot HaMizrach Tachanun — Vidui + 13 Middot + Psalm 25]';

const _ashkAleinu = '[Ashkenaz Aleinu]';
const _sfardAleinu = '[Sfard Aleinu]';
const _emAleinu = '[Edot HaMizrach Aleinu]';

const _emKaddish = '[Edot HaMizrach Kaddish Yatom]';

// Mincha template matching assets/prayers/templates/mincha.json.
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
    TemplateEntry(segmentId: 'amidah_mincha'),
    TemplateEntry(segmentId: 'tachanun', excludeFlags: ['skip_tachanun']),
    TemplateEntry(segmentId: 'aleinu'),
    TemplateEntry(segmentId: 'kaddish_yatom', allowedNusach: ['edot_mizrach']),
  ],
);

class _FakePrayerRepository implements IPrayerRepository {
  @override
  Future<PrayerTemplate> loadTemplate(String id) async => _minchaTemplate;

  @override
  Future<PrayerSegment> loadSegment(String id) async {
    return switch (id) {
      'ashrei' => const PrayerSegment(
          id: 'ashrei', defaultText: '[Ashrei — same all nusachim]'),
      'petihat_eliyahu' => const PrayerSegment(
          id: 'petihat_eliyahu', defaultText: ''),
      'kriat_hatorah_mincha' => const PrayerSegment(
          id: 'kriat_hatorah_mincha', defaultText: '[Torah reading]'),
      'amidah_mincha' => const PrayerSegment(
          id: 'amidah_mincha', defaultText: _ashkAmidah),
      'tachanun' => const PrayerSegment(
          id: 'tachanun', defaultText: _ashkTachanun),
      'aleinu' => const PrayerSegment(
          id: 'aleinu', defaultText: _ashkAleinu),
      'kaddish_yatom' => const PrayerSegment(
          id: 'kaddish_yatom', defaultText: ''),
      _ => throw Exception('Unknown segment: $id'),
    };
  }

  @override
  Future<NusachSegmentText?> loadNusachSegmentText(
    String nusach,
    String segmentId,
  ) async {
    return switch ((nusach, segmentId)) {
      // ── amidah_mincha ──
      ('ashkenaz', 'amidah_mincha') => NusachSegmentText(
          id: 'amidah_mincha', nusach: 'ashkenaz', text: _ashkAmidah),
      ('sfard', 'amidah_mincha') => NusachSegmentText(
          id: 'amidah_mincha', nusach: 'sfard', text: _sfardAmidah),
      ('edot_mizrach', 'amidah_mincha') => NusachSegmentText(
          id: 'amidah_mincha', nusach: 'edot_mizrach', text: _emAmidah),
      // ── tachanun ──
      ('ashkenaz', 'tachanun') => NusachSegmentText(
          id: 'tachanun', nusach: 'ashkenaz', text: _ashkTachanun),
      ('sfard', 'tachanun') => NusachSegmentText(
          id: 'tachanun', nusach: 'sfard', text: _sfardTachanun),
      ('edot_mizrach', 'tachanun') => NusachSegmentText(
          id: 'tachanun', nusach: 'edot_mizrach', text: _emTachanun),
      // ── aleinu ──
      ('ashkenaz', 'aleinu') => NusachSegmentText(
          id: 'aleinu', nusach: 'ashkenaz', text: _ashkAleinu),
      ('sfard', 'aleinu') => NusachSegmentText(
          id: 'aleinu', nusach: 'sfard', text: _sfardAleinu),
      ('edot_mizrach', 'aleinu') => NusachSegmentText(
          id: 'aleinu', nusach: 'edot_mizrach', text: _emAleinu),
      // ── kaddish_yatom (Edot HaMizrach only) ──
      ('edot_mizrach', 'kaddish_yatom') => NusachSegmentText(
          id: 'kaddish_yatom', nusach: 'edot_mizrach', text: _emKaddish),
      // ── ashrei is identical across nusachim; no nusach override ──
      _ => null,
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
    test('includes exactly: ashrei, amidah_mincha, tachanun, aleinu', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      expect(result.map((s) => s.id).toList(),
          ['ashrei', 'amidah_mincha', 'tachanun', 'aleinu']);
    });

    test('does NOT include petihat_eliyahu or kaddish_yatom', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final ids = result.map((s) => s.id).toSet();
      expect(ids, isNot(contains('petihat_eliyahu')));
      expect(ids, isNot(contains('kaddish_yatom')));
    });

    test('amidah_mincha resolves to Ashkenaz text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final amidah = result.firstWhere((s) => s.id == 'amidah_mincha');
      expect(amidah.resolvedText, _ashkAmidah);
    });

    test('tachanun resolves to Ashkenaz text (Psalm 6 form)', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: ashkUser);
      final tachanun = result.firstWhere((s) => s.id == 'tachanun');
      expect(tachanun.resolvedText, _ashkTachanun);
    });
  });

  // ── Sfard ─────────────────────────────────────────────────────────────────

  group('Mincha — Sfard weekday', () {
    test('includes exactly: ashrei, amidah_mincha, tachanun, aleinu', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: sfardUser);
      expect(result.map((s) => s.id).toList(),
          ['ashrei', 'amidah_mincha', 'tachanun', 'aleinu']);
    });

    test('amidah_mincha resolves to Sfard text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: sfardUser);
      final amidah = result.firstWhere((s) => s.id == 'amidah_mincha');
      expect(amidah.resolvedText, _sfardAmidah);
    });

    test('tachanun resolves to Sfard text (Vidui + 13 Middot form)', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: sfardUser);
      final tachanun = result.firstWhere((s) => s.id == 'tachanun');
      expect(tachanun.resolvedText, _sfardTachanun);
    });
  });

  // ── Edot HaMizrach ────────────────────────────────────────────────────────

  group('Mincha — Edot HaMizrach weekday', () {
    test('includes: ashrei, petihat_eliyahu, amidah_mincha, tachanun, aleinu, kaddish_yatom',
        () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      expect(result.map((s) => s.id).toList(), [
        'ashrei',
        'petihat_eliyahu',
        'amidah_mincha',
        'tachanun',
        'aleinu',
        'kaddish_yatom',
      ]);
    });

    test('amidah_mincha resolves to Edot HaMizrach text', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final amidah = result.firstWhere((s) => s.id == 'amidah_mincha');
      expect(amidah.resolvedText, _emAmidah);
    });

    test('tachanun resolves to EM text (Vidui + Psalm 25 form)', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final tachanun = result.firstWhere((s) => s.id == 'tachanun');
      expect(tachanun.resolvedText, _emTachanun);
    });

    test('kaddish_yatom resolves to EM nusach text (P2 override)', () async {
      final result = await assembler.assemble(
          templateId: 'mincha', userContext: emUser);
      final kaddish = result.firstWhere((s) => s.id == 'kaddish_yatom');
      expect(kaddish.resolvedText, _emKaddish);
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
            reason: '$nusach: tachanun must be absent when skip_tachanun is active');
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

    test('kriat_hatorah_mincha is included when monday_thursday_mincha is active',
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
