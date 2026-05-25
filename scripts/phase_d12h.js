// Batch D.12h — Barchi Nafshi (Psalm 104) as a shared segment.
//
// Recited by Sfard nusach on Rosh Chodesh between the post-Hallel Kaddish
// Titkabal/Shir Shel Yom and Kriat HaTorah. Same liturgical text in all
// three nusachim (Ashkenazi siddurim include it as an optional addendum on
// RC; Edot HaMizrach prints it less commonly but treats it as the same
// psalm) — so we store it under `common/` and let the template gating decide
// where it appears. The post-Hallel insertion in `acharei_amidah_sfard`
// (`barchi_nafshi [if: hallel_with_musaf, rosh_chodesh]`) is the only call
// site that exists in D.12 scope.
//
// Run from project root:  node scripts/phase_d12h.js

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
    .replace(/&[a-z]+;/gi, ' ')   // strip HTML entities like &thinsp;
    .replace(/<[^>]+>/g, '')
    .replace(/[֑-֯]/g, '')          // strip trope (cantillation)
    .replace(/[׀]/g, '')            // strip paseq
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

const src = readJson(path.join(PROJECT, '_psalm_104.json'));
const verses = flat(src.versions[0].text).map(clean).filter((v) => v.length > 0);
if (verses.length !== 35) {
  console.warn(`  warning: expected 35 verses, got ${verses.length}`);
}
// Liturgically, Psalm 104 ends by repeating its opening phrase: the printed
// custom in Sfard / Ashkenazi siddurim is to read verse 35 in full then echo
// "בָּרְכִי נַפְשִׁי אֶת־יְהֹוָה הַֽלְלוּ־יָֽהּ". The Sefaria text already contains
// "ברכי נפשי את יהוה" at the end of verse 35 (truncated above) — we keep
// what's there and trust the siddur convention.

// Combine into one long string then split into readable chunks.
const joined = verses.join(' ');
const lines = splitToArray(joined);

const dst = path.join(ASSETS, 'maariv', '..', 'shacharit', 'acharei_amidah', 'common', 'barchi_nafshi.json');
// Resolve "..":
const resolved = path.resolve(dst);
writeJson(resolved, {
  id: 'barchi_nafshi',
  sections: [
    {
      text: lines.length === 1 ? lines[0] : lines,
      condition_flags: [],
      exclude_flags: [],
    },
  ],
});

// Update manifest under common (it's a shared psalm, used cross-nusach).
const manifest = readJson(MANIFEST_PATH);
manifest.common['barchi_nafshi'] = rel(resolved);
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');
console.log(`  ${rel(resolved)} (${joined.length} chars, ${lines.length} lines)`);
console.log('DONE.');
