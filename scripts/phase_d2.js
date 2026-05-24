// Batch D.2 — Maariv brachot per-nusach (no shared content except shema).
//
// Two segments need to become per-nusach in Maariv:
//   1. ahavat_olam (Maariv version) — used in maariv all 3 nusachim AND in
//      Sfard/EM shacharit BKS. To avoid touching shacharit (whose ahavat_olam
//      is a separate liturgical text), introduce a NEW segment id
//      `maariv_ahavat_olam` for the maariv references. Shacharit Sfard/EM
//      continue using `ahavat_olam` from shared_global/common (unchanged).
//   2. emet_veemunh — maariv-only segment. Keep the name, make per-nusach,
//      delete the common copy.
//
// Sources (Sefaria, fetched into project root):
//   Ashkenaz: _ash_arvit_2nd_before.json [0]   (ahavat_olam ~436 chars)
//             _ash_arvit_1st_after.json [1..3] (emet_veemunh = main bracha +
//                                                mi chamocha + hashem yimloch)
//   Sfard:    _sef_maariv_shema.json [7]       (ahavat_olam ~445 chars)
//             _sef_maariv_shema.json [21..23]  (emet_veemunh full sequence)
//   EM:       _em_arvit_shema_full.json [2]    (ahavat_olam ~482 chars)
//             _em_arvit_shema_full.json [9]    (emet_veemunh ~1294 chars)
//
// Run from project root:  node scripts/phase_d2.js

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
function loadEntries(cacheFile, indices) {
  const d = readJson(path.join(PROJECT, cacheFile));
  const all = flat(d.versions[0].text).map(clean);
  return indices.map((i) => all[i]).filter(Boolean);
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
function sec(text) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: [],
    exclude_flags: [],
  };
}

const manifest = readJson(MANIFEST_PATH);

// ─── 1. maariv_ahavat_olam (new id) per-nusach ─────────────────────────────
console.log('=== maariv_ahavat_olam per-nusach ===');
{
  const sources = {
    ashkenaz: loadEntries('_ash_arvit_2nd_before.json', [0])[0],
    sfard:    loadEntries('_sef_maariv_shema.json', [7])[0],
    edot_mizrach: loadEntries('_em_arvit_shema_full.json', [2])[0],
  };
  for (const n of Object.keys(sources)) {
    const dst = path.join(
      ASSETS, 'maariv/birkot_kriat_shema/nusach', n, 'maariv_ahavat_olam.json'
    );
    writeJson(dst, {
      id: 'maariv_ahavat_olam',
      sections: [sec(sources[n])],
    });
    manifest.nusach[n].maariv_ahavat_olam = rel(dst);
    console.log(`  ${n}: ${rel(dst)} (${sources[n].length} chars)`);
  }
}

// ─── 2. emet_veemunh per-nusach (concatenate sub-pieces for Ash/Sfard) ─────
console.log('\n=== emet_veemunh per-nusach ===');
{
  // Ashkenaz: main bracha + mi chamocha + hashem yimloch (3 entries)
  const ashParts = loadEntries('_ash_arvit_1st_after.json', [1, 2, 3]);
  const ashText  = ashParts.join(' ');
  // Sfard: same composition
  const sefParts = loadEntries('_sef_maariv_shema.json', [21, 22, 23]);
  const sefText  = sefParts.join(' ');
  // EM: entry 9 already contains the full bracha including mi chamocha
  // through gaal yisrael (1294 chars).
  const emText   = loadEntries('_em_arvit_shema_full.json', [9])[0];

  const sources = { ashkenaz: ashText, sfard: sefText, edot_mizrach: emText };
  for (const n of Object.keys(sources)) {
    const dst = path.join(
      ASSETS, 'maariv/birkot_kriat_shema/nusach', n, 'emet_veemunh.json'
    );
    writeJson(dst, {
      id: 'emet_veemunh',
      sections: [sec(sources[n])],
    });
    manifest.nusach[n].emet_veemunh = rel(dst);
    console.log(`  ${n}: ${rel(dst)} (${sources[n].length} chars)`);
  }

  // Delete common version.
  const oldCommon = manifest.common.emet_veemunh;
  if (oldCommon) {
    const abs = path.join(PROJECT, oldCommon);
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
    delete manifest.common.emet_veemunh;
    console.log(`  deleted ${oldCommon}`);
  }
}

// ─── 3. Update Maariv templates: ahavat_olam → maariv_ahavat_olam ─────────
console.log('\n=== update Maariv templates ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const tp = path.join(PROJECT, manifest.templates[`maariv_${nusach}`]);
  const data = readJson(tp);
  let renamed = 0;
  for (const seg of data.segments) {
    if (seg.segment_id === 'ahavat_olam') {
      seg.segment_id = 'maariv_ahavat_olam';
      renamed++;
    }
  }
  writeJson(tp, data);
  console.log(`  maariv_${nusach}: renamed ${renamed} ahavat_olam → maariv_ahavat_olam`);
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
