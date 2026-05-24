// Batch D.9 — Mincha fixes:
//   • Remove `selichot` entry from the mincha template — Selichot are not
//     recited at Mincha (user clarification).
//   • Mark `petihat_eliyahu` in Mincha as optional (accordion).
//   • Create a dedicated `korbanot_mincha` segment for EM Mincha containing
//     the first 9 sections of shacharit korbanot (parshat_hatamid through
//     ana_bekoach — per user spec: "מהקטע שאחרי בשובי את שבותיכם...
//     ועד אחרי אנא בכח"). Update the mincha template to reference this new
//     id instead of `korbanot`, and mark it optional.
//
// Run from project root:  node scripts/phase_d9.js

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

// ─── 1. Build korbanot_mincha from EM shacharit korbanot (sections 0..8) ──
console.log('=== 1. build korbanot_mincha (EM) ===');
{
  const src = path.join(PROJECT, manifest.nusach.edot_mizrach.korbanot);
  const data = readJson(src);
  // Sections 0..8 inclusive: parshat_hatamid → ata_hu → parshat_haketoret
  // → pitum_haketoret → Rabban Shimon → tanya_rabbi_natan → tani bar_kappara
  // → abayei → ana_bekoach.
  const subset = data.sections.slice(0, 9);
  const dst = path.join(
    ASSETS, 'mincha/lifnei_mincha/nusach/edot_mizrach/korbanot_mincha.json'
  );
  writeJson(dst, { id: 'korbanot_mincha', sections: subset });
  manifest.nusach.edot_mizrach.korbanot_mincha = rel(dst);
  console.log(`  ${rel(dst)}: ${subset.length} sections`);
}

// ─── 2. Patch mincha template ──────────────────────────────────────────────
console.log('\n=== 2. patch mincha template ===');
{
  const tp = path.join(PROJECT, manifest.templates.mincha);
  const data = readJson(tp);

  // (a) Drop the selichot entry.
  const before = data.segments.length;
  data.segments = data.segments.filter((s) => s.segment_id !== 'selichot');
  console.log(`  removed selichot: ${before} → ${data.segments.length}`);

  // (b) petihat_eliyahu → optional.
  const pe = data.segments.find((s) => s.segment_id === 'petihat_eliyahu');
  if (pe) {
    pe.optional = true;
    console.log('  petihat_eliyahu marked optional');
  }

  // (c) Replace korbanot entry: change id to korbanot_mincha and mark optional.
  const ko = data.segments.find((s) => s.segment_id === 'korbanot');
  if (ko) {
    ko.segment_id = 'korbanot_mincha';
    ko.optional = true;
    console.log('  korbanot → korbanot_mincha (optional)');
  }

  writeJson(tp, data);
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
