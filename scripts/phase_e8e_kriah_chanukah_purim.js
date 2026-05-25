// Phase E.8e — Chanukah + Purim Torah readings + RC Tevet composite.
//
// CHANUKAH (Bamidbar 7 — nesi'im):
//   8 day-specific readings. Each day reads the nasi of that tribe.
//   Source: Siddur Sefard, Chanukah, Torah Reading (22 items).
//   Item layout: page-header, dinim, dinim-text, then for each of 8 days:
//     [header, intro/explanation, body].
//   Day bodies start at items 5, 8, 10, 12, 14, 16, 18, 21.
//   Bodies for days 2-8 begin with literal "כהן / שלישי" — preserved as
//   a bold marker indicating both Kohen and the 3rd oleh read this block.
//   Inline `:לוי` and `:שלישי` markers split olim within each body.
//
// PURIM (Shemot 17:8-16 — וַיָּבֹא עֲמָלֵק):
//   Single static reading. Source: Siddur Sefard, Purim, Torah Reading
//   (item 1). Inline `:לוי` / `:ישראל` markers split the 3 olim.
//
// RC TEVET COMPOSITE (deferred to E.8e3 — post-processor):
//   On RC Tevet (always during Chanukah), the reading combines RC olim
//   1-3 + Chanukah day-N oleh 4. Calendar flag `rc_tevet` is already
//   emitted. This phase just writes the data; the post-processor that
//   stitches RC + Chanukah-day-N will be added in E.8e3.
//
// Run from project root:  node scripts/phase_e8e_kriah_chanukah_purim.js

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

const ALIYAH_WORDS = ['שני', 'שלישי', 'רביעי', 'לוי', 'ישראל'];
const ALIYAH_RE = new RegExp(
  `:(${ALIYAH_WORDS.join('|')})(?=[\\u05D0-\\u05EA])`,
  'g',
);

function splitWithMarkers(raw) {
  let s = cleanHebrew(raw);
  // Sefaria Chanukah days 2-8 prefix the body with "כהן / שלישי" (no
  // surrounding whitespace). Promote that prefix to its own bold marker
  // line at the very beginning.
  s = s.replace(/^כהן\s*\/\s*שלישי/, '‹‹MARK=כהן / שלישי›› ');
  s = s.replace(ALIYAH_RE, (_, w) => `: ‹‹MARK=${w}››`);
  const parts = s.split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
  // Sentinel may also appear at the START of the very first part (no
  // preceding colon-split). Handle that.
  if (parts.length > 0 && parts[0].startsWith('‹‹MARK=')) {
    const m = parts[0].match(/^‹‹MARK=(.+?)››\s*(.*)$/);
    if (m) {
      parts.splice(0, 1, `‹‹MARK=${m[1]}››`, m[2] ?? '');
    }
  }
  const out = [];
  for (const p of parts) {
    const trimmed = p.trim();
    if (!trimmed) continue;
    const m = trimmed.match(/^‹‹MARK=(.+?)››\s*(.*)$/);
    if (m) {
      out.push(`<b>— ${m[1]} —</b>`);
      if (m[2].trim()) out.push(m[2].trim());
    } else {
      out.push(trimmed);
    }
  }
  return out;
}

(async () => {
  const manifest = readJson(MANIFEST_PATH);

  // ── CHANUKAH (8 days) ─────────────────────────────────────────────────────
  process.stdout.write('  fetching Chanukah ... ');
  const chText = await fetchSefaria('Siddur_Sefard,_Chanukah,_Torah_Reading');
  if (!Array.isArray(chText)) throw new Error('expected array');
  console.log(`${chText.length} entries`);

  // Day body indices (from inspection of the source):
  const CHANUKAH_BODY_INDICES = [5, 8, 10, 12, 14, 16, 18, 21];
  for (let day = 1; day <= 8; day++) {
    const body = String(chText[CHANUKAH_BODY_INDICES[day - 1]] ?? '').trim();
    if (!body) { console.warn(`  ⚠ no body for Chanukah day ${day}`); continue; }
    const lines = splitWithMarkers(body);
    const segmentId = `kriah_chanukah_day_${day}`;
    const filePath = path.join(READING_DIR, `${segmentId}.json`);
    writeJson(filePath, {
      id: segmentId,
      sections: [{ text: lines, condition_flags: [], exclude_flags: [] }],
    });
    manifest.common[segmentId] = rel(filePath);
    console.log(`  ${segmentId}: ${lines.length} lines`);
  }

  // ── PURIM (single reading) ────────────────────────────────────────────────
  process.stdout.write('  fetching Purim ... ');
  const puText = await fetchSefaria('Siddur_Sefard,_Purim,_Torah_Reading');
  if (!Array.isArray(puText)) throw new Error('expected array');
  console.log(`${puText.length} entries`);
  const purimBody = String(puText[1] ?? '').trim();
  const purimLines = splitWithMarkers(purimBody);
  const purimPath = path.join(READING_DIR, 'kriah_purim.json');
  writeJson(purimPath, {
    id: 'kriah_purim',
    sections: [{ text: purimLines, condition_flags: [], exclude_flags: [] }],
  });
  manifest.common['kriah_purim'] = rel(purimPath);
  console.log(`  kriah_purim: ${purimLines.length} lines`);

  // ── Templates ────────────────────────────────────────────────────────────
  // Strip prior kriah_chanukah_* / kriah_purim entries (idempotent),
  // then insert fresh. Position: after the last kriah_* entry (joining
  // the existing CHM/RC block).
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tplPath = path.join(
      ASSETS, 'templates', 'shacharit', `acharei_amidah_${nusach}.json`,
    );
    const tpl = readJson(tplPath);
    tpl.segments = tpl.segments.filter(
      (s) =>
        !(s.segment_id &&
          (s.segment_id.startsWith('kriah_chanukah_') ||
           s.segment_id === 'kriah_purim')),
    );
    // Anchor: AFTER the last kriah_* reading entry (so we land right
    // before the chatzi_kaddish that follows).
    let lastIdx = -1;
    for (let i = 0; i < tpl.segments.length; i++) {
      const id = tpl.segments[i].segment_id;
      if (id && id.startsWith('kriah_')) lastIdx = i;
    }
    // Fallback to kriat_hatorah_reading_text if no kriah_*.
    if (lastIdx < 0) {
      lastIdx = tpl.segments.findIndex(
        (s) => s.segment_id === 'kriat_hatorah_reading_text',
      );
    }
    if (lastIdx < 0) {
      console.log(`  ${rel(tplPath)}: no anchor`);
      continue;
    }

    const newEntries = [];
    for (let day = 1; day <= 8; day++) {
      newEntries.push({
        segment_id: `kriah_chanukah_day_${day}`,
        condition_flags: [
          `chanukah_day_${day}`,
          'kriat_hatorah_chanukah',
          'with_minyan',
        ],
        exclude_flags: [],
        optional: false,
        allowed_nusach: [],
      });
    }
    newEntries.push({
      segment_id: 'kriah_purim',
      condition_flags: ['kriat_hatorah_purim', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    tpl.segments.splice(lastIdx + 1, 0, ...newEntries);
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted ${newEntries.length} Chanukah/Purim entries at idx ${lastIdx + 1}`);
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
