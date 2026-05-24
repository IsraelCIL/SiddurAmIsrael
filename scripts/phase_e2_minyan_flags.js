// Phase E.2 — Tag every reference to devarim-shebikdushah segments with the
// `with_minyan` condition_flag, so they hide when the user davens b'yechidut.
//
// Targets (per user spec, 2026-05-24):
//   • Kaddish (all forms): kaddish_yatom, kaddish_titkabal, kaddish_derabanan,
//     kaddish_shalem, chatzi_kaddish
//   • Chazarat HaShatz: chazarat_hashatz, chazarat_hashatz_mincha,
//     chazarat_hashatz_musaf (the wrapping condition_flag at the caller level
//     gates Kedushah / BK / Modim deRabbanan inside automatically)
//   • Kriat HaTorah: kriat_hatorah_shacharit, kriat_hatorah_mincha,
//     kriat_hatorah_hotzaah, kriat_hatorah_hachnasah
//   • Barchu (segment_id)
//   • Yud-Gimel Middot in Tachanun: vidui_yud_gimel_midot
//
// Idempotent: scans every template JSON, adds 'with_minyan' to condition_flags
// if a target id appears and the flag is not already present. Leaves other
// entries (and condition_flags ordering for already-flagged entries) untouched.
//
// Run from project root:  node scripts/phase_e2_minyan_flags.js

const fs = require('fs');
const path = require('path');

const PROJECT = path.resolve(__dirname, '..');
const TEMPLATES_DIR = path.join(PROJECT, 'assets', 'prayers', 'templates');

const TARGETS = new Set([
  'kaddish_yatom',
  'kaddish_titkabal',
  'kaddish_derabanan',
  'kaddish_shalem',
  'chatzi_kaddish',
  'chazarat_hashatz',
  'chazarat_hashatz_mincha',
  'chazarat_hashatz_musaf',
  'kriat_hatorah_shacharit',
  'kriat_hatorah_mincha',
  'kriat_hatorah_hotzaah',
  'kriat_hatorah_hachnasah',
  'barchu',
  'vidui_yud_gimel_midot',
]);

function walk(dir, acc = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.isFile() && p.endsWith('.json')) acc.push(p);
  }
  return acc;
}

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }

const stats = { filesTouched: 0, entriesTagged: 0, alreadyTagged: 0 };
const touched = [];

for (const file of walk(TEMPLATES_DIR)) {
  const raw = fs.readFileSync(file, 'utf8');
  const json = JSON.parse(raw);
  if (!Array.isArray(json.segments)) continue;

  let fileChanged = false;
  let perFileTagged = 0;
  for (const s of json.segments) {
    const id = s.segment_id || s.sub_template_id;
    if (!TARGETS.has(id)) continue;

    const cf = Array.isArray(s.condition_flags) ? s.condition_flags : [];
    if (cf.includes('with_minyan')) { stats.alreadyTagged++; continue; }

    s.condition_flags = [...cf, 'with_minyan'];
    stats.entriesTagged++;
    perFileTagged++;
    fileChanged = true;
  }

  if (fileChanged) {
    fs.writeFileSync(file, JSON.stringify(json, null, 2) + '\n', 'utf8');
    stats.filesTouched++;
    touched.push({ file: rel(file), tagged: perFileTagged });
  }
}

console.log('Phase E.2 — with_minyan tagging\n');
for (const t of touched) console.log(`  ${t.file}: +${t.tagged}`);
console.log(`\nFiles touched:    ${stats.filesTouched}`);
console.log(`Entries tagged:   ${stats.entriesTagged}`);
console.log(`Already had flag: ${stats.alreadyTagged}`);
console.log('\nDONE.');
