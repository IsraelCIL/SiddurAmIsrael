// Phase E.5 — Hoshanot for Chol HaMoed Sukkot + Hoshana Rabba.
//
// Per user (2026-05-25):
//   • Ashkenaz: day-by-day text from Sefaria Siddur Ashkenaz, Sukkot,
//     Hosha'anot, <Day>_of_Sukkot.
//   • Sfard: shares the Ashk text exactly (per user). Stored under common/
//     and resolved for both nusachim via the standard datasource fallback.
//   • EM: separate text (Wikisource). Built in E.5b as a per-nusach
//     override (manifest.nusach.edot_mizrach).
//   • Scope: Days 2-6 of Sukkot (CHM in EY) + Hoshana Rabba (day 7).
//     Day 1 (YT) and Shabbat CHM are out of scope.
//
// Strategy: emit 6 segments (one per day) in common/. Add 6 template
// entries to acharei_amidah_<nusach>, each gated by its sukkot_day_<N>
// flag + with_minyan + hoshanot_day. Exactly one fires per day.
//
// Position: after Hallel, before Kaddish Titkabal.
//   • Sfard + EM: physical printed copy here.
//   • Ashk: physical printed copy here too (user E.5.1 decision: one
//     printed copy only). An accordion-link segment is added after
//     Musaf Kaddish Titkabal (E.5c, separate phase) for users who say
//     Hoshanot post-Musaf to navigate back here.
//
// Run from project root:  node scripts/phase_e5_hoshanot.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const COMMON_DIR = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common', 'hoshanot');

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

function paragraphsToSections(text) {
  const sections = [];
  function pushParagraph(raw) {
    const cleaned = cleanHebrew(raw);
    if (!cleaned) return;
    const lines = cleaned.split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
    if (lines.length === 0) return;
    sections.push({ text: lines, condition_flags: [], exclude_flags: [] });
  }
  if (Array.isArray(text)) {
    for (const p of text) {
      if (Array.isArray(p)) {
        const flat = p.flat(Infinity).filter((s) => typeof s === 'string');
        pushParagraph(flat.join(' '));
      } else if (typeof p === 'string') {
        pushParagraph(p);
      }
    }
  } else if (typeof text === 'string') {
    pushParagraph(text);
  }
  return sections;
}

// Sukkot CHM day (1..7) → Sefaria ref + segment_id.
// sukkotDay=1 (YT) is OOS. sukkotDay=7 is Hoshana Rabba.
const DAYS = [
  { day: 2, segmentId: 'hoshanot_day_2', ref: 'Siddur_Ashkenaz,_Festivals,_Sukkot,_Hosha%27anot,_Second_Day_of_Sukkot' },
  { day: 3, segmentId: 'hoshanot_day_3', ref: 'Siddur_Ashkenaz,_Festivals,_Sukkot,_Hosha%27anot,_Third_Day_of_Sukkot' },
  { day: 4, segmentId: 'hoshanot_day_4', ref: 'Siddur_Ashkenaz,_Festivals,_Sukkot,_Hosha%27anot,_Fourth_Day_of_Sukkot' },
  { day: 5, segmentId: 'hoshanot_day_5', ref: 'Siddur_Ashkenaz,_Festivals,_Sukkot,_Hosha%27anot,_Fifth_Day_of_Sukkot' },
  { day: 6, segmentId: 'hoshanot_day_6', ref: 'Siddur_Ashkenaz,_Festivals,_Sukkot,_Hosha%27anot,_Sixth_Day_of_Sukkot' },
  { day: 7, segmentId: 'hoshanot_hoshana_rabba', ref: 'Siddur_Ashkenaz,_Festivals,_Sukkot,_Hosha%27anot,_Hosha%27ana_Rabba' },
];

(async () => {
  const manifest = readJson(MANIFEST_PATH);
  fs.mkdirSync(COMMON_DIR, { recursive: true });

  // ── Fetch & write common (Ashk = Sfard) segments ─────────────────────────
  for (const d of DAYS) {
    process.stdout.write(`  fetching day ${d.day} (${d.segmentId}) ... `);
    const text = await fetchSefaria(d.ref);
    const sections = paragraphsToSections(text);
    const filePath = path.join(COMMON_DIR, `${d.segmentId}.json`);
    writeJson(filePath, { id: d.segmentId, sections });
    manifest.common[d.segmentId] = rel(filePath);
    console.log(`${sections.length} sections, ${rel(filePath)}`);
  }

  // ── Patch templates ──────────────────────────────────────────────────────
  // Insert 6 entries (one per Sukkot day 2..7) in acharei_amidah_<nusach>
  // after the Hallel block. Each gated on its specific sukkot_day_<N> flag.
  const SUKKOT_DAY_FLAG = {
    2: 'sukkot_day_2', 3: 'sukkot_day_3', 4: 'sukkot_day_4',
    5: 'sukkot_day_5', 6: 'sukkot_day_6', 7: 'sukkot_day_7',
  };
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tplPath = path.join(
      ASSETS, 'templates', 'shacharit', `acharei_amidah_${nusach}.json`,
    );
    const tpl = readJson(tplPath);
    if (tpl.segments.some((s) => s.segment_id === 'hoshanot_day_2')) {
      console.log(`  ${rel(tplPath)}: already patched`);
      continue;
    }
    // Find Hallel block: there's `hallel` (full) and `hallel_half`. We want
    // to insert AFTER the last hallel reference.
    let lastHallelIdx = -1;
    for (let i = 0; i < tpl.segments.length; i++) {
      const id = tpl.segments[i].segment_id;
      if (id === 'hallel' || id === 'hallel_half') lastHallelIdx = i;
    }
    if (lastHallelIdx < 0) {
      console.log(`  ${rel(tplPath)}: no hallel anchor — skipping`);
      continue;
    }
    const newEntries = DAYS.map((d) => ({
      segment_id: d.segmentId,
      condition_flags: [SUKKOT_DAY_FLAG[d.day], 'hoshanot_day', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    }));
    tpl.segments.splice(lastHallelIdx + 1, 0, ...newEntries);
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted ${newEntries.length} Hoshanot entries at idx ${lastHallelIdx + 1}`);
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
