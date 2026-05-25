// Phase E.6b — Gr"a Shir Shel Yom mapping for CHM Pesach + CHM Sukkot.
//
// Per Wikisource (סידור/נוסח אשכנז/שיר של יום — מנהג הגר"א),
// on Chol HaMoed Pesach and Sukkot the Gr"a reads a different Tehillim
// chapter for SSY depending on (chag, day-in-chag, weekday-of-YT1).
//
// Scope: Eretz Yisrael only (per user — siddur not used in chu"l for YT).
// Pesach in EY runs YT1..YT7. YT1 falls on Sun/Tue/Thu/Sat (לא בד"ו).
// Sukkot in EY runs YT1..Hoshana Raba (day 7) + Simchat Torah (day 8 YT).
// YT1 falls on Mon/Tue/Thu/Sat (לא אד"ו ראש).
//
// Strategy: fetch each unique Tehillim chapter from Sefaria once, store
// as its own segment file. Build a 3-D lookup map keyed by:
//   chag (pesach | sukkot) → yt1_weekday (1-7) → day_in_chag (1-7) → ch
// where `ch` is either an integer chapter number or "94a" / "94b" (the
// two halves of Ps. 94 the Gr"a splits for Sukkot).
//
// GraSsyPostProcessor (separate file) reads UserContext.pesachDay /
// sukkotDay / chagYt1Weekday and replaces the `<gra_chapter>` placeholder
// in the resolvedText of `shir_shel_yom_gra` with the actual psalm text.
//
// Run from project root:  node scripts/phase_e6b_gra_ssy.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const TEHILLIM_DIR = path.join(ASSETS, 'shacharit', 'sof_hatfila', 'common', 'tehillim_gra');
const MAPPING_PATH = path.join(ASSETS, 'shacharit', 'sof_hatfila', 'common', '_gra_ssy_mapping.json');
const SEGMENT_PATH = path.join(ASSETS, 'shacharit', 'sof_hatfila', 'common', 'shir_shel_yom_gra.json');

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
      res.on('data', (c) => { raw += c; });
      res.on('end', () => {
        try { resolve(JSON.parse(raw).versions[0].text); }
        catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

function cleanHebrew(s) {
  return s.replace(/[֑-֯]/g, '').replace(/׃/g, ':').replace(/\s+/g, ' ').trim();
}
function splitToLines(s) {
  return cleanHebrew(s).split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
}

// ── Mapping tables transcribed from Wikisource ───────────────────────────────
// (chag, yt1_weekday_dart, day_in_chag) → chapterKey
// Day-of-week is Dart's Mon=1..Sun=7.
// Empty cells are days that are YT (out of scope) — skipped here.

// PESACH (EY) — Pesach has 7 days. Days 1+7 are YT. CHM = days 2-6.
// We ALSO need to cover day 7 (Acharon Pesach, YT in EY but Shabbat-edge
// when YT1=Sun → YT7=Sat, etc.). But since YT is OOS in our app entirely,
// we ONLY need CHM days 2-6 for Pesach.
// YT1 in EY can only be Sun(7), Tue(2), Thu(4), Sat(6).
const PESACH_MAP = {
  // YT1 = Sunday (Dart=7)
  7: { 2: 78, 3: 80, 4: 105, 5: 135, 6: 66 },
  // YT1 = Tuesday (Dart=2)
  2: { 2: 78, 3: 80, 4: 105, 5: 92,  6: 135 },
  // YT1 = Thursday (Dart=4)
  4: { 2: 78, 3: 92, 4: 80,  5: 105, 6: 135 },
  // YT1 = Shabbat (Dart=6)
  6: { 2: 114, 3: 78, 4: 80, 5: 105, 6: 135 },
};

// SUKKOT (EY) — 7 days. Day 1 = YT, day 7 = Hoshana Raba (read SSY normally).
// CHM = days 2-6, plus day 7 (Hoshana Raba). YT1 ∈ {Mon=1, Tue=2, Thu=4, Sat=6}.
// "94a" and "94b" are the two halves of Tehillim 94 the Gr"a splits.
const SUKKOT_MAP = {
  // YT1 = Monday (Dart=1)
  1: { 2: 29, 3: 50, 4: '94b', 5: '94a', 6: 92, 7: 81 },
  // YT1 = Tuesday (Dart=2)
  2: { 2: 29, 3: 50, 4: '94b', 5: 92, 6: '94a', 7: 81 },
  // YT1 = Thursday (Dart=4)
  4: { 2: 29, 3: 92, 4: 50, 5: '94b', 6: '94a', 7: 81 },
  // YT1 = Shabbat (Dart=6)
  6: { 2: 29, 3: 50, 4: '94b', 5: '94a', 6: 81, 7: 82 },
};

// ── Collect unique chapter keys we need to fetch ────────────────────────────
const allKeys = new Set();
for (const m of [PESACH_MAP, SUKKOT_MAP]) {
  for (const weekday of Object.values(m)) {
    for (const ch of Object.values(weekday)) allKeys.add(String(ch));
  }
}

// Tehillim 94 split point: 94:1-7 = part "a" (about God-of-vengeance,
// preface) and 94:8-23 = part "b" (the "binu boarim ba'am" continuation
// and conclusion). Wikisource shows them as distinct mizmorim — we
// fetch the full chapter and slice at the verse boundary.
const PSALM_94_SPLIT_VERSE = 8;

// ── Main ────────────────────────────────────────────────────────────────────

(async () => {
  const manifest = readJson(MANIFEST_PATH);
  fs.mkdirSync(TEHILLIM_DIR, { recursive: true });

  // Resolve chapter key → segmentId + filePath, fetch text.
  const chapterFiles = {}; // key → { segmentId, manifestKey, filePath, lines }
  for (const key of [...allKeys].sort()) {
    const chapter = key.replace(/[ab]$/, '');
    const half = key.endsWith('a') ? 'a' : key.endsWith('b') ? 'b' : null;
    const segmentId = `tehillim_gra_${key}`;
    process.stdout.write(`  fetching Tehillim ${key} ... `);
    const ref = `Psalms.${chapter}`;
    const text = await fetchSefaria(ref);
    // text is an array of verse strings.
    let verses = Array.isArray(text)
      ? text.filter((v) => typeof v === 'string' && v.trim().length > 0)
      : [String(text)];
    if (half === 'a') verses = verses.slice(0, PSALM_94_SPLIT_VERSE - 1);
    if (half === 'b') verses = verses.slice(PSALM_94_SPLIT_VERSE - 1);
    const cleaned = verses.map((v) => cleanHebrew(v));
    const lines = cleaned.flatMap((v) => v.split(/(?<=:)\s+/)).filter((p) => p.trim().length > 0);
    const filePath = path.join(TEHILLIM_DIR, `${segmentId}.json`);
    writeJson(filePath, {
      id: segmentId,
      sections: [{ text: lines, condition_flags: [], exclude_flags: [] }],
    });
    manifest.common[segmentId] = rel(filePath);
    chapterFiles[key] = { segmentId, filePath, lineCount: lines.length };
    console.log(`${lines.length} lines, ${rel(filePath)}`);
  }

  // ── Mapping JSON (read by GraSsyPostProcessor at runtime) ─────────────────
  // We store the segmentId directly (e.g. "tehillim_gra_78") so the
  // post-processor can fetch the right text via the standard datasource.
  function mapToSegmentIds(srcMap) {
    const out = {};
    for (const [wd, days] of Object.entries(srcMap)) {
      out[wd] = {};
      for (const [d, ch] of Object.entries(days)) {
        out[wd][d] = `tehillim_gra_${ch}`;
      }
    }
    return out;
  }
  const mapping = {
    pesach: mapToSegmentIds(PESACH_MAP),
    sukkot: mapToSegmentIds(SUKKOT_MAP),
  };
  writeJson(MAPPING_PATH, mapping);
  manifest.common['_gra_ssy_mapping'] = rel(MAPPING_PATH);
  console.log(`  wrote ${rel(MAPPING_PATH)}`);

  // ── shir_shel_yom_gra segment ─────────────────────────────────────────────
  // This is a placeholder — the GraSsyPostProcessor replaces the body
  // at runtime by injecting the resolved chapter's text. If the day is
  // outside CHM Pesach/Sukkot the segment won't be emitted at all
  // (gated by `gra_ssy_day` flag).
  writeJson(SEGMENT_PATH, {
    id: 'shir_shel_yom_gra',
    sections: [{ text: ['{{gra_chapter}}'], condition_flags: [], exclude_flags: [] }],
  });
  manifest.common['shir_shel_yom_gra'] = rel(SEGMENT_PATH);
  console.log(`  wrote ${rel(SEGMENT_PATH)} (placeholder)`);

  // ── Wire into sof_hatfila for Ashkenaz + Sfard as optional ────────────────
  for (const nusach of ['ashkenaz', 'sfard']) {
    const tplPath = path.join(
      ASSETS, 'templates', 'shacharit', `sof_hatfila_${nusach}.json`,
    );
    if (!fs.existsSync(tplPath)) {
      console.log(`  ${rel(tplPath)}: NOT FOUND, skipping`);
      continue;
    }
    const tpl = readJson(tplPath);
    if (tpl.segments.some((s) => s.segment_id === 'shir_shel_yom_gra')) {
      console.log(`  ${rel(tplPath)}: already patched`);
      continue;
    }
    // Insert right after the regular shir_shel_yom reference.
    const idx = tpl.segments.findIndex(
      (s) => s.sub_template_id === 'shir_shel_yom' || s.segment_id === 'shir_shel_yom',
    );
    if (idx < 0) {
      console.log(`  ${rel(tplPath)}: no shir_shel_yom anchor found, skipping`);
      continue;
    }
    tpl.segments.splice(idx + 1, 0, {
      segment_id: 'shir_shel_yom_gra',
      condition_flags: ['gra_ssy_day'],
      exclude_flags: [],
      optional: true,
      allowed_nusach: [nusach],
    });
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted shir_shel_yom_gra (optional) at idx ${idx + 1}`);
  }

  function sortKeys(o) {
    if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
    const out = {};
    for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
    return out;
  }
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

  console.log('\nDONE.');
})().catch((e) => { console.error(e); process.exit(1); });
