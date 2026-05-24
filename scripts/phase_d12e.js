// Batch D.12e — Musaf middle bracha (Kedushat HaYom) for Rosh Chodesh.
//
// One segment per nusach: `amidah_musaf_intermediate_rc.json`.
// Referenced by `templates/musaf/amidah_musaf.json` with
//   condition_flags: ['rosh_chodesh'].
//
// Extracted from Sefaria sources (cached in project root):
//   Ashkenaz : _ash_musaf_rc.json — whole file = middle bracha (6 entries)
//   Sfard    : _sef_musaf_rc.json — entries [12..15] (after Kedushah, before Retzeh)
//   EM       : _em_musaf_rc.json  — entries [9..12]  (after Kedushah, before Retzeh)
//
// Run from project root:  node scripts/phase_d12e.js

const fs = require('fs');
const path = require('path');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}
function flat(x) { return Array.isArray(x) ? x.flatMap(flat) : [x]; }
function clean(s) {
  return (s || '')
    .replace(/&[a-z]+;/gi, ' ')
    .replace(/<[^>]+>/g, '')
    .replace(/[֑-֯]/g, '')
    .replace(/[׀]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}
function splitToArray(text, maxLen = 75) {
  const t = text.replace(/\s+/g, ' ').trim();
  if (t.length <= maxLen) return [t];
  const parts = [];
  let buf = '';
  for (let i = 0; i < t.length; i++) {
    buf += t[i];
    const ch = t[i], next = t[i + 1];
    if ((ch === ':' || ch === '.' || ch === ',' || ch === '׃') && (next === ' ' || next === undefined)) {
      parts.push(buf.trim()); buf = '';
    }
  }
  if (buf.trim()) parts.push(buf.trim());
  const small = [];
  for (const p of parts) {
    if (p.length <= maxLen) { small.push(p); continue; }
    const words = p.split(' ');
    let cur = '';
    for (const w of words) {
      if (cur.length === 0) { cur = w; continue; }
      if ((cur + ' ' + w).length <= maxLen) cur += ' ' + w;
      else { small.push(cur); cur = w; }
    }
    if (cur) small.push(cur);
  }
  const out = []; let cur = '';
  for (const s of small) {
    if (cur.length === 0) { cur = s; continue; }
    if ((cur + ' ' + s).length <= maxLen) cur += ' ' + s;
    else { out.push(cur); cur = s; }
  }
  if (cur) out.push(cur);
  return out;
}

function loadEntries(file, indices) {
  const d = readJson(path.join(PROJECT, file));
  const all = flat(d.versions[0].text).map(clean);
  return indices.map((i) => all[i]).filter((s) => s && s.length > 0);
}

const manifest = readJson(MANIFEST_PATH);

const sources = {
  ashkenaz: { file: '_ash_musaf_rc.json', indices: [0, 1, 2, 3, 4, 5] },
  sfard:    { file: '_sef_musaf_rc.json', indices: [12, 13, 14, 15] },
  edot_mizrach: { file: '_em_musaf_rc.json', indices: [9, 10, 11, 12] },
};

for (const nusach of Object.keys(sources)) {
  const { file, indices } = sources[nusach];
  const parts = loadEntries(file, indices);
  // Each source entry is a discrete paragraph — keep as separate sections so
  // the reader sees natural paragraph breaks.
  const sections = parts.map((p) => ({
    text: (() => {
      const arr = splitToArray(p);
      return arr.length === 1 ? arr[0] : arr;
    })(),
    condition_flags: [],
    exclude_flags: [],
  }));

  const dst = path.join(
    ASSETS, 'musaf', 'amidah', 'nusach', nusach,
    'amidah_musaf_intermediate_rc.json',
  );
  writeJson(dst, {
    id: 'amidah_musaf_intermediate_rc',
    sections,
  });
  manifest.nusach[nusach].amidah_musaf_intermediate_rc = rel(dst);
  const total = parts.join(' ').length;
  console.log(`  ${nusach}: ${rel(dst)} (${sections.length} sections, ${total} chars)`);
}

// ─── Write manifest ────────────────────────────────────────────────────────
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');
console.log('\nDONE.');
