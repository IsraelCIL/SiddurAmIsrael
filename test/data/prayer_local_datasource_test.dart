import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_siddur/data/datasources/local/prayer_local_datasource.dart';

class _FakeBundle extends AssetBundle {
  _FakeBundle(this._files);
  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    final str = _files[key];
    if (str == null) throw Exception('Asset not found: $key');
    final bytes = const Utf8Codec().encode(str);
    return ByteData.sublistView(bytes);
  }
}

void main() {
  group('PrayerLocalDatasource', () {
    // ── loadTemplate ──────────────────────────────────────────────────────────

    test('loadTemplate returns PrayerTemplate from asset JSON', () async {
      final ds = PrayerLocalDatasource(
        bundle: _FakeBundle({
          'assets/prayers/templates/mincha.json': jsonEncode(<String, dynamic>{
            'id': 'mincha',
            'name': 'מנחה',
            'segments': <dynamic>[
              <String, dynamic>{
                'segment_id': 'ashrei',
                'condition_flags': <String>[],
                'exclude_flags': <String>[],
                'optional': false,
                'allowed_nusach': <String>[],
              },
            ],
          }),
        }),
      );

      final template = await ds.loadTemplate('mincha');
      expect(template.id, 'mincha');
      expect(template.name, 'מנחה');
      expect(template.segments.single.segmentId, 'ashrei');
    });

    // ── loadNusachSegment ─────────────────────────────────────────────────────

    test('loadNusachSegment returns PrayerSegment from nusach folder', () async {
      const sectionText = 'עָלֵינוּ לְשַׁבֵּֽחַ לַאֲדוֹן הַכֹּל';
      final ds = PrayerLocalDatasource(
        bundle: _FakeBundle({
          'assets/prayers/nusach/ashkenaz/aleinu.json':
              jsonEncode(<String, dynamic>{
            'id': 'aleinu',
            'sections': <dynamic>[
              <String, dynamic>{
                'text': sectionText,
                'condition_flags': <String>[],
                'exclude_flags': <String>[],
              },
            ],
          }),
        }),
      );

      final segment = await ds.loadNusachSegment('ashkenaz', 'aleinu');
      expect(segment.id, 'aleinu');
      expect(segment.sections.single.text, sectionText);
    });

    // ── text normalization (List<String> → space-joined String) ───────────────

    test('loadNusachSegment joins List text inside sections with a single space',
        () async {
      final ds = PrayerLocalDatasource(
        bundle: _FakeBundle({
          'assets/prayers/nusach/ashkenaz/avot.json':
              jsonEncode(<String, dynamic>{
            'id': 'avot',
            'sections': <dynamic>[
              <String, dynamic>{
                'text': <String>['חֵלֶק רִאשׁוֹן', 'חֵלֶק שֵׁנִי'],
                'condition_flags': <String>[],
                'exclude_flags': <String>[],
              },
            ],
          }),
        }),
      );

      final segment = await ds.loadNusachSegment('ashkenaz', 'avot');
      expect(segment.sections.single.text, 'חֵלֶק רִאשׁוֹן חֵלֶק שֵׁנִי');
    });

    test('loadNusachSegment leaves a plain String text field unchanged',
        () async {
      const plain = 'בָּרוּךְ אַתָּה יְהֹוָה';
      final ds = PrayerLocalDatasource(
        bundle: _FakeBundle({
          'assets/prayers/nusach/ashkenaz/avot.json':
              jsonEncode(<String, dynamic>{
            'id': 'avot',
            'sections': <dynamic>[
              <String, dynamic>{
                'text': plain,
                'condition_flags': <String>[],
                'exclude_flags': <String>[],
              },
            ],
          }),
        }),
      );

      final segment = await ds.loadNusachSegment('ashkenaz', 'avot');
      expect(segment.sections.single.text, plain);
    });

    test('loadNusachSegment throws when the nusach file does not exist',
        () async {
      final ds = PrayerLocalDatasource(bundle: _FakeBundle({}));
      expect(
        () => ds.loadNusachSegment('ashkenaz', 'nonexistent'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
