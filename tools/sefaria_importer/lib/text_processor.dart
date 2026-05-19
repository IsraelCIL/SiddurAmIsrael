/// Cleans and enriches raw Sefaria text for storage in our prayer JSON schema.
///
/// Pipeline (in order):
///   1. flattenText  — normalises the value Sefaria returns (String | List)
///   2. stripHtml    — removes HTML tags and decodes common entities
///   3. normalize    — collapses whitespace and trims
///   4. applyGenderTags — wraps known gendered phrases with {{male|female}}
class TextProcessor {
  // ---------------------------------------------------------------------------
  // Regex constants
  // ---------------------------------------------------------------------------

  static final _htmlTag = RegExp(r'<[^>]+>');
  static final _multiSpace = RegExp(r' {2,}');
  static final _trailingNewlines = RegExp(r'\n{3,}');

  /// Unicode block U+05B0–U+05C7 covers all Hebrew nikud (vowel points).
  static final _nikud = RegExp(r'[ְ-ׇ]');

  // ---------------------------------------------------------------------------
  // Public interface
  // ---------------------------------------------------------------------------

  /// Full processing pipeline: flatten → strip HTML → normalize → return.
  /// Gender tags are NOT applied here; call [applyGenderTags] separately so
  /// callers can decide whether to tag a given segment.
  String process(dynamic rawText) {
    final flat = flattenText(rawText);
    final stripped = stripHtml(flat);
    return normalize(stripped);
  }

  /// Flatten Sefaria's polymorphic text field.
  ///
  /// Sefaria can return:
  ///   • String                   — simple passage
  ///   • List<String>             — paragraphs / verses
  ///   • List<List<String>>       — chapters → verses (e.g. full Amidah)
  ///
  /// All cases collapse to a single newline-separated string.
  String flattenText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List) {
      return value
          .map(flattenText)
          .where((s) => s.isNotEmpty)
          .join('\n');
    }
    return value.toString();
  }

  /// Remove HTML tags and decode the five basic HTML entities.
  String stripHtml(String text) {
    return text
        .replaceAll(_htmlTag, '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&nbsp;', ' ');
  }

  /// Collapse repeated spaces/newlines and trim outer whitespace.
  String normalize(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_multiSpace, ' ')
        .replaceAll(_trailingNewlines, '\n\n')
        .trim();
  }

  /// Returns true if [text] contains at least one Hebrew nikud character.
  bool hasNikud(String text) => _nikud.hasMatch(text);

  /// Inject `{{male_form|female_form}}` inline markers for known gendered
  /// phrases in [segmentId].
  ///
  /// Returns a record with:
  ///   • [text]   — the (possibly modified) text
  ///   • [tagged] — whether any substitutions were made
  ///
  /// Only phrases listed in [_genderRules] are touched; everything else is
  /// left verbatim so we never silently corrupt prayer text.
  ///
  /// All variants must have a recognised Halachic basis in Orthodox poskim.
  /// Non-Orthodox liturgical changes (Reform, Conservative, Egalitarian, etc.)
  /// must never be added as rules here or anywhere else in the application.
  ({String text, bool tagged}) applyGenderTags(String text, String segmentId) {
    // No halachic Orthodox gender variants are currently defined for Mincha.
    // Add rules to _genderRules below only when a specific poskim source is cited.
    return (text: text, tagged: false);
  }
}

// ---------------------------------------------------------------------------
// Halachic gender substitution rules
// ---------------------------------------------------------------------------
//
// When a specific blessing requires a different verbal form for women
// (supported by a named posek / Orthodox siddur edition), add a rule here
// and wire it into applyGenderTags.
//
// Non-Orthodox liturgical variants (Reform, Conservative, Egalitarian, etc.)
// must NEVER be added — see CLAUDE.md "Halachic Standard".
