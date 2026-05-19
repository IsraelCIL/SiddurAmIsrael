import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:sefaria_importer/models/sefaria_version.dart';
import 'package:sefaria_importer/nusach_mapper.dart';
import 'package:sefaria_importer/text_processor.dart';

/// Wraps the Sefaria REST API.
///
/// Fetch strategy for a single Sefaria ref:
///   1. GET /api/versions/{ref} — discover Hebrew versions and score them.
///   2. Fetch text for the top-scoring version.
///   3. If /versions returns nothing, fall back to GET /api/texts/{ref}?lang=he.
///
/// For a full segment (which may map to N refs), the service fetches each ref
/// independently and joins the results with '\n\n'.
class SefariaService {
  SefariaService(this._client, {TextProcessor? processor})
      : _processor = processor ?? TextProcessor();

  final http.Client _client;
  final TextProcessor _processor;

  static const String _baseUrl = 'https://www.sefaria.org/api';
  static const Duration _requestDelay = Duration(milliseconds: 700);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Fetch and concatenate all Sefaria refs mapped to [segmentId] / [nusachId].
  ///
  /// Returns null if:
  ///   • the segment+nusach combination is not mapped (logs a warning), or
  ///   • the mapped list is empty (segment intentionally absent for this nusach).
  ///
  /// Returns partial text if only some refs succeed (logs a [PART] line).
  Future<String?> fetchSegment(String segmentId, String nusachId) async {
    final refs = NusachMapper.refsFor(segmentId, nusachId);

    if (refs == null) {
      stderr.writeln('[WARN] No refs mapped for $nusachId / $segmentId');
      return null;
    }
    if (refs.isEmpty) {
      return null; // intentionally absent — caller skips silently
    }

    final parts = <String>[];
    for (final ref in refs) {
      final text = await _fetchOneRef(ref, nusachId);
      if (text != null && text.isNotEmpty) {
        parts.add(text);
      } else {
        stderr.writeln('[MISS] $nusachId / $segmentId: "$ref"');
      }
    }

    if (parts.isEmpty) {
      stderr.writeln('[FAIL] $nusachId / $segmentId — all ${refs.length} ref(s) failed');
      return null;
    }

    if (parts.length < refs.length) {
      stdout.writeln('[PART] $nusachId / $segmentId (${parts.length}/${refs.length} refs)');
    } else {
      stdout.writeln('[OK]   $nusachId / $segmentId (${refs.length} ref(s))');
    }

    return parts.join('\n\n');
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Fetch the best Hebrew text for a single Sefaria [ref].
  Future<String?> _fetchOneRef(String ref, String nusachId) async {
    final versions = await _fetchVersions(ref);

    if (versions.isEmpty) {
      return _fetchDefaultHebrew(ref);
    }

    final ranked = versions
        .map((v) => (
              version: v,
              score: NusachMapper.scoreVersion(
                v.versionTitle,
                nusachId,
                sefariaPriority: v.priority,
              ),
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final best = ranked.first;
    stdout.writeln('      version: "${best.version.versionTitle}" (score ${best.score})');
    return _fetchByVersionTitle(ref, best.version.versionTitle);
  }

  /// GET /api/versions/{ref} — Hebrew version metadata only.
  Future<List<SefariaVersion>> _fetchVersions(String ref) async {
    await Future<void>.delayed(_requestDelay);

    final uri = Uri.parse('$_baseUrl/versions/${Uri.encodeComponent(ref)}');
    final response = await _safeGet(uri);
    if (response == null) return [];

    final body = jsonDecode(response.body);
    if (body is! List) return [];

    return body
        .whereType<Map<String, dynamic>>()
        .map(SefariaVersion.fromJson)
        .where((v) => v.language == 'he' && v.versionTitle.isNotEmpty)
        .toList();
  }

  /// GET /api/texts/{ref}?lang=he — Sefaria default Hebrew.
  Future<String?> _fetchDefaultHebrew(String ref) async {
    await Future<void>.delayed(_requestDelay);

    final uri = Uri.parse(
      '$_baseUrl/texts/${Uri.encodeComponent(ref)}?lang=he',
    );
    final response = await _safeGet(uri);
    if (response == null) return null;

    final json = _decodeTextResponse(response, ref);
    if (json == null) return null;

    final processed = _processor.process(json['he']);
    return processed.isEmpty ? null : processed;
  }

  /// GET /api/texts/{ref}?lang=he&versionTitle={title} — specific version.
  Future<String?> _fetchByVersionTitle(String ref, String versionTitle) async {
    await Future<void>.delayed(_requestDelay);

    final uri = Uri.parse(
      '$_baseUrl/texts/${Uri.encodeComponent(ref)}'
      '?lang=he&versionTitle=${Uri.encodeComponent(versionTitle)}',
    );
    final response = await _safeGet(uri);
    if (response == null) return null;

    final json = _decodeTextResponse(response, ref);
    if (json == null) return null;

    final processed = _processor.process(json['he']);
    if (processed.isEmpty) return _fetchDefaultHebrew(ref);
    return processed;
  }

  Future<http.Response?> _safeGet(Uri uri) async {
    try {
      final r = await _client.get(uri, headers: _headers);
      if (r.statusCode != 200) {
        stderr.writeln('[WARN] GET $uri → HTTP ${r.statusCode}');
        return null;
      }
      return r;
    } catch (e) {
      stderr.writeln('[ERROR] GET $uri → $e');
      return null;
    }
  }

  Map<String, dynamic>? _decodeTextResponse(http.Response response, String ref) {
    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      stderr.writeln('[ERROR] Invalid JSON for "$ref": $e');
      return null;
    }
    if (body is! Map<String, dynamic>) return null;
    if (body['error'] != null) {
      stderr.writeln('[WARN] Sefaria error for "$ref": ${body['error']}');
      return null;
    }
    return body;
  }

  static const Map<String, String> _headers = {
    'User-Agent': 'SmartSiddurImporter/1.0 (offline siddur app; non-commercial)',
    'Accept': 'application/json',
  };
}
