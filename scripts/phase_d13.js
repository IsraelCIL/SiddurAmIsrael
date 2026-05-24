// Batch D.13 — EM Hotzaat Sefer Torah: insert Brich Shmei before "גדלו"
// on Musaf days. Per user input, EM tradition recites Brich Shmei here
// only on days with Musaf (Rosh Chodesh, Chol HaMoed, Yom Tov, Shabbat).
//
// Strategy:
//   1. Read the current EM kriat_hatorah_hotzaah.json (2 sections: rubric +
//      single block).
//   2. Find the line in the block that starts with "גדלו" and split the
//      block into two sections at that boundary.
//   3. Insert Brich Shmei (text reused from Ashkenaz hotzaah section 1)
//      between them, with condition_flags=['musaf_day'].
//
// Run from project root:  node scripts/phase_d13.js

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

// Source 1: Ashkenaz hotzaah — Brich Shmei is section 1 (after the swap in
// Batch B fixups). It's text contains the full Aramaic Zohar passage.
const ashHotzaah = readJson(path.join(PROJECT, manifest.nusach.ashkenaz.kriat_hatorah_hotzaah));
// section 0 (after swap) is Vayehi BiNso'a; section 1 is Brich Shmei.
// Find by content: the Brich Shmei section starts with "בְּרִיךְ שְׁמֵהּ".
const brichShmeiSection = ashHotzaah.sections.find((s) => {
  const t = Array.isArray(s.text) ? s.text.join(' ') : s.text;
  return /בְּרִיךְ\s*שְׁמֵהּ/.test(t);
});
if (!brichShmeiSection) throw new Error('Could not find Brich Shmei in Ashkenaz hotzaah');

// Patch EM hotzaah.
const emPath = path.join(PROJECT, manifest.nusach.edot_mizrach.kriat_hatorah_hotzaah);
const emData = readJson(emPath);

// Find the block section (long one with all the pesukim). Strip niqqud
// before regex to avoid having to match Unicode combining marks exactly.
const stripNiqqud = (s) => s.replace(/[֑-ֽֿ-ׇ]/g, '');
const blockIdx = emData.sections.findIndex((s) => {
  const t = Array.isArray(s.text) ? s.text.join(' ') : s.text;
  const bare = stripNiqqud(t);
  return /גדלו/.test(bare) && /ברוך המקום/.test(bare);
});
if (blockIdx < 0) throw new Error('Could not find EM Hotzaah block containing both ברוך המקום and גדלו');

const block = emData.sections[blockIdx];
const lines = Array.isArray(block.text) ? block.text : [block.text];

// Find the line that starts with "גדלו".
const splitAt = lines.findIndex((line) => /^\s*גדלו/.test(stripNiqqud(line)));
if (splitAt < 0) throw new Error('Could not find "גדלו" line in EM Hotzaah block');

const beforeLines = lines.slice(0, splitAt);
const afterLines = lines.slice(splitAt);

// Rebuild sections:
//   …rubric…
//   [pre-Gadlu block]            (no flags)
//   Brich Shmei                  (musaf_day)
//   [Gadlu onwards block]        (no flags)
//   …(anything after the block, if any)…
const newSections = [
  ...emData.sections.slice(0, blockIdx),
  { text: beforeLines.length === 1 ? beforeLines[0] : beforeLines, condition_flags: [], exclude_flags: [] },
  {
    text: brichShmeiSection.text,
    condition_flags: ['musaf_day'],
    exclude_flags: [],
  },
  { text: afterLines.length === 1 ? afterLines[0] : afterLines, condition_flags: [], exclude_flags: [] },
  ...emData.sections.slice(blockIdx + 1),
];

writeJson(emPath, { id: emData.id, sections: newSections });
console.log(`  ${rel(emPath)}: ${emData.sections.length} → ${newSections.length} sections`);
console.log(`  split at "${lines[splitAt].substring(0, 30)}..."`);
console.log('DONE.');
