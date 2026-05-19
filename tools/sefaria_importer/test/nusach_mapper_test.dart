import 'package:sefaria_importer/nusach_mapper.dart';
import 'package:test/test.dart';

void main() {
  // ── refsFor ─────────────────────────────────────────────────────────────────

  group('NusachMapper.refsFor', () {
    test('returns 22 refs for ashkenaz amidah_mincha', () {
      final refs = NusachMapper.refsFor('amidah_mincha', 'ashkenaz');
      expect(refs, isNotNull);
      expect(refs!.length, equals(22));
      expect(refs.first,
          equals('Siddur Ashkenaz, Weekday, Minchah, Amida, Patriarchs'));
      expect(refs.last,
          equals('Siddur Ashkenaz, Weekday, Minchah, Amida, Concluding Passage'));
    });

    test('returns a single ref for sfard amidah_mincha', () {
      expect(
        NusachMapper.refsFor('amidah_mincha', 'sfard'),
        equals(['Siddur Sefard, Weekday Mincha, Amidah']),
      );
    });

    test('returns a single ref for edot_mizrach amidah_mincha', () {
      expect(
        NusachMapper.refsFor('amidah_mincha', 'edot_mizrach'),
        equals(['Siddur Edot HaMizrach, Weekday Mincha, Amida']),
      );
    });

    test('returns empty list for petihat_eliyahu in ashkenaz (intentionally absent)', () {
      expect(NusachMapper.refsFor('petihat_eliyahu', 'ashkenaz'), isEmpty);
    });

    test('returns non-null (mapped) entry for petihat_eliyahu in edot_mizrach', () {
      expect(NusachMapper.refsFor('petihat_eliyahu', 'edot_mizrach'), isNotNull);
    });

    test('returns null for an unknown nusach', () {
      expect(NusachMapper.refsFor('amidah_mincha', 'unknown_nusach'), isNull);
    });

    test('returns null for an unknown segment in a known nusach', () {
      expect(NusachMapper.refsFor('nonexistent_segment', 'ashkenaz'), isNull);
    });

    test('shabbat_mincha variant is not mapped (app is weekday-only)', () {
      for (final nusach in ['ashkenaz', 'sfard', 'edot_mizrach']) {
        expect(
          NusachMapper.refsFor('amidah_mincha:shabbat_mincha', nusach),
          isNull,
          reason: 'Shabbat/Yom Tov use of the app is forbidden; variant must be absent',
        );
      }
    });

    test('tachanun is mapped for all three nusachim', () {
      for (final nusach in ['ashkenaz', 'sfard', 'edot_mizrach']) {
        expect(
          NusachMapper.refsFor('tachanun', nusach),
          isNotNull,
          reason: '$nusach tachanun is missing',
        );
      }
    });

    test('aleinu is mapped for all three nusachim', () {
      for (final nusach in ['ashkenaz', 'sfard', 'edot_mizrach']) {
        expect(
          NusachMapper.refsFor('aleinu', nusach),
          isNotNull,
          reason: '$nusach aleinu is missing',
        );
      }
    });

    test('ashkenaz tachanun has exactly 2 refs', () {
      final refs = NusachMapper.refsFor('tachanun', 'ashkenaz');
      expect(refs, isNotNull);
      expect(refs!.length, equals(2));
    });
  });

  // ── scoreVersion ────────────────────────────────────────────────────────────

  group('NusachMapper.scoreVersion', () {
    test('scores a matching nusach + nikud version highest', () {
      final score = NusachMapper.scoreVersion('Siddur Ashkenaz', 'ashkenaz');
      // 50 (nusach) + 30 (nikud via "Siddur" keyword) = 80
      expect(score, greaterThanOrEqualTo(70));
    });

    test('scores Torat Emet for nikud bonus', () {
      final scoreWithTorat = NusachMapper.scoreVersion('Torat Emet', 'ashkenaz');
      final scoreWithout = NusachMapper.scoreVersion('Some Other Version', 'ashkenaz');
      expect(scoreWithTorat, greaterThan(scoreWithout));
    });

    test('penalises English translation versions relative to plain Hebrew', () {
      final penalisedScore =
          NusachMapper.scoreVersion('English Translation of Siddur', 'ashkenaz');
      final plainScore =
          NusachMapper.scoreVersion('Siddur Ashkenaz', 'ashkenaz');
      expect(penalisedScore, lessThan(plainScore));
    });

    test('correctly identifies Sfard version', () {
      final sfardScore = NusachMapper.scoreVersion('Siddur Sefard', 'sfard');
      final ashkenazScore = NusachMapper.scoreVersion('Siddur Sefard', 'ashkenaz');
      expect(sfardScore, greaterThan(ashkenazScore));
    });

    test('edot_mizrach matches Ben Ish Chai keyword', () {
      final score = NusachMapper.scoreVersion('Ben Ish Chai Siddur', 'edot_mizrach');
      expect(score, greaterThanOrEqualTo(50));
    });

    test('sefariaPriority adds a small bonus without dominating', () {
      final withPriority = NusachMapper.scoreVersion(
        'Generic Hebrew Version',
        'ashkenaz',
        sefariaPriority: 5,
      );
      final withoutPriority = NusachMapper.scoreVersion(
        'Generic Hebrew Version',
        'ashkenaz',
        sefariaPriority: 0,
      );
      expect(withPriority - withoutPriority, lessThanOrEqualTo(5));
    });
  });
}
