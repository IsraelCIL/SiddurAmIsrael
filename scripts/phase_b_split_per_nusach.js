// Batch A.8 + A.9: split per-nusach for two segments that currently live in
// common but actually differ between nusachim.
//
//   A.8  el_erech_apayim — currently first section of common
//        kriat_hatorah_hotzaah.json (exclude_flag: skip_tachanun).
//        New per-nusach segment; remove that section from the common file.
//        EM also has a "יהי ה' אלהינו" replacement said on days WITHOUT
//        Tachanun — bundle it as a second section in the EM file under
//        condition_flag: skip_tachanun.
//
//   A.9  maariv_aravim — currently common (Ashkenaz). Sefaria's Sfard text
//        is byte-identical to Ashkenaz (verified via matchable-compare).
//        EM differs (495 vs 533 chars). Write per-nusach files.
//
// Sources are read from the Sefaria caches fetched earlier into the project
// root (_ash_el_erech.json, _sef_torah_reading_full.json, _em_torah_reading_full.json,
// _ash_maariv_aravim.json, _sef_maariv_aravim.json, _em_arvit_shema_full.json).
//
// Run from project root:  node scripts/phase_b_split_per_nusach.js

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
    .replace(/[֑-֯]/g, '')        // strip cantillation
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

// ─── A.8  el_erech_apayim per-nusach ───────────────────────────────────────
console.log('=== A.8 el_erech_apayim per-nusach ===');
{
  const ashText = loadEntry('_ash_el_erech.json', 0);
  const sefText = loadEntry('_sef_torah_reading_full.json', 1);
  const emWith = loadEntry('_em_torah_reading_full.json', 2);
  const emWithout = loadEntry('_em_torah_reading_full.json', 5);

  const targets = {
    ashkenaz: {
      sections: [sec(ashText, [], ['skip_tachanun'])],
    },
    sfard: {
      sections: [sec(sefText, [], ['skip_tachanun'])],
    },
    edot_mizrach: {
      sections: [
        sec(emWith, [], ['skip_tachanun']),
        sec(emWithout, ['skip_tachanun'], []),
      ],
    },
  };

  for (const nusach of Object.keys(targets)) {
    const obj = { id: 'el_erech_apayim', sections: targets[nusach].sections };
    const dst = path.join(
      ASSETS,
      'shacharit/acharei_amidah/nusach',
      nusach,
      'el_erech_apayim.json',
    );
    writeJson(dst, obj);
    manifest.nusach[nusach].el_erech_apayim = rel(dst);
    const maxLen = obj.sections
      .flatMap((s) => (Array.isArray(s.text) ? s.text : [s.text]))
      .reduce((m, l) => Math.max(m, l.length), 0);
    console.log(`  ${nusach}: ${obj.sections.length} section(s), maxLine=${maxLen}`);
  }

  // Remove the el_erech section from common kriat_hatorah_hotzaah.json.
  const commonHotzaahPath = path.join(PROJECT, manifest.common.kriat_hatorah_hotzaah);
  const hotzaah = readJson(commonHotzaahPath);
  const before = hotzaah.sections.length;
  hotzaah.sections = hotzaah.sections.filter((s) => {
    const flat = Array.isArray(s.text) ? s.text.join(' ') : s.text;
    // Heuristic: the el_erech section starts with "אֵל אֶרֶךְ אַפַּיִם".
    return !/אֵל\s*אֶ?ר?ֶ?ךְ?\s*אַפַּ?ֽ?יִם/.test(flat);
  });
  writeJson(commonHotzaahPath, hotzaah);
  console.log(`  ${rel(commonHotzaahPath)}: sections ${before} → ${hotzaah.sections.length}`);

  // Add el_erech_apayim entry to each shacharit template, right before
  // kriat_hatorah_hotzaah.
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tp = path.join(PROJECT, manifest.templates[`shacharit_${nusach}`]);
    const data = readJson(tp);
    const idx = data.segments.findIndex((s) => s.segment_id === 'kriat_hatorah_hotzaah');
    if (idx < 0) {
      console.log(`  ! shacharit_${nusach}: kriat_hatorah_hotzaah entry not found`);
      continue;
    }
    if (data.segments.some((s) => s.segment_id === 'el_erech_apayim')) {
      console.log(`  shacharit_${nusach}: already has el_erech_apayim`);
      continue;
    }
    // Inherit kriat_hatorah condition from neighbouring hotzaah entry.
    const hotzaahEntry = data.segments[idx];
    data.segments.splice(idx, 0, {
      segment_id: 'el_erech_apayim',
      condition_flags: hotzaahEntry.condition_flags.slice(),
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    writeJson(tp, data);
    console.log(`  shacharit_${nusach}: inserted el_erech_apayim at position ${idx}`);
  }
}

// ─── A.9  maariv_aravim per-nusach ─────────────────────────────────────────
console.log('\n=== A.9 maariv_aravim per-nusach ===');
{
  const ashText = loadEntry('_ash_maariv_aravim.json', 0);
  const sefText = loadEntry('_sef_maariv_aravim.json', 0);
  const emText = loadEntry('_em_arvit_shema_full.json', 1);

  const texts = { ashkenaz: ashText, sfard: sefText, edot_mizrach: emText };

  for (const nusach of Object.keys(texts)) {
    const obj = {
      id: 'maariv_aravim',
      sections: [sec(texts[nusach])],
    };
    const dst = path.join(
      ASSETS,
      'maariv/birkot_kriat_shema/nusach',
      nusach,
      'maariv_aravim.json',
    );
    writeJson(dst, obj);
    manifest.nusach[nusach].maariv_aravim = rel(dst);
    const maxLen = obj.sections
      .flatMap((s) => (Array.isArray(s.text) ? s.text : [s.text]))
      .reduce((m, l) => Math.max(m, l.length), 0);
    console.log(`  ${nusach}: maxLine=${maxLen}`);
  }

  // Delete the common version.
  const oldPath = manifest.common.maariv_aravim;
  if (oldPath) {
    const abs = path.join(PROJECT, oldPath);
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
    delete manifest.common.maariv_aravim;
    console.log(`  deleted ${oldPath}`);
  }
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
