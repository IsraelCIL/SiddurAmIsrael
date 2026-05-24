// Batch B fix-ups (user feedback):
//   1. Hotzaah Ashkenaz + Sfard: "ויהי בנסוע הארון ... לעמו ישראל בקדושתו"
//      should come BEFORE "בריך שמיה" — swap section[0] and section[1].
//   2. EM Hotzaah: render the whole quoted block as ONE section, not per
//      pasuk (matches Sefaria entry [6] which is a single paragraph).
//   3. EM Hachnasah: replace the placeholder ("ה' עוז לעמו...") with the
//      authentic EM text from Sefaria Siddur Edot HaMizrach Uva LeSion
//      entry [9] — Yehallelu + the pesukim through Hashivenu.
//   4. Move three "post-Torah" segments (beit_yaakov, tefila_ledavid_ps86,
//      shir_hamaalot_lulei) from shacharit/acharei_amidah/ to
//      shacharit/sof_hatfila/ — they are recited after Hachnasah, in the
//      same flow as shir_shel_yom / pitum_haketoreh / ein_keloheinu.
//
// Run from project root:  node scripts/phase_b_fixups.js

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
    .replace(/<[^>]+>/g, '')
    .replace(/[֑-֯]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}
function loadEntry(cacheFile, idx) {
  const d = readJson(path.join(PROJECT, cacheFile));
  return flat(d.versions[0].text).map(clean)[idx];
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
      parts.push(buf.trim());
      buf = '';
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
function sec(text, conditionFlags = [], excludeFlags = []) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: conditionFlags,
    exclude_flags: excludeFlags,
  };
}

const manifest = readJson(MANIFEST_PATH);

// ─── 1. Hotzaah Ashk/Sfard — swap Brich Shmei ↔ Vayehi BiNso'a ──────────────
console.log('=== 1. swap Brich Shmei ↔ Vayehi BiNso\'a (Ash + Sfard) ===');
for (const nusach of ['ashkenaz', 'sfard']) {
  const p = path.join(PROJECT, manifest.nusach[nusach].kriat_hatorah_hotzaah);
  const data = readJson(p);
  // Current order: [0] Brich Shmei, [1] Vayehi BiNso'a → swap.
  const tmp = data.sections[0];
  data.sections[0] = data.sections[1];
  data.sections[1] = tmp;
  writeJson(p, data);
  console.log(`  ${nusach}: swapped`);
}

// ─── 2. EM Hotzaah — collapse to single section ─────────────────────────────
console.log('\n=== 2. EM Hotzaah single block ===');
{
  const emText = loadEntry('_em_torah_reading_full.json', 6)
    .replace(/^שמוציאים ספר תורה אומרים\s*/, '');
  const dst = path.join(PROJECT, manifest.nusach.edot_mizrach.kriat_hatorah_hotzaah);
  const data = {
    id: 'kriat_hatorah_hotzaah',
    sections: [
      {
        text: ['שמוציאים ספר תורה אומרים:'],
        condition_flags: [],
        exclude_flags: [],
      },
      sec(emText),
    ],
  };
  writeJson(dst, data);
  console.log(`  ${rel(dst)}: ${data.sections.length} sections`);
}

// ─── 3. EM Hachnasah — proper text from Uva LeSion entry [9] ────────────────
console.log('\n=== 3. EM Hachnasah from Uva LeSion entry [9] ===');
{
  const emHachnasahText = loadEntry('_em_uva_lesion_full.json', 9);
  const dst = path.join(PROJECT, manifest.nusach.edot_mizrach.kriat_hatorah_hachnasah);
  const data = {
    id: 'kriat_hatorah_hachnasah',
    sections: [
      {
        text: ['ומחזירין את ספר התורה למקומו ואומרים:'],
        condition_flags: [],
        exclude_flags: [],
      },
      sec(emHachnasahText),
    ],
  };
  writeJson(dst, data);
  console.log(`  ${rel(dst)}: ${data.sections.length} sections`);
}

// ─── 4. Move 3 segments → sof_hatfila ──────────────────────────────────────
console.log('\n=== 4. Move post-Torah segments to sof_hatfila ===');
const moves = [
  // [scope, segment_id]
  ['nusach.edot_mizrach', 'beit_yaakov'],
  ['nusach.edot_mizrach', 'tefila_ledavid_ps86'],
  ['common',              'shir_hamaalot_lulei'],
];

for (const [scope, segId] of moves) {
  const [bucket, sub] = scope.split('.');
  const oldPath = bucket === 'nusach' ? manifest.nusach[sub][segId] : manifest.common[segId];
  if (!oldPath) {
    console.log(`  ! ${scope}/${segId}: not found in manifest`);
    continue;
  }
  const oldAbs = path.join(PROJECT, oldPath);
  // Replace the category prefix from acharei_amidah → sof_hatfila.
  const newRel = oldPath.replace(
    /assets\/prayers\/shacharit\/acharei_amidah\//,
    'assets/prayers/shacharit/sof_hatfila/',
  );
  const newAbs = path.join(PROJECT, newRel);
  fs.mkdirSync(path.dirname(newAbs), { recursive: true });
  fs.renameSync(oldAbs, newAbs);

  if (bucket === 'nusach') {
    manifest.nusach[sub][segId] = newRel;
  } else {
    manifest.common[segId] = newRel;
  }
  console.log(`  ${segId}: ${oldPath} → ${newRel}`);
}

// ─── Write manifest ────────────────────────────────────────────────────────
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(
  MANIFEST_PATH,
  JSON.stringify(sortKeys(manifest), null, 2) + '\n',
  'utf8',
);

console.log('\nDONE.');
