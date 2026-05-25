// Phase E.7a — Selichot for the four "public" minor fasts.
//
// Per user (2026-05-24):
//   Ashk says selichot on: 10 Tevet, Taanit Esther, 17 Tammuz, BaHaB.
//   Sfard says on:         10 Tevet, Taanit Esther, 17 Tammuz, BaHaB
//                          (BaHaB split into Sheni Kama / Chamishi /
//                          Sheni Batra — 3 separate texts).
//   EM says on:            Tzom Gedalya, 10 Tevet, Taanit Esther, 17 Tammuz.
//   ⚠ Ashk + Sfard do NOT say selichot inside the prayer on Tzom Gedalya.
//   ⚠ EM does NOT say selichot on BaHaB.
//
// This phase (E.7a) covers the four MAIN fasts only — 10 Tevet, Taanit
// Esther, 17 Tammuz, and Tzom Gedalya (EM only). BaHaB is deferred to
// E.7b because it needs custom calendar logic for the 3 specific days
// in Iyar/Cheshvan, which kosher_dart doesn't expose directly.
//
// Sources fetched from Sefaria at runtime — these texts are ~40KB each
// and not transcribed by hand. Trope marks (U+0591–U+05AF) are stripped,
// sof-pasuk (׃) → regular colon. Each Sefaria paragraph becomes one
// section in the resulting segment file; long paragraphs are split into
// JSON-array lines on pasuk-end boundaries.
//
// Templates patched: the existing generic `selichot` entry in each
// acharei_amidah_<nusach>.json (gated on [avinu_malkeinu, with_minyan,
// fast_day]) is replaced with N day-specific entries, each gated on the
// matching `fast_<name>` calendar flag + `with_minyan`.
//
// Run from project root:  node scripts/phase_e7a_selichot.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

function fetchSefaria(ref) {
  return new Promise((resolve, reject) => {
    const url = `https://www.sefaria.org/api/v3/texts/${ref}?return_format=text_only&version=hebrew`;
    https.get(url, (res) => {
      let raw = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(raw);
          resolve(json.versions[0].text);
        } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

// Strip trope marks; map sof-pasuk to colon; collapse whitespace.
function cleanHebrew(raw) {
  return raw
    .replace(/[֑-֯]/g, '')
    .replace(/׃/g, ':')
    .replace(/\s+/g, ' ')
    .trim();
}

// Sefaria sometimes embeds book references like "(תהלים סז)" inline —
// the reader sees them as book citations, not as recited text. Strip
// the pattern aggressively for any Tanach book name in Hebrew abbrev.
function stripBookRef(s) {
  return s.replace(/\s*\([֐-׿\s.,"׳״]{2,40}\)\s*/g, (m) => {
    // Only strip if the parens look like a citation: contain a book
    // abbreviation pattern (Hebrew letter+letter punctuation).
    if (/(תהלים|תהילים|במדבר|דברים|בראשית|שמות|ויקרא|ישעיה|ירמיה|יחזקאל|הושע|יואל|עמוס|עובדיה|יונה|מיכה|נחום|חבקוק|צפניה|חגי|זכריה|מלאכי|איוב|משלי|רות|שיר השירים|קהלת|איכה|אסתר|דניאל|עזרא|נחמיה|דהי|דברי הימים|איכה|תהלים)/.test(m)) {
      return ' ';
    }
    return m;
  });
}

// Split a single paragraph into array lines at pasuk-end boundaries
// (the `:` we normalized from sof-pasuk). Empty fragments dropped.
function splitParagraph(raw) {
  const cleaned = cleanHebrew(stripBookRef(raw));
  if (!cleaned) return null;
  // Split AFTER each colon; keep the colon attached to the preceding fragment.
  const parts = cleaned.split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
  return parts;
}

// Convert Sefaria's nested `text` (array of strings, or array of arrays
// of strings) into a list of sections suitable for our segment JSON.
function paragraphsToSections(text) {
  const sections = [];
  for (const para of text) {
    let lines;
    if (Array.isArray(para)) {
      // Flatten one level — sometimes Sefaria nests.
      const flat = para.flat(Infinity).filter((s) => typeof s === 'string' && s.trim());
      const joined = flat.join(' ');
      lines = splitParagraph(joined);
    } else if (typeof para === 'string') {
      lines = splitParagraph(para);
    }
    if (!lines || lines.length === 0) continue;
    sections.push({ text: lines, condition_flags: [], exclude_flags: [] });
  }
  return sections;
}

// ── Selichot definitions ────────────────────────────────────────────────────

// segment_id → list of { nusach, sefariaRef, segmentPath }
const SELICHOT = [
  {
    fastFlag: 'fast_10_tevet',
    fastName: '10 Tevet',
    nusachim: {
      ashkenaz:     'Siddur_Ashkenaz,_Festivals,_Selichot,_Ten_of_Tevet',
      sfard:        "Siddur_Sefard,_Fast_Days,_Selichot_for_Asara_B%27Tevet",
      edot_mizrach: 'Siddur_Edot_HaMizrach,_Fast_Days_and_Mourning,_Tenth_of_Tevet',
    },
    segmentId: 'selichot_10_tevet',
  },
  {
    fastFlag: 'fast_esther',
    fastName: 'Ta\'anit Esther',
    nusachim: {
      ashkenaz:     'Siddur_Ashkenaz,_Festivals,_Selichot,_Fast_of_Esther',
      sfard:        'Siddur_Sefard,_Fast_Days,_Selichot_for_Taanit_Esther',
      edot_mizrach: 'Siddur_Edot_HaMizrach,_Fast_Days_and_Mourning,_Fast_of_Esther',
    },
    segmentId: 'selichot_esther',
  },
  {
    fastFlag: 'fast_17_tammuz',
    fastName: '17 Tammuz',
    nusachim: {
      ashkenaz:     'Siddur_Ashkenaz,_Festivals,_Selichot,_Seventeen_of_Tamuz',
      sfard:        'Siddur_Sefard,_Fast_Days,_Selichot_for_17_Tamuz',
      edot_mizrach: 'Siddur_Edot_HaMizrach,_Fast_Days_and_Mourning,_Seventeenth_of_Tammuz',
    },
    segmentId: 'selichot_17_tammuz',
  },
  {
    fastFlag: 'fast_gedalia',
    fastName: 'Tzom Gedalya',
    nusachim: {
      // Ashk/Sfard intentionally absent — no in-prayer selichot for them.
      edot_mizrach: 'Siddur_Edot_HaMizrach,_Fast_Days_and_Mourning,_Fast_of_Gedalya',
    },
    segmentId: 'selichot_gedalia',
  },
];

const NUSACH_DIR = {
  ashkenaz:     path.join(ASSETS, 'shacharit', 'acharei_amidah', 'nusach', 'ashkenaz'),
  sfard:        path.join(ASSETS, 'shacharit', 'acharei_amidah', 'nusach', 'sfard'),
  edot_mizrach: path.join(ASSETS, 'shacharit', 'acharei_amidah', 'nusach', 'edot_mizrach'),
};

// ── Main ────────────────────────────────────────────────────────────────────

(async () => {
  const manifest = readJson(MANIFEST_PATH);

  let totalWritten = 0;
  for (const sel of SELICHOT) {
    for (const [nusach, ref] of Object.entries(sel.nusachim)) {
      process.stdout.write(`  fetching ${nusach}/${sel.segmentId} ... `);
      const text = await fetchSefaria(ref);
      const sections = paragraphsToSections(text);
      const filePath = path.join(NUSACH_DIR[nusach], `${sel.segmentId}.json`);
      writeJson(filePath, { id: sel.segmentId, sections });
      manifest.nusach[nusach][sel.segmentId] = rel(filePath);
      console.log(`${sections.length} sections, ${rel(filePath)}`);
      totalWritten++;
    }
  }

  // ── Patch acharei_amidah_<nusach> templates ───────────────────────────────
  // Replace the existing generic `selichot` entry with day-specific entries.
  const TPL_DIR = path.join(ASSETS, 'templates', 'shacharit');
  for (const nusach of Object.keys(NUSACH_DIR)) {
    const tplPath = path.join(TPL_DIR, `acharei_amidah_${nusach}.json`);
    const tpl = readJson(tplPath);
    const idx = tpl.segments.findIndex((s) => s.segment_id === 'selichot');
    if (idx < 0) {
      console.log(`  ${rel(tplPath)}: no generic selichot entry to replace`);
      continue;
    }
    // Preserve the existing exclude_flags + optional + allowed_nusach from
    // the old entry, only swap segment_id + tighten condition_flags.
    const old = tpl.segments[idx];
    const newEntries = [];
    for (const sel of SELICHOT) {
      if (!sel.nusachim[nusach]) continue;
      newEntries.push({
        segment_id: sel.segmentId,
        condition_flags: [sel.fastFlag, 'with_minyan'],
        exclude_flags: old.exclude_flags ?? [],
        optional: old.optional ?? false,
        allowed_nusach: old.allowed_nusach ?? [],
      });
    }
    tpl.segments.splice(idx, 1, ...newEntries);
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: replaced selichot with ${newEntries.length} fast-specific entries`);
  }

  // ── Persist manifest ─────────────────────────────────────────────────────
  function sortKeys(o) {
    if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
    const out = {};
    for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
    return out;
  }
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

  console.log(`\nTotal segment files written: ${totalWritten}`);
  console.log('DONE.');
})().catch((e) => { console.error(e); process.exit(1); });
