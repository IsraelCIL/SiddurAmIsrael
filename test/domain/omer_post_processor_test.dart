import 'package:flutter_test/flutter_test.dart';
import 'package:smart_siddur/domain/entities/assembled_segment.dart';
import 'package:smart_siddur/domain/entities/omer_day.dart';
import 'package:smart_siddur/domain/services/omer_post_processor.dart';

OmerDay _day({
  required int day,
  required int week,
  required int dayInWeek,
  String textA = 'הַיּוֹם בָּעֹמֶר:',
  String textS = 'הַיּוֹם לָעֹמֶר:',
  String textE = 'הַיּוֹם לָעֹמֶר:',
  required String sefira,
  required String ana,
  required String lamenatz,
  required String yism,
}) =>
    OmerDay(
      day: day,
      week: week,
      dayInWeek: dayInWeek,
      textAshkenaz: textA,
      textSfard: textS,
      textEdotMizrach: textE,
      sefira: sefira,
      anaWord: ana,
      lamenatzeachWord: lamenatz,
      yismechuLetter: yism,
    );

AssembledSegment _seg(String id, String text) =>
    AssembledSegment(id: id, resolvedText: text);

void main() {
  const proc = OmerPostProcessor();

  group('day_count placeholder', () {
    test('replaces {{omer_day_count}} with nusach-specific text', () {
      final day = _day(
        day: 1, week: 1, dayInWeek: 1,
        textA: 'הַיּוֹם יוֹם אֶחָד בָּעֹמֶר:',
        textS: 'הַיּוֹם יוֹם אֶחָד לָעֹמֶר:',
        textE: 'הַיּוֹם יוֹם אֶחָד לָעֹמֶר:',
        sefira: 'חֶסֶד שֶׁבְּחֶסֶד',
        ana: 'אנא', lamenatz: 'אלהים', yism: 'י',
      );
      final seg = _seg('sefirat_haomer_day_count', '{{omer_day_count}}');
      expect(proc.process(seg, day, 'ashkenaz').resolvedText,
          'הַיּוֹם יוֹם אֶחָד בָּעֹמֶר:');
      expect(proc.process(seg, day, 'sfard').resolvedText,
          'הַיּוֹם יוֹם אֶחָד לָעֹמֶר:');
      expect(proc.process(seg, day, 'edot_mizrach').resolvedText,
          'הַיּוֹם יוֹם אֶחָד לָעֹמֶר:');
    });
  });

  group('ribono_shel_olam sefira placeholder', () {
    test('substitutes {{omer_sefira}} with the day sefira', () {
      final day = _day(
        day: 8, week: 2, dayInWeek: 1,
        sefira: 'חֶסֶד שֶׁבִּגְבוּרָה',
        ana: 'קבל', lamenatz: 'לדעת', yism: 'ר',
      );
      final seg = _seg('sefirat_haomer_ribono_shel_olam',
          'יתוקן מה שפגמתי בספירה {{omer_sefira}} ואטהר');
      expect(proc.process(seg, day, 'ashkenaz').resolvedText,
          'יתוקן מה שפגמתי בספירה חֶסֶד שֶׁבִּגְבוּרָה ואטהר');
    });
  });

  group('lamenatzeach bold injection', () {
    // Use a simplified Psalm 67 (heading + verse 2 + verse 5) for testing.
    const psalm = 'לַמְנַצֵּחַ בִּנְגִינוֹת מִזְמוֹר שִׁיר: '
        'אֱלֹהִים יְחָנֵּנוּ וִיבָרְכֵנוּ יָאֵר פָּנָיו אִתָּנוּ סֶלָה: '
        'יִשְׂמְחוּ וִירַנְּנוּ לְאֻמִּים כִּי תִשְׁפֹּט עַמִּים מִישׁוֹר וּלְאֻמִּים בָּאָרֶץ תַּנְחֵם סֶלָה:';

    test('day 1 bolds word "אֱלֹהִים" (1st after heading)', () {
      final day = _day(
        day: 1, week: 1, dayInWeek: 1,
        sefira: 'חֶסֶד שֶׁבְּחֶסֶד',
        ana: 'אנא', lamenatz: 'אלהים', yism: 'י',
      );
      final seg = _seg('sefirat_haomer_lamenatzeach', psalm);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      expect(out, contains('<b>אֱלֹהִים</b>'));
    });

    test('day 5 bolds word "פָּנָיו" (5th after heading)', () {
      final day = _day(
        day: 5, week: 1, dayInWeek: 5,
        sefira: 'הוֹד שֶׁבְּחֶסֶד',
        ana: 'תתיר', lamenatz: 'פניו', yism: 'ו',
      );
      final seg = _seg('sefirat_haomer_lamenatzeach', psalm);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      expect(out, contains('<b>פָּנָיו</b>'));
    });

    test('day 1 also bolds the 1st letter (י) of the yismechu verse', () {
      final day = _day(
        day: 1, week: 1, dayInWeek: 1,
        sefira: 'חֶסֶד שֶׁבְּחֶסֶד',
        ana: 'אנא', lamenatz: 'אלהים', yism: 'י',
      );
      final seg = _seg('sefirat_haomer_lamenatzeach', psalm);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      // The yismechu verse "יִשְׂמְחוּ..." should have <b> wrapping the leading
      // י-letter together with any combining marks attached to it.
      expect(out, contains(RegExp(r'<b>יִ?[֑-ֽ]*</b>שְׂמְחוּ')));
    });

    test('day 3 bolds letter "מ" (3rd consonant of "ישמחו")', () {
      final day = _day(
        day: 3, week: 1, dayInWeek: 3,
        sefira: 'תִּפְאֶרֶת שֶׁבְּחֶסֶד',
        ana: 'גדולת', lamenatz: 'ויברכנו', yism: 'מ',
      );
      final seg = _seg('sefirat_haomer_lamenatzeach', psalm);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      // After processing, the מ inside יִשְׂמְחוּ should be bolded
      // (the third consonant of the verse, counting from i=1).
      expect(out, contains('<b>וִיבָרְכֵנוּ</b>'));
      expect(out, contains(RegExp(r'יִ[֑-ֽ]*שְׂ?<b>מְ?')));
    });
  });

  group('ana_bekoach bold injection', () {
    // 7 lines + Baruch Shem, joined with \n.
    const ana = 'אָנָּא בְּכֹחַ גְּדֻלַּת יְמִינְךָ תַּתִּיר צְרוּרָה: (אב"ג ית"ץ)\n'
        'קַבֵּל רִנַּת עַמְּךָ שַׂגְּבֵנוּ טַהֲרֵנוּ נוֹרָא: (קר"ע שט"ן)\n'
        'נָא גִבּוֹר דּוֹרְשֵׁי יִחוּדְךָ כְּבָבַת שָׁמְרֵם: (נג"ד יכ"ש)\n'
        'בָּרְכֵם טַהֲרֵם רַחֲמֵם צִדְקָתְךָ תָּמִיד גָּמְלֵם: (בט"ר צת"ג)\n'
        'חֲסִין קָדוֹשׁ בְּרֹב טוּבְךָ נַהֵל עֲדָתֶךָ: (חק"ב טנ"ע)\n'
        'יָחִיד גֵּאֶה לְעַמְּךָ פְּנֵה זוֹכְרֵי קְדֻשָּׁתֶךָ: (יג"ל פז"ק)\n'
        'שַׁוְעָתֵנוּ קַבֵּל וּשְׁמַע צַעֲקָתֵנוּ יוֹדֵעַ תַּעֲלוּמוֹת: (שק"ו צי"ת)\n'
        '(בלחש) בָּרוּךְ שֵׁם כְּבוֹד מַלְכוּתוֹ לְעוֹלָם וָעֶד:';

    test('day 1 (week 1, dow 1) bolds "אָנָּא" — word 1 of line 1', () {
      final day = _day(
        day: 1, week: 1, dayInWeek: 1,
        sefira: 'חֶסֶד שֶׁבְּחֶסֶד',
        ana: 'אנא', lamenatz: 'אלהים', yism: 'י',
      );
      final seg = _seg('sefirat_haomer_ana_bekoach', ana);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      expect(out, contains('<b>אָנָּא</b>'));
      // Make sure no other line was affected.
      expect(out.split('\n')[1], isNot(contains('<b>')));
    });

    test('day 2 (week 1, dow 2) bolds "בְּכֹחַ" — word 2 of line 1', () {
      final day = _day(
        day: 2, week: 1, dayInWeek: 2,
        sefira: 'גְּבוּרָה שֶׁבְּחֶסֶד',
        ana: 'בכח', lamenatz: 'יחננו', yism: 'ש',
      );
      final seg = _seg('sefirat_haomer_ana_bekoach', ana);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      expect(out, contains('<b>בְּכֹחַ</b>'));
    });

    test('day 7 (end of week 1) bolds the acronym "(אב"ג ית"ץ)" of line 1', () {
      final day = _day(
        day: 7, week: 1, dayInWeek: 7,
        sefira: 'מַלְכוּת שֶׁבְּחֶסֶד',
        ana: 'אב"ג ית"ץ', lamenatz: 'סלה', yism: 'י',
      );
      final seg = _seg('sefirat_haomer_ana_bekoach', ana);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      expect(out.split('\n')[0], contains('<b>(אב"ג ית"ץ)</b>'));
    });

    test('day 8 (week 2, dow 1) bolds "קַבֵּל" — word 1 of line 2', () {
      final day = _day(
        day: 8, week: 2, dayInWeek: 1,
        sefira: 'חֶסֶד שֶׁבִּגְבוּרָה',
        ana: 'קבל', lamenatz: 'לדעת', yism: 'ר',
      );
      final seg = _seg('sefirat_haomer_ana_bekoach', ana);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      // Line 2 (index 1) should have its first word bolded.
      final lines = out.split('\n');
      expect(lines[1], contains('<b>קַבֵּל</b>'));
      // Line 1 should be untouched.
      expect(lines[0], isNot(contains('<b>')));
    });

    test('day 49 (end of week 7) bolds the acronym of line 7', () {
      final day = _day(
        day: 49, week: 7, dayInWeek: 7,
        sefira: 'מַלְכוּת שֶׁבְּמַלְכוּת',
        ana: 'שק"ו צי"ת', lamenatz: 'ארץ', yism: 'ה',
      );
      final seg = _seg('sefirat_haomer_ana_bekoach', ana);
      final out = proc.process(seg, day, 'ashkenaz').resolvedText;
      final lines = out.split('\n');
      expect(lines[6], contains('<b>(שק"ו צי"ת)</b>'));
      // Baruch Shem (line 7 index) must be untouched.
      expect(lines[7], isNot(contains('<b>')));
    });
  });

  group('pass-through', () {
    test('leaves unrelated segments untouched', () {
      final day = _day(
        day: 1, week: 1, dayInWeek: 1,
        sefira: 'חֶסֶד שֶׁבְּחֶסֶד',
        ana: 'אנא', lamenatz: 'אלהים', yism: 'י',
      );
      final seg = _seg('aleinu', 'עָלֵינוּ לְשַׁבֵּחַ');
      expect(proc.process(seg, day, 'ashkenaz').resolvedText,
          'עָלֵינוּ לְשַׁבֵּחַ');
    });
  });
}
