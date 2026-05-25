// Refactor: flat shacharit_*.json templates → modular sub-templates per
// liturgical section. Each main template becomes a short list of
// sub_template_id references; per-section sub-templates hold the actual
// segment ordering.
//
// New sub-templates (per nusach):
//   shacharit_lifnei_hatfila_<nusach>
//   shacharit_pesukei_dezimra_<nusach>
//   shacharit_birkot_kriat_shema_<nusach>
//   shacharit_acharei_amidah_<nusach>
//   shacharit_sof_hatfila_<nusach>
//
// The existing `amidah` and `chazarat_hashatz` sub-templates stay as they
// are and are still referenced directly by the main template.
//
// Section boundaries are hand-mapped per nusach from the current 88/90
// segment layout (verified by visual inspection).
//
// Run from project root:  node scripts/refactor_templates.js

const fs = require('fs');
const path = require('path');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const TEMPLATES_DIR = path.join(ASSETS, 'templates');
const SHACHARIT_SUBDIR = path.join(TEMPLATES_DIR, 'shacharit');

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

const manifest = readJson(MANIFEST_PATH);

// Section boundaries [start, end] inclusive for each nusach.
// Boundaries identified by walking the current flat template (post-Batch C):
//   lifnei_hatfila ends after kaddish_derabanan (post-korbanot)
//   pesukei_dezimra starts at psalm_030/hodu, ends at yishtabach
//   birkot_kriat_shema starts at the chatzi_kaddish after yishtabach, ends at emet_veyatziv
//   amidah and chazarat_hashatz are single sub-template refs (kept as-is)
//   acharei_amidah starts after chazarat_hashatz, ends at kaddish_titkabal (after uva_letzion)
//   sof_hatfila starts at the entry after kaddish_titkabal, ends at end
const BOUNDS = {
  ashkenaz: {
    lifnei_hatfila:      [0, 40],
    pesukei_dezimra:     [41, 55],
    birkot_kriat_shema:  [56, 61],
    amidah_idx:          62,
    chazarat_idx:        63,
    acharei_amidah:      [64, 78],
    sof_hatfila:         [79, 87],
  },
  sfard: {
    lifnei_hatfila:      [0, 40],
    pesukei_dezimra:     [41, 56],
    birkot_kriat_shema:  [57, 62],
    amidah_idx:          63,
    chazarat_idx:        64,
    acharei_amidah:      [65, 79],
    sof_hatfila:         [80, 89],
  },
  edot_mizrach: {
    lifnei_hatfila:      [0, 38],
    pesukei_dezimra:     [39, 55],
    birkot_kriat_shema:  [56, 61],
    amidah_idx:          62,
    chazarat_idx:        63,
    acharei_amidah:      [64, 76],
    sof_hatfila:         [77, 89],
  },
};

const SECTIONS = ['lifnei_hatfila', 'pesukei_dezimra', 'birkot_kriat_shema', 'acharei_amidah', 'sof_hatfila'];

function templateEntry(sub_template_id, condition_flags = []) {
  return {
    sub_template_id,
    condition_flags,
    exclude_flags: [],
    optional: false,
    allowed_nusach: [],
  };
}

for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const mainTplPath = path.join(PROJECT, manifest.templates[`shacharit_${nusach}`]);
  const main = readJson(mainTplPath);
  const segs = main.segments;
  const b = BOUNDS[nusach];

  // Verify boundaries match expected sub-template ids at the marker positions
  // (sanity check).
  const amidahEntry = segs[b.amidah_idx];
  const chazaratEntry = segs[b.chazarat_idx];
  if (amidahEntry.sub_template_id !== 'amidah') {
    throw new Error(`${nusach}: index ${b.amidah_idx} is not amidah sub-template`);
  }
  if (chazaratEntry.sub_template_id !== 'chazarat_hashatz') {
    throw new Error(`${nusach}: index ${b.chazarat_idx} is not chazarat_hashatz sub-template`);
  }

  // Build each per-section sub-template.
  for (const section of SECTIONS) {
    const [start, end] = b[section];
    const sectionSegments = segs.slice(start, end + 1);
    const tplId = `shacharit_${section}_${nusach}`;
    const dst = path.join(SHACHARIT_SUBDIR, `${section}_${nusach}.json`);
    writeJson(dst, {
      id: tplId,
      name: tplId,
      segments: sectionSegments,
    });
    manifest.templates[tplId] = rel(dst);
    console.log(`  ${nusach}/${section}: ${sectionSegments.length} segments → ${rel(dst)}`);
  }

  // Rewrite main template as 7-entry list of sub-template references.
  const newMain = {
    id: `shacharit_${nusach}`,
    name: main.name || 'שחרית',
    segments: [
      templateEntry(`shacharit_lifnei_hatfila_${nusach}`),
      templateEntry(`shacharit_pesukei_dezimra_${nusach}`),
      templateEntry(`shacharit_birkot_kriat_shema_${nusach}`),
      templateEntry('amidah'),
      templateEntry('chazarat_hashatz', ['with_minyan']),
      templateEntry(`shacharit_acharei_amidah_${nusach}`),
      templateEntry(`shacharit_sof_hatfila_${nusach}`),
    ],
  };
  writeJson(mainTplPath, newMain);
  console.log(`  ${nusach} main: rewrote to ${newMain.segments.length} sub-template entries\n`);
}

// Sort + write manifest.
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

console.log('DONE.');
