import '../entities/assembled_segment.dart';
import '../entities/omer_day.dart';

/// Applies day-specific transformations to Sefirat HaOmer segments after
/// they have been assembled.
///
/// Transformations:
///   • `sefirat_haomer_day_count`        — replace `{{omer_day_count}}` with
///                                          the day's counting text for nusach
///   • `sefirat_haomer_ribono_shel_olam` — replace `{{omer_sefira}}` with the
///                                          day's sefira (e.g. "חֶסֶד שֶׁבְּחֶסֶד")
///   • `sefirat_haomer_lamenatzeach`     — wrap the day's lamenatzeach word
///                                          in `<b>...</b>`; wrap the day's
///                                          letter of the "ישמחו..." verse
///                                          in `<b>...</b>` as well
///   • `sefirat_haomer_ana_bekoach`      — in the line corresponding to
///                                          `day.week`, wrap either the
///                                          dayInWeek-th word (days 1–6 of
///                                          the week) or the line's acronym
///                                          (day 7 of the week — end of week)
///                                          in `<b>...</b>`
///
/// The bold token is `<b>...</b>` (HTML-style). [PrayerTextWidget] is
/// responsible for parsing this into a styled TextSpan.
class OmerPostProcessor {
  const OmerPostProcessor();

  AssembledSegment process(AssembledSegment seg, OmerDay day, String nusach) {
    switch (seg.id) {
      case 'sefirat_haomer_day_count':
        return seg.copyWith(
          resolvedText: seg.resolvedText
              .replaceAll('{{omer_day_count}}', day.textFor(nusach)),
        );
      case 'sefirat_haomer_ribono_shel_olam':
        return seg.copyWith(
          resolvedText:
              seg.resolvedText.replaceAll('{{omer_sefira}}', day.sefira),
        );
      case 'sefirat_haomer_lamenatzeach':
        return seg.copyWith(
          resolvedText: _processLamenatzeach(seg.resolvedText, day),
        );
      case 'sefirat_haomer_ana_bekoach':
        return seg.copyWith(
          resolvedText: _processAnaBekoach(seg.resolvedText, day),
        );
      default:
        return seg;
    }
  }

  // ─── Lamenatzeach (Psalm 67) ───────────────────────────────────────────
  // 1) Bold the Nth word of the psalm body (1-indexed, N = day, counted
  //    AFTER the heading ending in "...שִׁיר:").
  // 2) Bold the (day-1)-th consonant inside the verse that begins with
  //    "ישמחו וירננו..." (verse 5 of Psalm 67).
  String _processLamenatzeach(String text, OmerDay day) {
    // Step 1 — find end of heading (first ':')
    final headingEnd = text.indexOf(':');
    if (headingEnd < 0) return text;
    final headPart = text.substring(0, headingEnd + 1);
    var bodyPart = text.substring(headingEnd + 1);

    // Step 2 — bold the Nth word in the body FIRST (on clean text so that
    // word indices are stable and no nested-tag artefact arises).
    bodyPart = _boldNthWord(bodyPart, day.day);

    // Step 3 — bold the letter in the "ישמחו" verse.  _boldYismechuLetter
    // uses consonant-only matching that skips the <b>/<b> tags already
    // inserted in Step 2, so the search and position are still correct.
    bodyPart = _boldYismechuLetter(bodyPart, day.day);

    return headPart + bodyPart;
  }

  String _boldYismechuLetter(String body, int day) {
    // Find the start of the yismechu verse using consonant-only match.
    final yismStart = _findBareSubstring(body, 'ישמחו');
    if (yismStart == null) return body;
    final pos = _nthConsonantAt(body, yismStart, day);
    if (pos == null) return body;
    return _wrapCluster(body, pos);
  }

  // ─── Ana BeKoach ────────────────────────────────────────────────────────
  // Lines are joined by '\n' in the assembled text. Line index 0..6 = the 7
  // poetic lines; line index 7 = whispered "Baruch Shem". For day d:
  //   week     = ceil(d/7),  dayInWeek = ((d-1) mod 7) + 1
  //   line     = week - 1
  //   if dayInWeek 1..6:    bold the dayInWeek-th word of the line
  //   if dayInWeek == 7:    bold the parenthetical at the END of the line
  String _processAnaBekoach(String text, OmerDay day) {
    final lines = text.split('\n');
    final lineIdx = day.week - 1;
    if (lineIdx < 0 || lineIdx >= lines.length) return text;
    if (day.dayInWeek == 7) {
      lines[lineIdx] = _boldParenthetical(lines[lineIdx]);
    } else {
      lines[lineIdx] = _boldNthWord(lines[lineIdx], day.dayInWeek);
    }
    return lines.join('\n');
  }

  String _boldParenthetical(String line) {
    // Bold the LAST "(...)" group in the line.
    final regex = RegExp(r'\([^()]+\)');
    Match? lastMatch;
    for (final m in regex.allMatches(line)) {
      lastMatch = m;
    }
    if (lastMatch == null) return line;
    return line.substring(0, lastMatch.start) +
        '<b>' +
        lastMatch.group(0)! +
        '</b>' +
        line.substring(lastMatch.end);
  }

  // ─── Word/letter helpers ────────────────────────────────────────────────

  String _boldNthWord(String text, int n) {
    // A "word" is a run of consecutive non-whitespace characters.
    final regex = RegExp(r'\S+');
    final matches = regex.allMatches(text).toList();
    if (n < 1 || n > matches.length) return text;
    final m = matches[n - 1];
    return text.substring(0, m.start) +
        '<b>' +
        m.group(0)! +
        '</b>' +
        text.substring(m.end);
  }

  // Hebrew consonant range (alef..tav and final forms).
  bool _isHebConsonant(int code) => code >= 0x05D0 && code <= 0x05EA;

  // Niqqud / cantillation / combining marks that attach to a consonant.
  bool _isHebMark(int code) =>
      (code >= 0x0591 && code <= 0x05BD) ||
      code == 0x05BF ||
      (code >= 0x05C1 && code <= 0x05C2) ||
      (code >= 0x05C4 && code <= 0x05C5) ||
      code == 0x05C7;

  /// Returns the index in [text] of the first occurrence of [needle] when
  /// both are compared as consonant-only sequences (niqqud and cantillation
  /// stripped). The returned index points to the matching consonant in the
  /// original (un-stripped) text.
  int? _findBareSubstring(String text, String needle) {
    final positions = <int>[];
    final buf = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);
      if (_isHebConsonant(c)) {
        positions.add(i);
        buf.writeCharCode(c);
      } else if (!_isHebMark(c)) {
        // Treat anything else (spaces, punctuation) as separator — collapse
        // it to a single space in the bare buffer to avoid spurious matches.
        if (buf.isNotEmpty && buf.toString().codeUnitAt(buf.length - 1) != 0x20) {
          positions.add(i);
          buf.writeCharCode(0x20);
        }
      }
    }
    final bareNeedle = needle.runes
        .where((c) => _isHebConsonant(c))
        .map((c) => String.fromCharCode(c))
        .join();
    if (bareNeedle.isEmpty) return null;
    final idx = buf.toString().indexOf(bareNeedle);
    if (idx < 0) return null;
    return positions[idx];
  }

  /// Walks forward from [startPos] in [text] and returns the index of the
  /// [n]-th Hebrew consonant (1-indexed). The first consonant AT [startPos]
  /// counts as 1.
  int? _nthConsonantAt(String text, int startPos, int n) {
    var count = 0;
    for (var i = startPos; i < text.length; i++) {
      if (_isHebConsonant(text.codeUnitAt(i))) {
        count++;
        if (count == n) return i;
      }
    }
    return null;
  }

  /// Wraps the consonant at [pos] together with any trailing combining
  /// marks (niqqud, dagesh, shin/sin dot, etc.) in `<b>...</b>`.
  String _wrapCluster(String text, int pos) {
    var end = pos + 1;
    while (end < text.length && _isHebMark(text.codeUnitAt(end))) {
      end++;
    }
    return text.substring(0, pos) +
        '<b>' +
        text.substring(pos, end) +
        '</b>' +
        text.substring(end);
  }
}
