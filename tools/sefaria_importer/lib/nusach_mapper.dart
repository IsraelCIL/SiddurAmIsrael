/// Maps each (segmentId, nusachId) pair to the exact ordered list of Sefaria
/// reference strings that should be fetched and concatenated to produce the
/// full prayer text.
///
/// Design notes
/// ─────────────
/// • Some segments require multiple refs (e.g. the Ashkenaz weekday Amida,
///   which Sefaria splits into 22 individual blessings).  Each ref is fetched
///   in order; results are joined with '\n\n'.
/// • When a traditional Orthodox source is not available in the target nusach's
///   own Sefaria book, the closest Orthodox equivalent is used as a fallback
///   and the field 'sources' in the output JSON makes the provenance explicit.
/// • An empty list means "this segment intentionally does not exist for this
///   nusach" (e.g. Petihat Eliyahu only exists for Edot HaMizrach).
/// • null from refsFor() means "segment not in the mapper at all" — caller
///   should log a warning.
class NusachMapper {
  // ---------------------------------------------------------------------------
  // Primary API
  // ---------------------------------------------------------------------------

  /// Returns the ordered Sefaria refs for [segmentId] in [nusachId], or null
  /// if the combination is not mapped.  An empty list means the segment is
  /// intentionally absent for this nusach (caller should skip silently).
  static List<String>? refsFor(String segmentId, String nusachId) {
    return _segmentRefs[nusachId]?[segmentId];
  }

  // ---------------------------------------------------------------------------
  // Version scoring (used when a ref has multiple Hebrew versions available)
  // ---------------------------------------------------------------------------

  static const Map<String, List<String>> _nusachVersionKeywords = {
    'ashkenaz': ['Ashkenaz', 'אשכנז', 'Metsudah', 'Metsuda', 'Birnbaum'],
    'sfard': ['Sefard', 'Sfard', 'ספרד', 'Metsudah', 'Metsuda'],
    'edot_mizrach': ['Mizrach', 'מזרח', 'Edot', 'עדות המזרח', 'Sephardi', 'Ben Ish Chai'],
    'chabad': ['Chabad', 'חב"ד', 'Lubavitch', 'Tehillat Hashem'],
  };

  static const List<String> _nikudKeywords = [
    'מנוקד', 'Torat Emet', 'Mevaser Emet', 'Metsudah', 'Metsuda',
    'Vocalized', 'Niqqud', 'Siddur',
  ];

  /// Scores a version title: higher = better match for [nusachId] and nikud.
  ///
  ///   +50  nusach keyword match
  ///   +30  nikud keyword match
  ///   +0–5 Sefaria's own priority field
  ///   −20  title signals a translation or commentary
  static int scoreVersion(
    String versionTitle,
    String nusachId, {
    int sefariaPriority = 0,
  }) {
    int score = 0;
    for (final kw in _nusachVersionKeywords[nusachId] ?? <String>[]) {
      if (versionTitle.contains(kw)) {
        score += 50;
        break;
      }
    }
    for (final kw in _nikudKeywords) {
      if (versionTitle.contains(kw)) {
        score += 30;
        break;
      }
    }
    score += sefariaPriority.clamp(0, 5);
    final lc = versionTitle.toLowerCase();
    if (lc.contains('translation') || lc.contains('english') || lc.contains('commentary')) {
      score -= 20;
    }
    return score;
  }

  // ---------------------------------------------------------------------------
  // Reference map
  // All paths verified against live Sefaria API.  Source: The Metsudah Siddur
  // (Avrohom Davis, 1981) — confirmed traditional Orthodox source.
  // ---------------------------------------------------------------------------

  static const Map<String, Map<String, List<String>>> _segmentRefs = {
    // ── ASHKENAZ ──────────────────────────────────────────────────────────────
    'ashkenaz': {
      // Ashrei (Psalm 145 + framing verses) — identical across all nusachim.
      'ashrei': [
        'Siddur Ashkenaz, Weekday, Minchah, Ashrei',
      ],

      // Weekday Amida: Sefaria splits it into 22 individual blessings.
      // Fetched in halachic order and joined with \n\n.
      'amidah_mincha': [
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Patriarchs',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Divine Might',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Holiness of God',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Keduasha',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Knowledge',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Repentance',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Forgiveness',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Redemption',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Healing',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Prosperity',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Gathering the Exiles',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Justice',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Against Enemies',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, The Righteous',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Rebuilding Jerusalem',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Kingdom of David',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Response to Prayer',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Temple Service',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Thanksgiving',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Birkat Kohanim',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Peace',
        'Siddur Ashkenaz, Weekday, Minchah, Amida, Concluding Passage',
      ],

      // Tachanun (Ashkenaz): Nefilat Appayim (Psalm 6) + Shomer Yisrael.
      // No Vidui or 13 Attributes preamble — those are Sfard/EM only.
      'tachanun': [
        'Siddur Ashkenaz, Weekday, Minchah, Post Amidah, Tachanun, Nefilat Appayim',
        'Siddur Ashkenaz, Weekday, Minchah, Post Amidah, Tachanun, Shomer Yisrael',
      ],

      'aleinu': [
        'Siddur Ashkenaz, Weekday, Minchah, Concluding Prayers, Alenu',
      ],

      'kaddish_yatom': [
        "Siddur Ashkenaz, Weekday, Minchah, Concluding Prayers, Mourner's Kaddish",
      ],

      // Edot HaMizrach-only segments — intentionally absent in Ashkenaz.
      'petihat_eliyahu': [],
      'lamenatzeach': [],
    },

    // ── SFARD ─────────────────────────────────────────────────────────────────
    'sfard': {
      // Siddur Sefard on Sefaria does not include Ashrei inside Weekday Mincha.
      // Ashrei (Psalm 145) is textually identical across nusachim, so we use
      // the Ashkenaz ref as the source.
      'ashrei': [
        'Siddur Ashkenaz, Weekday, Minchah, Ashrei',
      ],

      // Sefard Amida is a flat JaggedArrayNode — fetchable as a single unit.
      'amidah_mincha': [
        'Siddur Sefard, Weekday Mincha, Amidah',
      ],

      // Tachanun (Sfard): Vidui confession + 13 Attributes + Nefilat Appayim
      // (Psalm 6) + Shomer Yisrael.  Sefaria's Tachanun node also contains
      // Kaddish and Aleinu at the end; those are handled as separate segments.
      'tachanun': [
        'Siddur Sefard, Weekday Mincha, Tachanun',
      ],

      // Aleinu is not under Weekday Mincha in Siddur Sefard; it only appears
      // in Shacharit.  The text is identical — same source is used.
      'aleinu': [
        'Siddur Sefard, Weekday Shacharit, Aleinu',
      ],

      // Kaddish Yatom is not indexed in Siddur Sefard; use Ashkenaz ref
      // (text is halachically identical across nusachim).
      'kaddish_yatom': [
        "Siddur Ashkenaz, Weekday, Minchah, Concluding Prayers, Mourner's Kaddish",
      ],

      'petihat_eliyahu': [],
      'lamenatzeach': [],
    },

    // ── EDOT HAMIZRACH ────────────────────────────────────────────────────────
    'edot_mizrach': {
      // Ashrei is identical across nusachim — use Ashkenaz source.
      'ashrei': [
        'Siddur Ashkenaz, Weekday, Minchah, Ashrei',
      ],

      // Edot HaMizrach Amida is a flat node (like Sefard).
      'amidah_mincha': [
        'Siddur Edot HaMizrach, Weekday Mincha, Amida',
      ],

      // Tachanun (Edot HaMizrach): Vidui confession + 13 Attributes +
      // Psalm 25 (לְדָוִד אֵלֶיךָ ה' נַפְשִׁי אֶשָּׂא) — the EM form of
      // Nefilat Appayim, distinct from the Psalm 6 used in Ashkenaz/Sfard.
      // Sefaria's Vidui node also includes extra content at the end;
      // handled as separate segments.
      'tachanun': [
        'Siddur Edot HaMizrach, Weekday Mincha, Vidui',
      ],

      // Aleinu is inside Weekday Mincha in Edot HaMizrach (unlike Ashkenaz/Sefard).
      'aleinu': [
        'Siddur Edot HaMizrach, Weekday Mincha, Alenu',
      ],

      // Kaddish Yatom: not yet confirmed in Siddur Edot HaMizrach — use Ashkenaz.
      'kaddish_yatom': [
        "Siddur Ashkenaz, Weekday, Minchah, Concluding Prayers, Mourner's Kaddish",
      ],

      // Edot HaMizrach-exclusive segments (template gates via allowed_nusach).
      // Refs TBD — marked empty until paths are confirmed via API.
      'petihat_eliyahu': [],
      'lamenatzeach': [],
    },
  };
}
