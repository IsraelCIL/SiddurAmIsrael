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

    // ── loadSegment ───────────────────────────────────────────────────────────

    test('loadSegment returns PrayerSegment from asset JSON', () async {
      const ashreiText = 'אַשְׁרֵי יוֹשְׁבֵי בֵיתֶֽךָ';
      final ds = PrayerLocalDatasource(
        bundle: _FakeBundle({
          'assets/prayers/segments/ashrei.json': jsonEncode(<String, dynamic>{
            'id': 'ashrei',
            'default_text': ashreiText,
            'variants': <String, String>{},
            'condition_flags': <String>[],
            'exclude_flags': <String>[],
            'optional': false,
          }),
        }),
      );

      final segment = await ds.loadSegment('ashrei');
      expect(segment.id, 'ashrei');
      expect(segment.defaultText, ashreiText);
      expect(segment.variants, isEmpty);
    });

    // ── loadNusachSegmentText ─────────────────────────────────────────────────

    test('loadNusachSegmentText returns NusachSegmentText for a known file',
        () async {
      const text = 'עָלֵינוּ לְשַׁבֵּֽחַ לַאֲדוֹן הַכֹּל';
      final ds = PrayerLocalDatasource(
        bundle: _FakeBundle({
          'assets/prayers/nusach/ashkenaz/aleinu.json':
              jsonEncode(<String, dynamic>{
            'id': 'aleinu',
            'nusach': 'ashkenaz',
            'text': text,
            'variants': <String, String>{},
            'has_nikud': true,
            'gender_tagged': false,
            'sources': <String>[
              'Siddur Ashkenaz, Weekday, Minchah, Concluding Prayers, Alenu',
            ],
          }),
        }),
      );

      final result = await ds.loadNusachSegmentText('ashkenaz', 'aleinu');
      expect(result, isNotNull);
      expect(result!.id, 'aleinu');
      expect(result.nusach, 'ashkenaz');
      expect(result.text, text);
      expect(result.hasNikud, isTrue);
      expect(result.genderTagged, isFalse);
      expect(result.sources, hasLength(1));
    });

    test('loadNusachSegmentText returns null when the file does not exist',
        () async {
      final ds = PrayerLocalDatasource(bundle: _FakeBundle({}));
      final result = await ds.loadNusachSegmentText('ashkenaz', 'nonexistent');
      expect(result, isNull);
    });

    test('loadNusachSegmentText returns null for a nusach with no override file',
        () async {
      final ds = PrayerLocalDatasource(
        bundle: _FakeBundle({
          'assets/prayers/nusach/ashkenaz/aleinu.json':
              jsonEncode(<String, dynamic>{
            'id': 'aleinu',
            'nusach': 'ashkenaz',
            'text': 'text',
            'variants': <String, String>{},
            'has_nikud': false,
            'gender_tagged': false,
            'sources': <String>[],
          }),
        }),
      );

      // sfard file is absent — should return null gracefully
      final result = await ds.loadNusachSegmentText('sfard', 'aleinu');
      expect(result, isNull);
    });
  });
}
