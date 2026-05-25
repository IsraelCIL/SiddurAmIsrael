// Batch E.1 — Chazarat HaShatz for Mincha.
//
// Creates `templates/chazarat_hashatz_mincha.json` as a near-copy of the
// existing shacharit chazara, with one structural change:
//   • Birkat Kohanim: condition_flags ['kohanim', 'fast_day'] — only said
//     at Mincha on public fast days (Tisha B'Av Mincha + Yom Kippur Mincha).
//   • elokeinu_velohei_avoteinu fallback: condition_flags ['fast_day'] +
//     exclude_flags ['kohanim'] — only fires on fast Mincha when no kohanim.
//   • On a regular Mincha day (no fast), neither fires — the chazara goes
//     straight from Modim to Sim Shalom, matching standard practice.
//
// Also updates `templates/mincha.json` so segment[6] now references the new
// `chazarat_hashatz_mincha` sub-template instead of the shacharit-shaped one.
//
// Run from project root:  node scripts/phase_e1_chazara_mincha.js

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

const manifest = readJson(MANIFEST_PATH);

// Load the existing shacharit chazara as a baseline.
const shacharitPath = path.join(PROJECT, manifest.templates['chazarat_hashatz']);
const baseline = readJson(shacharitPath);

// Build the Mincha version: same segments, but rewrite the BK + fallback
// gating, and drop `anenu_shliach_tzibur` (which is shacharit-only? no, it
// actually applies to Mincha too on fast days — keep it).
const newSegments = baseline.segments.map((s) => {
  const copy = JSON.parse(JSON.stringify(s));
  if (copy.segment_id === 'birkat_kohanim') {
    copy.condition_flags = ['kohanim', 'fast_day'];
    copy.exclude_flags = [];
  }
  if (copy.segment_id === 'elokeinu_velohei_avoteinu') {
    copy.condition_flags = ['fast_day'];
    copy.exclude_flags = ['kohanim'];
  }
  return copy;
});

const dst = path.join(PROJECT, 'assets', 'prayers', 'templates', 'chazarat_hashatz_mincha.json');
writeJson(dst, {
  id: 'chazarat_hashatz_mincha',
  name: 'חזרת הש״ץ — מנחה',
  segments: newSegments,
});
manifest.templates['chazarat_hashatz_mincha'] = rel(dst);
console.log(`  ${rel(dst)} (${newSegments.length} segments)`);

// Update mincha.json to reference the new sub-template.
const minchaPath = path.join(PROJECT, manifest.templates['mincha']);
const mincha = readJson(minchaPath);
let patched = 0;
for (const s of mincha.segments) {
  if (s.sub_template_id === 'chazarat_hashatz') {
    s.sub_template_id = 'chazarat_hashatz_mincha';
    patched++;
  }
}
writeJson(minchaPath, mincha);
console.log(`  ${rel(minchaPath)}: ${patched} entry rewired to chazarat_hashatz_mincha`);

function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');
console.log('\nDONE.');
