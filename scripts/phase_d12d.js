// Batch D.12d — Musaf sub-template skeleton.
//
// Creates the empty structural shell for Musaf, ready to receive the actual
// liturgical content in D.12e (Rosh Chodesh), D.12f (Chol HaMoed Pesach),
// and D.12g (Chol HaMoed Sukkot) — each per nusach.
//
// Files created:
//   • templates/musaf/musaf_<nusach>.json   ← top-level Musaf sub-template,
//       referenced from `shacharit_acharei_amidah_<nusach>` on musaf_content
//       days. Sequences amidah_musaf → chazarat_hashatz_musaf → kaddish_titkabal.
//   • templates/musaf/amidah_musaf.json      ← Musaf Amidah (silent). Opens
//       and closes with the standard 3+3 amidah brachot (shared with weekday
//       amidah); the middle bracha varies by chag and resolves per-nusach via
//       segment_id (gated by rosh_chodesh / chol_hamoed_pesach / chol_hamoed_sukkot).
//   • templates/musaf/chazarat_hashatz_musaf.json  ← placeholder for the
//       chazan's repetition. To be fleshed out alongside the content batches.
//
// Run from project root:  node scripts/phase_d12d.js

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
function entry(opts) {
  return {
    ...(opts.segmentId ? { segment_id: opts.segmentId } : {}),
    ...(opts.subTemplateId ? { sub_template_id: opts.subTemplateId } : {}),
    condition_flags: opts.condition_flags || [],
    exclude_flags: opts.exclude_flags || [],
    ...(opts.optional ? { optional: true } : {}),
  };
}

const manifest = readJson(MANIFEST_PATH);

// ─── amidah_musaf.json (shared) ────────────────────────────────────────────
// Structure: standard 3 opening + 1 middle (variable by chag) + 3 closing
// brachot. Opening and closing brachot reuse the same segment_ids as the
// weekday amidah, resolving per-nusach via the manifest.
{
  const dst = path.join(PROJECT, 'assets', 'prayers', 'templates', 'musaf', 'amidah_musaf.json');
  writeJson(dst, {
    id: 'amidah_musaf',
    name: 'תפילת מוסף',
    segments: [
      entry({ segmentId: 'amidah_intro' }),
      entry({ segmentId: 'amidah_avot' }),
      entry({ segmentId: 'amidah_gevurot' }),
      entry({ segmentId: 'amidah_kedushah_hashem' }),
      // ─── Middle bracha — variable by chag ─────────────────────────────────
      // Each is a per-nusach segment resolved via the manifest. Exactly one
      // of these should fire on any given Musaf-content day.
      entry({
        segmentId: 'amidah_musaf_intermediate_rc',
        condition_flags: ['rosh_chodesh'],
      }),
      entry({
        segmentId: 'amidah_musaf_intermediate_chm_pesach',
        condition_flags: ['chol_hamoed_pesach'],
      }),
      entry({
        segmentId: 'amidah_musaf_intermediate_chm_sukkot',
        condition_flags: ['chol_hamoed_sukkot'],
      }),
      // ─── Closing brachot ─────────────────────────────────────────────────
      entry({ segmentId: 'amidah_retzeh' }),
      entry({ segmentId: 'amidah_modim' }),
      entry({ segmentId: 'amidah_shalom' }),
      entry({ segmentId: 'amidah_conclusion' }),
    ],
  });
  manifest.templates['amidah_musaf'] = rel(dst);
  console.log(`  ${rel(dst)}`);
}

// ─── chazarat_hashatz_musaf.json (placeholder) ─────────────────────────────
// Stub for now — will mirror amidah_musaf with chazan-specific kedushah and
// modim derabbanan once content batches land.
{
  const dst = path.join(
    PROJECT, 'assets', 'prayers', 'templates', 'musaf', 'chazarat_hashatz_musaf.json',
  );
  writeJson(dst, {
    id: 'chazarat_hashatz_musaf',
    name: 'חזרת הש״ץ — מוסף',
    segments: [
      entry({ subTemplateId: 'amidah_musaf' }),
    ],
  });
  manifest.templates['chazarat_hashatz_musaf'] = rel(dst);
  console.log(`  ${rel(dst)} (stub)`);
}

// ─── musaf_<nusach>.json (per-nusach top-level) ────────────────────────────
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const id = `musaf_${nusach}`;
  const dst = path.join(PROJECT, 'assets', 'prayers', 'templates', 'musaf', `${id}.json`);
  writeJson(dst, {
    id,
    name: 'מוסף',
    segments: [
      entry({ subTemplateId: 'amidah_musaf' }),
      entry({ subTemplateId: 'chazarat_hashatz_musaf', condition_flags: ['with_minyan'] }),
      entry({ subTemplateId: 'kaddish_titkabal', condition_flags: ['with_minyan'] }),
    ],
  });
  manifest.templates[id] = rel(dst);
  console.log(`  ${rel(dst)}`);
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
