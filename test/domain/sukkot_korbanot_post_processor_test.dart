import 'package:flutter_test/flutter_test.dart';
import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/sukkot_korban.dart';
import 'package:siddur_am_israel_chai/domain/services/sukkot_korbanot_post_processor.dart';

void main() {
  const proc = SukkotKorbanotPostProcessor();

  AssembledSegment seg(String id, String text) =>
      AssembledSegment(id: id, resolvedText: text);

  SukkotKorban day(int d) => SukkotKorban(
        day: d,
        pasukIsrael: 'ISRAEL_KORBAN_$d',
        pasukChul: 'CHUL_KORBAN_$d',
      );

  test('fills {{daily_korban}} with Israel pasuk when isInIsrael=true', () {
    final s = seg('amidah_musaf_intermediate_chm_sukkot',
        'Na\'aseh v\'nakriv: {{daily_korban}} — Uminchatam');
    final out = proc.process(s, day(3), isInIsrael: true).resolvedText;
    expect(out, contains('ISRAEL_KORBAN_3'));
    expect(out, isNot(contains('{{daily_korban}}')));
  });

  test('fills {{daily_korban}} with chu"l pasuk when isInIsrael=false', () {
    final s = seg('amidah_musaf_intermediate_chm_sukkot',
        'Na\'aseh v\'nakriv: {{daily_korban}}');
    final out = proc.process(s, day(5), isInIsrael: false).resolvedText;
    expect(out, contains('CHUL_KORBAN_5'));
  });

  test('leaves unrelated segments untouched', () {
    final s = seg('aleinu', 'Aleinu {{daily_korban}}');
    final out = proc.process(s, day(2), isInIsrael: true).resolvedText;
    expect(out, contains('{{daily_korban}}')); // unchanged
  });
}
