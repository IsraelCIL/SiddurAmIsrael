// Phase E.7b — BaHaB (בה"ב) selichot.
//
// BaHaB = three penitential days observed in Cheshvan (post-Sukkot) and
// Iyar (post-Pesach) by some communities. Rule: starts on the SECOND
// Monday of the Jewish month, then the following Thursday, then the
// following Monday. Calendar logic lives in HalachicCalendarService.
//
// Per user: EM does NOT observe BaHaB in-prayer. Sfard splits into
// three distinct selichot texts (one per day); Ashk has a single
// combined text covering all three days.
//
// Run from project root:  node scripts/phase_e7b_bahab.js

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
      res.on('data', (c) => { raw += c; });
      res.on('end', () => {
        try { resolve(JSON.parse(raw).versions[0].text); }
        catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

function cleanHebrew(raw) {
  return raw.replace(/[֑-֯]/g, '').replace(/׃/g, ':').replace(/\s+/g, ' ').trim();
}

function splitParagraph(raw) {
  const cleaned = cleanHebrew(raw);
  if (!cleaned) return null;
  return cleaned.split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
}

function paragraphsToSections(text) {
  const sections = [];
  for (const para of text) {
    let lines;
    if (Array.isArray(para)) {
      const flat = para.flat(Infinity).filter((s) => typeof s === 'string' && s.trim());
      lines = splitParagraph(flat.join(' '));
    } else if (typeof para === 'string') {
      lines = splitParagraph(para);
    }
    if (!lines || lines.length === 0) continue;
    sections.push({ text: lines, condition_flags: [], exclude_flags: [] });
  }
  return sections;
}

// Each entry: { nusach, segmentId, ref, condition }
const PLAN = [
  {
    nusach: 'ashkenaz',
    segmentId: 'selichot_bahab',
    ref: 'Siddur_Ashkenaz,_Festivals,_Selichot,_BaHaB',
    fastFlag: 'bahab_day',
  },
  {
    nusach: 'sfard',
    segmentId: 'selichot_bahab_sheni_kama',
    ref: 'Siddur_Sefard,_Fast_Days,_Selichot_for_First_Monday',
    fastFlag: 'bahab_sheni_kama',
  },
  {
    nusach: 'sfard',
    segmentId: 'selichot_bahab_chamishi',
    ref: 'Siddur_Sefard,_Fast_Days,_Selichot_for_Thursday',
    fastFlag: 'bahab_chamishi',
  },
  {
    nusach: 'sfard',
    segmentId: 'selichot_bahab_sheni_batra',
    ref: 'Siddur_Sefard,_Fast_Days,_Selichot_for_Concluding_Monday',
    fastFlag: 'bahab_sheni_batra',
  },
];

(async () => {
  const manifest = readJson(MANIFEST_PATH);
  const inserts = { ashkenaz: [], sfard: [] };

  for (const p of PLAN) {
    process.stdout.write(`  fetching ${p.nusach}/${p.segmentId} ... `);
    const text = await fetchSefaria(p.ref);
    const sections = paragraphsToSections(text);
    const filePath = path.join(
      ASSETS, 'shacharit', 'acharei_amidah', 'nusach', p.nusach,
      `${p.segmentId}.json`,
    );
    writeJson(filePath, { id: p.segmentId, sections });
    manifest.nusach[p.nusach][p.segmentId] = rel(filePath);
    inserts[p.nusach].push({
      segment_id: p.segmentId,
      condition_flags: [p.fastFlag, 'with_minyan'],
      exclude_flags: ['skip_tachanun'],
      optional: false,
      allowed_nusach: [],
    });
    console.log(`${sections.length} sections, ${rel(filePath)}`);
  }

  // ── Patch acharei_amidah_<nusach> templates ────────────────────────────────
  // Insert BaHaB selichot entries right after the existing fast-day
  // selichot block (or, if not found, right after the tachanun reference).
  const TPL_DIR = path.join(ASSETS, 'templates', 'shacharit');
  for (const nusach of Object.keys(inserts)) {
    if (inserts[nusach].length === 0) continue;
    const tplPath = path.join(TPL_DIR, `acharei_amidah_${nusach}.json`);
    const tpl = readJson(tplPath);
    // Skip if already inserted (idempotent).
    if (tpl.segments.some((s) => s.segment_id === inserts[nusach][0].segment_id)) {
      console.log(`  ${rel(tplPath)}: already patched`);
      continue;
    }
    // Find insertion point: after the last existing `selichot_*` entry,
    // or after the first tachanun sub_template_id.
    let lastSelichot = -1;
    for (let i = 0; i < tpl.segments.length; i++) {
      const s = tpl.segments[i];
      if (s.segment_id && s.segment_id.startsWith('selichot_')) lastSelichot = i;
    }
    let insertAt;
    if (lastSelichot >= 0) {
      insertAt = lastSelichot + 1;
    } else {
      insertAt = tpl.segments.findIndex(
        (s) => s.sub_template_id && s.sub_template_id.startsWith('tachanun_'),
      ) + 1;
      if (insertAt === 0) insertAt = 0;
    }
    tpl.segments.splice(insertAt, 0, ...inserts[nusach]);
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted ${inserts[nusach].length} BaHaB entr${inserts[nusach].length === 1 ? 'y' : 'ies'} at idx ${insertAt}`);
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
