// Phase E.6a — EM Shir Shel Yom additional mizmorim.
//
// In Edot HaMizrach nusach, on certain days an additional Tehillim
// mizmor is recited after the daily Shir Shel Yom (and its Hoshianu
// continuation), BEFORE Kaddish Yatom. Source: Siddur Edot HaMizrach,
// Weekday Shacharit, Song_of_the_Day §14–§24.
//
// Per source (verified on Sefaria):
//   • Tzom Gedalia + 10 Tevet → Tehillim 83  (§16)
//   • Day after Yom Kippur    → Tehillim 85  (§18)
//   • Chanukah                → Tehillim 30  (§20)
//   • Ta'anit Esther + Purim  → Tehillim 22  (§22)
//   • 17 Tammuz               → Tehillim 79  (§24)
//
// Note: Sefaria §25–§26 is the "Beit Avel" (mourner's house) mizmor —
// out of scope because it depends on personal user state, not a
// calendar flag. Erev Shabbat §14 (Hashem Malach) is the EM weekday
// replacement for the regular SSY, not an addition — out of scope here
// (would need its own structural treatment).
//
// Run from project root:  node scripts/phase_e6a_ssy_em_extras.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const NUSACH_DIR = path.join(ASSETS, 'shacharit', 'sof_hatfila', 'nusach', 'edot_mizrach');

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

// Strip inline book citations: "(תהילים פג:א-ג)" etc.
function stripBookRef(s) {
  return s.replace(/\s*\(תהי?לים[^)]*\)\s*/g, ' ');
}

function splitToLines(s) {
  return cleanHebrew(stripBookRef(s)).split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
}

const SOURCES = [
  {
    section: 16,
    segmentId: 'ssy_em_extra_tzom_gedalia_10_tevet',
    psalmId: 'Tehillim 83',
    conditionFlags: ['fast_gedalia'],
    conditionFlagsAlt: ['fast_10_tevet'],
  },
  {
    section: 18,
    segmentId: 'ssy_em_extra_day_after_yk',
    psalmId: 'Tehillim 85',
    conditionFlags: ['day_after_yom_kippur'],
  },
  {
    section: 20,
    segmentId: 'ssy_em_extra_chanukah',
    psalmId: 'Tehillim 30',
    conditionFlags: ['chanukah'],
  },
  {
    section: 22,
    segmentId: 'ssy_em_extra_esther_purim',
    psalmId: 'Tehillim 22',
    conditionFlags: ['fast_esther'],
    conditionFlagsAlt: ['purim'],
  },
  {
    section: 24,
    segmentId: 'ssy_em_extra_17_tammuz',
    psalmId: 'Tehillim 79',
    conditionFlags: ['fast_17_tammuz'],
  },
];

(async () => {
  const manifest = readJson(MANIFEST_PATH);
  const newEntries = [];

  for (const src of SOURCES) {
    process.stdout.write(`  fetching §${src.section} (${src.psalmId}) ... `);
    const ref = `Siddur_Edot_HaMizrach,_Weekday_Shacharit,_Song_of_the_Day.${src.section}`;
    const raw = await fetchSefaria(ref);
    if (typeof raw !== 'string') {
      console.log('SKIPPED (unexpected structure)');
      continue;
    }
    const lines = splitToLines(raw);
    const filePath = path.join(NUSACH_DIR, `${src.segmentId}.json`);
    writeJson(filePath, {
      id: src.segmentId,
      sections: [{ text: lines, condition_flags: [], exclude_flags: [] }],
    });
    manifest.nusach.edot_mizrach[src.segmentId] = rel(filePath);
    console.log(`${lines.length} lines, ${rel(filePath)}`);

    // For segments triggered by either of two flags, emit two template
    // entries (one per flag). The assembler's section logic is AND-of
    // condition_flags within a single entry, so OR requires duplicates.
    const flagSets = src.conditionFlagsAlt
      ? [src.conditionFlags, src.conditionFlagsAlt]
      : [src.conditionFlags];
    for (const flags of flagSets) {
      newEntries.push({
        segment_id: src.segmentId,
        condition_flags: flags,
        exclude_flags: ['hallel_with_musaf'],
        optional: false,
        allowed_nusach: ['edot_mizrach'],
      });
    }
  }

  // ── Patch sof_hatfila_edot_mizrach: insert between shir_shel_yom and
  // the closing kaddish_yatom. ────────────────────────────────────────────────
  const tplPath = path.join(
    ASSETS, 'templates', 'shacharit', 'sof_hatfila_edot_mizrach.json',
  );
  const tpl = readJson(tplPath);
  if (tpl.segments.some((s) => s.segment_id && s.segment_id.startsWith('ssy_em_extra_'))) {
    console.log(`  ${rel(tplPath)}: already patched`);
  } else {
    const idx = tpl.segments.findIndex(
      (s) => s.sub_template_id === 'shir_shel_yom',
    );
    if (idx < 0) throw new Error('shir_shel_yom segment not found in EM sof_hatfila');
    tpl.segments.splice(idx + 1, 0, ...newEntries);
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted ${newEntries.length} EM SSY-extra entries at idx ${idx + 1}`);
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
