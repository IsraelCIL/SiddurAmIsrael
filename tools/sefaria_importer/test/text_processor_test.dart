import 'package:sefaria_importer/text_processor.dart';
import 'package:test/test.dart';

void main() {
  late TextProcessor processor;

  setUp(() => processor = TextProcessor());

  // ── flattenText ─────────────────────────────────────────────────────────────

  group('flattenText', () {
    test('passes through a plain string unchanged', () {
      expect(processor.flattenText('שלום'), 'שלום');
    });

    test('joins a List<String> with newlines', () {
      expect(processor.flattenText(['א', 'ב', 'ג']), 'א\nב\nג');
    });

    test('flattens nested List<List<String>>', () {
      expect(
        processor.flattenText([
          ['פסוק א', 'פסוק ב'],
          ['פסוק ג'],
        ]),
        'פסוק א\nפסוק ב\nפסוק ג',
      );
    });

    test('returns empty string for null', () {
      expect(processor.flattenText(null), '');
    });

    test('filters out empty strings in a list', () {
      expect(processor.flattenText(['א', '', 'ב']), 'א\nב');
    });
  });

  // ── stripHtml ───────────────────────────────────────────────────────────────

  group('stripHtml', () {
    test('removes bold tags', () {
      expect(processor.stripHtml('<b>בָּרוּךְ</b>'), 'בָּרוּךְ');
    });

    test('removes span with class', () {
      expect(
        processor.stripHtml('<span class="he">אֲדֹנָי</span>'),
        'אֲדֹנָי',
      );
    });

    test('decodes &amp;', () {
      expect(processor.stripHtml('a &amp; b'), 'a & b');
    });

    test('decodes &nbsp; to space', () {
      expect(processor.stripHtml('a&nbsp;b'), 'a b');
    });

    test('handles text with no HTML', () {
      const plain = 'בָּרוּךְ אַתָּה יְהוָה';
      expect(processor.stripHtml(plain), plain);
    });
  });

  // ── hasNikud ────────────────────────────────────────────────────────────────

  group('hasNikud', () {
    test('returns true for text with nikud', () {
      expect(processor.hasNikud('אֲדֹנָי שְׂפָתַי'), isTrue);
    });

    test('returns false for unvowelized Hebrew', () {
      expect(processor.hasNikud('אדוני שפתי'), isFalse);
    });

    test('returns false for empty string', () {
      expect(processor.hasNikud(''), isFalse);
    });
  });

  // ── normalize ───────────────────────────────────────────────────────────────

  group('normalize', () {
    test('collapses multiple spaces', () {
      expect(processor.normalize('א  ב   ג'), 'א ב ג');
    });

    test('trims leading and trailing whitespace', () {
      expect(processor.normalize('  שלום  '), 'שלום');
    });

    test('normalises CRLF to LF', () {
      expect(processor.normalize('א\r\nב'), 'א\nב');
    });

    test('collapses 3+ blank lines to 2 newlines', () {
      expect(processor.normalize('א\n\n\n\nב'), 'א\n\nב');
    });
  });

  // ── applyGenderTags ─────────────────────────────────────────────────────────

  group('applyGenderTags', () {
    test('always returns tagged=false when no rules are defined', () {
      // No Orthodox halachic gender variants are currently wired up.
      // tagged must be false and the text must pass through unchanged.
      const input = 'אֲדֹנָי שְׂפָתַי תִּפְתָּח';
      final (:text, :tagged) =
          processor.applyGenderTags(input, 'amidah_mincha');

      expect(tagged, isFalse);
      expect(text, equals(input));
    });

    test('text is never modified when no rules are defined', () {
      const input = 'ברוך אתה ה׳ שומע תפילה';
      final (:text, :tagged) =
          processor.applyGenderTags(input, 'ashrei');

      expect(tagged, isFalse);
      expect(text, equals(input));
    });
  });

  // ── process (full pipeline) ─────────────────────────────────────────────────

  group('process', () {
    test('flattens list, strips HTML, and normalizes', () {
      final result = processor.process([
        '<b>בָּרוּךְ</b>  אַתָּה',
        'יְהוָה',
      ]);
      expect(result, 'בָּרוּךְ אַתָּה\nיְהוָה');
    });

    test('returns empty string for null input', () {
      expect(processor.process(null), '');
    });
  });
}
