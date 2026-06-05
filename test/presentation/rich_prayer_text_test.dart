import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/rich_prayer_text.dart';

void main() {
  const base = TextStyle(fontSize: 20);

  test('empty input returns empty list', () {
    expect(parseBoldSpans(''), isEmpty);
  });

  test('no tags → single span with base style', () {
    final spans = parseBoldSpans('שלום עולם', baseStyle: base);
    expect(spans, hasLength(1));
    expect(spans[0].text, 'שלום עולם');
    expect(spans[0].style, base);
  });

  test('single <b>...</b> emits 3 spans (pre / bold / post)', () {
    final spans = parseBoldSpans('היום <b>אנא</b> בכח', baseStyle: base);
    expect(spans, hasLength(3));
    expect(spans[0].text, 'היום ');
    expect(spans[0].style!.fontWeight, isNot(FontWeight.bold));
    expect(spans[1].text, 'אנא');
    expect(spans[1].style!.fontWeight, FontWeight.bold);
    expect(spans[2].text, ' בכח');
    expect(spans[2].style!.fontWeight, isNot(FontWeight.bold));
  });

  test('bold span inherits base style fontSize', () {
    final spans = parseBoldSpans('<b>אלהים</b>', baseStyle: base);
    expect(spans, hasLength(1));
    expect(spans[0].style!.fontSize, 20);
    expect(spans[0].style!.fontWeight, FontWeight.bold);
  });

  test('multiple <b>...</b> tags are each bolded', () {
    final spans = parseBoldSpans('<b>א</b>בג<b>ד</b>הו', baseStyle: base);
    expect(spans, hasLength(4));
    expect(spans[0].text, 'א'); expect(spans[0].style!.fontWeight, FontWeight.bold);
    expect(spans[1].text, 'בג');
    expect(spans[2].text, 'ד'); expect(spans[2].style!.fontWeight, FontWeight.bold);
    expect(spans[3].text, 'הו');
  });

  test('bold-only text (no surrounding text) emits single bold span', () {
    final spans = parseBoldSpans('<b>קדוש</b>', baseStyle: base);
    expect(spans, hasLength(1));
    expect(spans[0].text, 'קדוש');
    expect(spans[0].style!.fontWeight, FontWeight.bold);
  });

  test('Hebrew with niqqud inside <b>...</b> is preserved', () {
    final spans = parseBoldSpans('<b>אֱלֹהִים</b> יְחָנֵּנוּ', baseStyle: base);
    expect(spans[0].text, 'אֱלֹהִים');
    expect(spans[0].style!.fontWeight, FontWeight.bold);
    expect(spans[1].text, ' יְחָנֵּנוּ');
  });

  test('parenthetical "(...)" inside <b> stays atomic', () {
    final spans = parseBoldSpans('סוף: <b>(אב"ג ית"ץ)</b>', baseStyle: base);
    expect(spans, hasLength(2));
    expect(spans[1].text, '(אב"ג ית"ץ)');
    expect(spans[1].style!.fontWeight, FontWeight.bold);
  });
}
