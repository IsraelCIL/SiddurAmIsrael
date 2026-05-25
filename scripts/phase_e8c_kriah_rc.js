// Phase E.8c — Rosh Chodesh Torah reading.
//
// Source: Siddur Sefard, Torah Readings, Torah Reading for Rosh Chodesh
// (Bamidbar 28). Single static reading — 4 olim (Kohen / Levi / Yisrael
// / Revi'i) from Bamidbar 28:1-15.
//
// Key feature: the Levi aliyah begins by REPEATING the verse "וְאָמַרְתָּ
// לָהֶם זֶה הָאִשֶּׁה" that the Kohen read last. Sefaria marks this with
// an inline (whitespace-less) annotation: `:לוי חוזר מ"ואמרת להם"`. We
// detect that annotation and emit it as a stylized bold marker line.
//
// Per user (2026-05-25): "חוזרים על הפסוק השלישי שקרא הכהן" — the
// instruction itself is the marker; the actual repeated text is not
// duplicated in our output (would be redundant). The marker line tells
// the reader to repeat from "ואמרת להם" before continuing.
//
// Run from project root:  node scripts/phase_e8c_kriah_rc.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const READING_DIR = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common', 'torah_reading');

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

// Parses a Sefaria reading body with embedded aliyah markers (no
// whitespace around them) and returns the JSON-array `text` lines with
// <b>...</b> marker rows inserted.
function parseReading(raw) {
  let s = cleanHebrew(raw);

  // Sefaria's RC source duplicates the "Levi repeats from..." annotation,
  // producing `לוי חוזר מ"ואמרת להם"חוזר מ"ואמרת להם"`. Collapse to one
  // copy. Also handle smart-quote / straight-quote variants.
  s = s.replace(
    /לוי\s*חוזר\s*מ["״]([^"״]+)["״]\s*חוזר\s*מ["״][^"״]+["״]/g,
    'לוי חוזר מ"$1"',
  );

  // Standard ordinal aliyah markers (שני / שלישי / רביעי).
  const ALIYAH_WORDS = ['שני', 'שלישי', 'רביעי'];
  const ordinalRe = new RegExp(
    `:(${ALIYAH_WORDS.join('|')})(?=[\\u05D0-\\u05EA])`,
    'g',
  );
  s = s.replace(ordinalRe, (_, w) => `: ‹‹MARK=${w}››`);

  // Levi with explicit "חוזר מ..." annotation: render as the levi marker
  // plus the repeat instruction.
  s = s.replace(
    /:לוי\s*חוזר\s*מ["״]([^"״]+)["״]/g,
    (_, src) => `: ‹‹MARK=לוי (חוזר מ"${src}")››`,
  );

  // Bare לוי (no repeat annotation).
  s = s.replace(/:לוי(?=[א-ת])/g, ': ‹‹MARK=לוי››');

  // Split at sof-pasuk-followed-by-space.
  const parts = s.split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
  const out = [];
  for (const p of parts) {
    const m = p.match(/^‹‹MARK=(.+?)››\s*(.*)$/);
    if (m) {
      out.push(`<b>— ${m[1]} —</b>`);
      if (m[2].trim()) out.push(m[2].trim());
    } else {
      out.push(p);
    }
  }
  return out;
}

(async () => {
  process.stdout.write('  fetching RC Torah reading ... ');
  const text = await fetchSefaria(
    'Siddur_Sefard,_Torah_Readings,_Torah_Reading_for_Rosh_Chodesh.2',
  );
  if (typeof text !== 'string') throw new Error('expected string body');
  const lines = parseReading(text);
  console.log(`${lines.length} lines`);

  const filePath = path.join(READING_DIR, 'kriah_rc.json');
  writeJson(filePath, {
    id: 'kriah_rc',
    sections: [{ text: lines, condition_flags: [], exclude_flags: [] }],
  });

  const manifest = readJson(MANIFEST_PATH);
  manifest.common['kriah_rc'] = rel(filePath);
  console.log(`  wrote ${rel(filePath)}`);

  // ── Insert into templates ────────────────────────────────────────────────
  // Position: immediately after kriat_hatorah_reading_text (the Mon/Thu
  // placeholder), gated on kriat_hatorah_rc + with_minyan. The two gates
  // are mutually exclusive (Mon/Thu vs RC), so at most one fires per day.
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tplPath = path.join(
      ASSETS, 'templates', 'shacharit', `acharei_amidah_${nusach}.json`,
    );
    const tpl = readJson(tplPath);
    if (tpl.segments.some((s) => s.segment_id === 'kriah_rc')) {
      console.log(`  ${rel(tplPath)}: already patched`);
      continue;
    }
    const idx = tpl.segments.findIndex(
      (s) => s.segment_id === 'kriat_hatorah_reading_text',
    );
    if (idx < 0) {
      console.log(`  ${rel(tplPath)}: kriat_hatorah_reading_text anchor not found`);
      continue;
    }
    tpl.segments.splice(idx + 1, 0, {
      segment_id: 'kriah_rc',
      condition_flags: ['kriat_hatorah_rc', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted kriah_rc at idx ${idx + 1}`);
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
