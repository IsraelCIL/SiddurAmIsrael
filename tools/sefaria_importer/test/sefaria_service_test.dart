import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:sefaria_importer/sefaria_service.dart';
import 'package:sefaria_importer/text_processor.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Fake HTTP clients
// ---------------------------------------------------------------------------

/// Routes GET requests by URL substring to pre-configured JSON responses.
class FakeHttpClient implements http.Client {
  final Map<String, String> _routes = {};
  int _defaultStatus = 200;

  void addRoute(String urlFragment, String jsonBody) =>
      _routes[urlFragment] = jsonBody;

  void setDefaultStatus(int status) => _defaultStatus = status;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final urlStr = url.toString();
    for (final entry in _routes.entries) {
      if (urlStr.contains(entry.key)) return _utf8Response(entry.value, 200);
    }
    return http.Response('', _defaultStatus);
  }

  @override
  void close() {}

  // Satisfy the interface; tests only use GET.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns pre-configured responses in declaration order (one per call).
class SequentialFakeClient implements http.Client {
  SequentialFakeClient(this._responses);

  final List<(String body, int status)> _responses;
  int _index = 0;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    if (_index >= _responses.length) return http.Response('', 404);
    final (body, status) = _responses[_index++];
    return _utf8Response(body, status);
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

http.Response _utf8Response(String body, int status) {
  return http.Response.bytes(
    Uint8List.fromList(utf8.encode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeHttpClient fakeClient;
  late SefariaService service;

  setUp(() {
    fakeClient = FakeHttpClient();
    service = SefariaService(fakeClient, processor: TextProcessor());
  });

  group('SefariaService.fetchSegment', () {
    // aleinu/ashkenaz maps to exactly 1 ref — keeps test fast and predictable.

    test('selects the best version and returns processed text', () async {
      final versionsJson = jsonEncode([
        {'versionTitle': 'Siddur Ashkenaz', 'language': 'he', 'versionSource': '', 'priority': 1},
        {'versionTitle': 'Generic Version', 'language': 'he', 'versionSource': '', 'priority': 0},
      ]);
      const hebrewText = 'אֲדֹנָי שְׂפָתַי תִּפְתָּח';
      final textJson = jsonEncode({'ref': 'ref', 'he': hebrewText});

      fakeClient
        ..addRoute('/versions/', versionsJson)
        ..addRoute('/texts/', textJson);

      final result = await service.fetchSegment('aleinu', 'ashkenaz');
      expect(result, equals(hebrewText));
    });

    test('falls back to default Hebrew when /versions returns empty list', () async {
      const hebrewText = 'אַשְׁרֵי יוֹשְׁבֵי בֵיתֶךָ';
      final textJson = jsonEncode({'ref': 'ref', 'he': hebrewText});

      fakeClient
        ..addRoute('/versions/', '[]')
        ..addRoute('/texts/', textJson);

      final result = await service.fetchSegment('ashrei', 'ashkenaz');
      expect(result, equals(hebrewText));
    });

    test('returns null when the single ref fails with non-200 status', () async {
      fakeClient.setDefaultStatus(404);
      final result = await service.fetchSegment('aleinu', 'ashkenaz');
      expect(result, isNull);
    });

    test('returns null for an unknown nusach', () async {
      final result = await service.fetchSegment('amidah_mincha', 'unknown_nusach');
      expect(result, isNull);
    });

    test('strips HTML tags from returned text', () async {
      final textJson = jsonEncode({
        'ref': 'ref',
        'he': '<b>אֲדֹנָי</b> <span>שְׂפָתַי</span>',
      });

      fakeClient
        ..addRoute('/versions/', '[]')
        ..addRoute('/texts/', textJson);

      final result = await service.fetchSegment('aleinu', 'ashkenaz');
      expect(result, equals('אֲדֹנָי שְׂפָתַי'));
    });

    test('handles Sefaria error JSON gracefully and returns null', () async {
      final errorJson = jsonEncode({'error': 'Text not found'});

      fakeClient
        ..addRoute('/versions/', '[]')
        ..addRoute('/texts/', errorJson);

      final result = await service.fetchSegment('aleinu', 'ashkenaz');
      expect(result, isNull);
    });

    test('flattens list-valued he field into newline-joined string', () async {
      final textJson = jsonEncode({
        'ref': 'ref',
        'he': ['בָּרוּךְ אַתָּה', 'יְהוָה אֱלֹהֵינוּ'],
      });

      fakeClient
        ..addRoute('/versions/', '[]')
        ..addRoute('/texts/', textJson);

      final result = await service.fetchSegment('aleinu', 'ashkenaz');
      expect(result, equals('בָּרוּךְ אַתָּה\nיְהוָה אֱלֹהֵינוּ'));
    });

    test('concatenates multiple refs with double newline separator', () async {
      // tachanun/ashkenaz maps to exactly 2 refs (Nefilat Appayim + Shomer Yisrael).
      // Each ref triggers: /versions → empty, /texts → text.
      const text1 = 'וְהוּא רַחוּם יְכַפֵּר עָוֹן';
      const text2 = 'שׁוֹמֵר יִשְׂרָאֵל';

      final seqClient = SequentialFakeClient([
        ('[]', 200),                                          // ref1 /versions → empty
        (jsonEncode({'ref': 'r1', 'he': text1}), 200),       // ref1 /texts
        ('[]', 200),                                          // ref2 /versions → empty
        (jsonEncode({'ref': 'r2', 'he': text2}), 200),       // ref2 /texts
      ]);
      final seqService = SefariaService(seqClient, processor: TextProcessor());

      final result = await seqService.fetchSegment('tachanun', 'ashkenaz');
      expect(result, equals('$text1\n\n$text2'));
    });

    test('returns partial text and logs when only some refs succeed', () async {
      // tachanun/ashkenaz: ref1 succeeds, ref2 fails → partial result returned.
      const text1 = 'וְהוּא רַחוּם';

      final seqClient = SequentialFakeClient([
        ('[]', 200),                                          // ref1 /versions → empty
        (jsonEncode({'ref': 'r1', 'he': text1}), 200),       // ref1 /texts → ok
        ('[]', 200),                                          // ref2 /versions → empty
        (jsonEncode({'error': 'not found'}), 200),            // ref2 /texts → error
      ]);
      final seqService = SefariaService(seqClient, processor: TextProcessor());

      final result = await seqService.fetchSegment('tachanun', 'ashkenaz');
      expect(result, equals(text1));
    });
  });
}
