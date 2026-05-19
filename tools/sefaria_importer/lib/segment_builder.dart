import 'dart:convert';
import 'dart:io';

import 'package:sefaria_importer/nusach_mapper.dart';
import 'package:sefaria_importer/sefaria_service.dart';
import 'package:sefaria_importer/text_processor.dart';

// ---------------------------------------------------------------------------
// Segment catalogue
// ---------------------------------------------------------------------------

/// Segments whose text is identical across all nusachim — fetch once from
/// Ashkenaz and write to assets/prayers/segments/{id}.json only.
const _universalSegments = ['ashrei'];

/// Segments where each nusach has its own wording.  Ashkenaz text becomes the
/// canonical `default_text`; every nusach gets its own per-segment override
/// file at assets/prayers/nusach/{nusach_id}/{segment_id}.json.
const _nusachVariantSegments = ['amidah_mincha', 'tachanun', 'aleinu'];

/// Segments that only apply to specific nusachim.
/// Key: segment_id.  Value: list of nusach IDs that should receive the file.
const _restrictedSegments = <String, List<String>>{
  'petihat_eliyahu': ['edot_mizrach'],
  'lamenatzeach': ['edot_mizrach'],
  'kaddish_yatom': ['edot_mizrach'],
};

/// All nusachim to process (Chabad omitted until content is confirmed on Sefaria).
const _nusachim = ['ashkenaz', 'sfard', 'edot_mizrach'];

// ---------------------------------------------------------------------------
// SegmentBuilder
// ---------------------------------------------------------------------------

/// Orchestrates fetching all Mincha prayer segments from Sefaria and writing
/// the resulting JSON files to the assets directory tree.
///
/// Output layout
/// ─────────────
///   assets/prayers/segments/{segment_id}.json
///     → base segment with `default_text` (Ashkenaz text) + variants map
///
///   assets/prayers/nusach/{nusach_id}/{segment_id}.json
///     → nusach-specific text + variant texts + metadata (nikud, gender_tagged)
///
/// This is a superset of the existing NusachOverride schema; the data layer
/// can be updated to read per-segment nusach files in a follow-on task.
class SegmentBuilder {
  SegmentBuilder(this._sefaria, this._processor);

  final SefariaService _sefaria;
  final TextProcessor _processor;

  // ---------------------------------------------------------------------------
  // Public entry point
  // ---------------------------------------------------------------------------

  /// Run the full Mincha import, writing files under [outputDir].
  ///
  /// [outputDir] should point to `assets/prayers/` (relative or absolute).
  /// Set [dryRun] to true to log what would be written without touching disk.
  Future<void> buildMincha(String outputDir, {bool dryRun = false}) async {
    stdout.writeln('\n═══ Building universal segments ═══');
    for (final segId in _universalSegments) {
      await _buildUniversalSegment(segId, outputDir, dryRun);
    }

    stdout.writeln('\n═══ Building nusach-variant segments ═══');
    for (final segId in _nusachVariantSegments) {
      await _buildNusachVariantSegment(segId, outputDir, dryRun);
    }

    stdout.writeln('\n═══ Building nusach-restricted segments ═══');
    for (final entry in _restrictedSegments.entries) {
      await _buildRestrictedSegment(entry.key, entry.value, outputDir, dryRun);
    }

    stdout.writeln('\n═══ Import complete ═══');
  }

  // ---------------------------------------------------------------------------
  // Segment type handlers
  // ---------------------------------------------------------------------------

  Future<void> _buildUniversalSegment(
    String segId,
    String outputDir,
    bool dryRun,
  ) async {
    final rawText = await _sefaria.fetchSegment(segId, 'ashkenaz');
    if (rawText == null) return;

    final genderResult = _processor.applyGenderTags(rawText, segId);
    if (genderResult.tagged) stdout.writeln('      ↳ gender tags applied');

    final json = _makeSegmentJson(
      id: segId,
      defaultText: genderResult.text,
      variants: const {},
      conditionFlags: const [],
      excludeFlags: const [],
      optional: false,
    );

    await _writeJson(json: json, path: '$outputDir/segments/$segId.json', dryRun: dryRun);
  }

  Future<void> _buildNusachVariantSegment(
    String segId,
    String outputDir,
    bool dryRun,
  ) async {
    String? ashkenazText;

    for (final nusachId in _nusachim) {
      final rawText = await _sefaria.fetchSegment(segId, nusachId);
      if (rawText == null) continue;

      final genderResult = _processor.applyGenderTags(rawText, segId);
      if (genderResult.tagged) stdout.writeln('      ↳ gender tags applied ($nusachId)');

      final processedText = genderResult.text;
      if (nusachId == 'ashkenaz') ashkenazText = processedText;

      final nusachJson = _makeNusachSegmentJson(
        id: segId,
        nusachId: nusachId,
        text: processedText,
        variants: const {},
        hasNikud: _processor.hasNikud(processedText),
        genderTagged: genderResult.tagged,
        sources: NusachMapper.refsFor(segId, nusachId) ?? [],
      );
      await _writeJson(
        json: nusachJson,
        path: '$outputDir/nusach/$nusachId/$segId.json',
        dryRun: dryRun,
      );
    }

    if (ashkenazText != null) {
      final segJson = _makeSegmentJson(
        id: segId,
        defaultText: ashkenazText,
        variants: const {},
        conditionFlags: const [],
        excludeFlags: const [],
        optional: false,
      );
      await _writeJson(
        json: segJson,
        path: '$outputDir/segments/$segId.json',
        dryRun: dryRun,
      );
    }
  }

  Future<void> _buildRestrictedSegment(
    String segId,
    List<String> allowedNusachim,
    String outputDir,
    bool dryRun,
  ) async {
    for (final nusachId in allowedNusachim) {
      final rawText = await _sefaria.fetchSegment(segId, nusachId);
      if (rawText == null) continue;

      final genderResult = _processor.applyGenderTags(rawText, segId);

      // Restricted segments are nusach-specific; no base segment file is needed
      // (the template already gates them via allowed_nusach).
      final nusachJson = _makeNusachSegmentJson(
        id: segId,
        nusachId: nusachId,
        text: genderResult.text,
        variants: const {},
        hasNikud: _processor.hasNikud(genderResult.text),
        genderTagged: genderResult.tagged,
        sources: NusachMapper.refsFor(segId, nusachId) ?? [],
      );
      await _writeJson(
        json: nusachJson,
        path: '$outputDir/nusach/$nusachId/$segId.json',
        dryRun: dryRun,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // JSON schema builders
  // ---------------------------------------------------------------------------

  /// Builds the canonical segment JSON (matches PrayerSegment entity).
  Map<String, dynamic> _makeSegmentJson({
    required String id,
    required String defaultText,
    required Map<String, String> variants,
    required List<String> conditionFlags,
    required List<String> excludeFlags,
    required bool optional,
  }) {
    return {
      'id': id,
      'default_text': defaultText,
      'variants': variants,
      'condition_flags': conditionFlags,
      'exclude_flags': excludeFlags,
      'optional': optional,
    };
  }

  /// Builds the per-nusach segment override JSON.
  ///
  /// Schema:
  /// {
  ///   "id": "amidah_mincha",
  ///   "nusach": "sfard",
  ///   "text": "...",
  ///   "variants": { "shabbat_mincha": "..." },
  ///   "has_nikud": true,
  ///   "gender_tagged": false,
  ///   "sources": ["Siddur Sefard, Weekday Mincha, Amidah"]
  /// }
  ///
  /// The `sources` array lists the exact Sefaria refs used to produce the text,
  /// so provenance can be verified for Orthodox correctness.
  Map<String, dynamic> _makeNusachSegmentJson({
    required String id,
    required String nusachId,
    required String text,
    required Map<String, String> variants,
    required bool hasNikud,
    required bool genderTagged,
    required List<String> sources,
  }) {
    return {
      'id': id,
      'nusach': nusachId,
      'text': text,
      'variants': variants,
      'has_nikud': hasNikud,
      'gender_tagged': genderTagged,
      'sources': sources,
    };
  }

  // ---------------------------------------------------------------------------
  // File I/O
  // ---------------------------------------------------------------------------

  Future<void> _writeJson({
    required Map<String, dynamic> json,
    required String path,
    required bool dryRun,
  }) async {
    final encoded = const JsonEncoder.withIndent('  ').convert(json);

    if (dryRun) {
      stdout.writeln('[DRY]  Would write: $path (${encoded.length} bytes)');
      return;
    }

    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(encoded, flush: true);
    stdout.writeln('[WRITE] $path');
  }
}
