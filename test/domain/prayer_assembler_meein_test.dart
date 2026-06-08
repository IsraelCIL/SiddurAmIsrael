import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/prayer_local_datasource.dart';
import 'package:siddur_am_israel_chai/data/repositories/prayer_repository_impl.dart';
import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/user_context.dart';
import 'package:siddur_am_israel_chai/domain/services/prayer_assembler.dart';

/// AssetBundle that reads the real prayer JSON from disk (cwd = project root),
/// so these tests exercise the actual shipped Me'ein Shalosh assets through the
/// real datasource → repository → assembler pipeline.
class _DiskBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      File(key).readAsString();
}

void main() {
  late PrayerAssembler assembler;

  setUp(() {
    final ds = PrayerLocalDatasource(bundle: _DiskBundle());
    assembler = PrayerAssembler(PrayerRepositoryImpl(ds));
  });

  Future<List<AssembledSegment>> build(String nusach, List<String> flags) =>
      assembler.assemble(
        templateId: 'meein_shalosh_$nusach',
        userContext: UserContext(nusach: nusach, activeFlags: flags),
      );

  String textOf(List<AssembledSegment> segs, String id) =>
      segs.firstWhere((s) => s.id == id).resolvedText;

  group('Me\'ein Shalosh — structure', () {
    test('all three nusach templates resolve every segment', () async {
      for (final n in ['ashkenaz', 'sfard', 'edot_mizrach']) {
        final segs = await build(n, ['ms_mezonot']);
        final ids = segs.map((s) => s.id).toList();
        expect(ids, containsAll(['ms_opening', 'ms_eretz', 'ms_kiatah', 'ms_chatima']),
            reason: n);
        // every assembled prayer-text segment has non-empty text (inline-toggle
        // markers are intentionally empty — they render as a control widget).
        for (final s in segs.where((s) => !s.id.startsWith('inline_toggle_'))) {
          expect(s.resolvedText, isNotEmpty, reason: '$n/${s.id} empty');
        }
      }
    });

    test('date insertions appear only on their day', () async {
      final plain = await build('ashkenaz', ['ms_mezonot']);
      expect(plain.map((s) => s.id), isNot(contains('ms_date_rc')));

      final rc = await build('ashkenaz', ['ms_mezonot', 'rosh_chodesh']);
      expect(rc.map((s) => s.id), contains('ms_date_rc'));
      expect(textOf(rc, 'ms_date_rc'), contains('רֹאשׁ הַחֹֽדֶשׁ'));

      final pesach = await build('ashkenaz', ['ms_mezonot', 'chol_hamoed_pesach']);
      expect(textOf(pesach, 'ms_date_chm_pesach'), contains('הַמַּצּוֹת'));
    });
  });

  group('Me\'ein Shalosh — opening vav-prefix (first uses עַל, rest וְעַל)', () {
    test('mezonot alone: opening uses leading עַל', () async {
      final segs = await build('ashkenaz', ['ms_mezonot']);
      expect(textOf(segs, 'ms_opening'), contains('עַל הַמִּחְיָה וְעַל הַכַּלְכָּלָה'));
    });

    test('mezonot + gefen: gefen line gets leading וְ', () async {
      final segs = await build('ashkenaz', ['ms_mezonot', 'ms_gefen']);
      final open = textOf(segs, 'ms_opening');
      expect(open, contains('עַל הַמִּחְיָה וְעַל הַכַּלְכָּלָה'));
      expect(open, contains('וְעַל הַגֶּֽפֶן וְעַל פְּרִי הַגֶּֽפֶן'));
    });

    test('gefen alone: gefen is first, uses leading עַל', () async {
      final segs = await build('ashkenaz', ['ms_gefen']);
      final open = textOf(segs, 'ms_opening');
      expect(open, contains('עַל הַגֶּֽפֶן וְעַל פְּרִי הַגֶּֽפֶן'));
      expect(open, isNot(contains('וְעַל הַגֶּֽפֶן')));
    });
  });

  group('Me\'ein Shalosh — chatima closing colon (only on last type)', () {
    test('single type: exactly one closing colon', () async {
      final segs = await build('ashkenaz', ['ms_mezonot']);
      final chatima = textOf(segs, 'ms_chatima');
      expect(':'.allMatches(chatima).length, 1);
      expect(chatima.trimRight(), endsWith('וְעַל הַמִּחְיָה:'));
    });

    test('three types: colon only on the last (perot), order preserved', () async {
      final segs =
          await build('ashkenaz', ['ms_mezonot', 'ms_gefen', 'ms_perot']);
      final chatima = textOf(segs, 'ms_chatima');
      // exactly one colon in the whole chatima
      expect(':'.allMatches(chatima).length, 1);
      expect(chatima.trimRight(), endsWith('וְעַל הַפֵּרוֹת:'));
      // mezonot & gefen present without a colon
      expect(chatima, contains('וְעַל הַמִּחְיָה\n'));
    });
  });

  group('Me\'ein Shalosh — Eretz-Yisrael toggles', () {
    test('gefen chutz la\'aretz (default) vs Eretz Yisrael wording', () async {
      final chul = await build('ashkenaz', ['ms_gefen']);
      expect(textOf(chul, 'ms_chatima'), contains('פְּרִי הַגָּֽפֶן'));

      final ey = await build('ashkenaz', ['ms_gefen', 'ms_gefen_ey']);
      expect(textOf(ey, 'ms_chatima'), contains('פְּרִי גַפְנָהּ'));
    });

    test('perot Eretz Yisrael uses פֵּרוֹתֶיהָ', () async {
      final ey = await build('ashkenaz', ['ms_perot', 'ms_perot_ey']);
      expect(textOf(ey, 'ms_chatima'), contains('פֵּרוֹתֶֽיהָ'));
    });
  });

  group('Me\'ein Shalosh — nusach differences', () {
    test('Sfard adds וְעַל הַכַּלְכָּלָה in the chatima grain (not Ashkenaz)', () async {
      final ashk = await build('ashkenaz', ['ms_mezonot']);
      final sfard = await build('sfard', ['ms_mezonot']);
      expect(textOf(ashk, 'ms_chatima'), isNot(contains('כַּלְכָּלָה')));
      expect(textOf(sfard, 'ms_chatima'), contains('וְעַל הַכַּלְכָּלָה'));
      // near-closing (ms_kiatah) keeps plain ועל המחיה in Sfard
      expect(textOf(sfard, 'ms_kiatah'), isNot(contains('כַּלְכָּלָה')));
    });

    test('Edot HaMizrach near-closing grain has כלכלה + EY מחיתה form', () async {
      final chul = await build('edot_mizrach', ['ms_mezonot']);
      expect(textOf(chul, 'ms_kiatah'), contains('וְעַל הַמִּחְיָה וְעַל הַכַּלְכָּלָה'));

      final ey = await build('edot_mizrach', ['ms_mezonot', 'ms_mezonot_ey']);
      expect(textOf(ey, 'ms_kiatah'), contains('מִחְיָתָהּ'));
      expect(textOf(ey, 'ms_chatima'), contains('כַּלְכָּלָתָהּ'));
    });

    test('Edot HaMizrach kiatah omits the divine name (כי אתה טוב)', () async {
      final em = await build('edot_mizrach', ['ms_mezonot']);
      expect(textOf(em, 'ms_kiatah'), startsWith('כִּי אַתָּה טוֹב'));
      final ashk = await build('ashkenaz', ['ms_mezonot']);
      expect(textOf(ashk, 'ms_kiatah'), startsWith('כִּי אַתָּה יְהֹוָה'));
    });
  });

  group('Tefilat HaDerech', () {
    Future<List<AssembledSegment>> thd(String nusach) => assembler.assemble(
          templateId: 'tefilat_haderech_$nusach',
          userContext: UserContext(nusach: nusach),
        );

    test('all nusachim resolve main blessing + additions accordion', () async {
      for (final n in ['ashkenaz', 'sfard', 'edot_mizrach']) {
        final segs = await thd(n);
        final ids = segs.map((s) => s.id).toList();
        expect(ids, contains('thd_main'), reason: n);
        // additions are optional (accordion) and present in the assembled list
        expect(ids.any((i) => i.startsWith('thd_additions')), isTrue, reason: n);
        expect(textOf(segs, 'thd_main'), startsWith('יְהִי רָצוֹן'), reason: n);
      }
    });

    test('additions marked optional (accordion)', () async {
      final segs = await thd('ashkenaz');
      final add = segs.firstWhere((s) => s.id == 'thd_additions');
      expect(add.optional, isTrue);
    });

    test('A/S additions: one bold opener per repeated verse run (12 runs)', () async {
      // Repeated verses each get exactly one <b>…</b> on their first occurrence;
      // single verses (כי מלאכיו / אתה סתר / שיר למעלות / מגדל עז) are not bolded.
      final segs = await thd('ashkenaz');
      final add = textOf(segs, 'thd_additions');
      expect('<b>'.allMatches(add).length, 12);
      // long runs are split into groups of 5 (blank line between groups)
      expect(add, contains('\n\n'));
    });

    test('EM additions: 5 verse runs, each bolded once', () async {
      final segs = await thd('edot_mizrach');
      final add = textOf(segs, 'thd_additions_em');
      expect('<b>'.allMatches(add).length, 5);
    });

    test('EM main parenthesises both the return phrase and the chatima name', () async {
      // (ותחזירנו לשלום) + (אתה יהוה) → two parenthesised inserts.
      final segs = await thd('edot_mizrach');
      expect('('.allMatches(textOf(segs, 'thd_main')).length, 2);
    });

    test('A/S main has only the return-phrase parenthesis', () async {
      final segs = await thd('ashkenaz');
      expect('('.allMatches(textOf(segs, 'thd_main')).length, 1);
    });
  });
}
