// Batch D.12 follow-up — Chazarat HaShatz Musaf.
//
// Builds the full chazan's repetition of the Musaf amidah:
//   • Per-nusach `kedushah_musaf` segment (different opening + structure):
//       Ashkenaz : "Nekadesh" (same opening as shacharit; per Sefaria the
//                  Na'aritzach variant is reserved for Yom Tov / Hoshana
//                  Raba and is NOT used on RC or Chol HaMoed)
//       Sfard    : "Keter Yitnu Lecha" — uniquely Sfard/Sephardi Musaf
//       EM       : "Keter Yitnu Lecha" (slightly different wording from Sfard)
//     Sfard + Ashk close the kedushah block with the "Ledor Vador" chazan
//     line; EM goes straight from the verses to the "Atah Kadosh" chatima
//     (handled by the standard amidah_kedushah_hashem segment).
//   • Rewrite `templates/musaf/chazarat_hashatz_musaf.json` to sequence the
//     full repetition: Avot → Gevurot → Kedushah Musaf → Kedushat HaShem →
//     middle bracha (RC/CHM-Pesach/CHM-Sukkot) → Retzeh → Modim + Modim
//     Derabbanan → Birkat Kohanim (with-kohanim) OR Elokeinu V'elohei
//     Avoteinu (without) → Shalom → Concluding passage.
//
// Sources reused:
//   _ash_musaf_rc_kedushah.json — Ashk Nekadesh + Ledor Vador
//   _sef_musaf_rc.json          — Sfard Keter + Ledor Vador (entries 9–10)
//   _em_musaf_rc.json           — EM Keter (entry 7)
//
// Run from project root:  node scripts/phase_d12_chazara.js

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
    .replace(/&[a-z]+;/gi, ' ')
    .replace(/[׀]/g, '')
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

function load(file) {
  return flat(readJson(path.join(PROJECT, file)).versions[0].text).map(clean);
}
const manifest = readJson(MANIFEST_PATH);

// ─── Build kedushah_musaf per nusach ───────────────────────────────────────

// Ashkenaz — "Nekadesh" structure (matches shacharit shape but in Musaf
// context with Ledor Vador). Source: _ash_musaf_rc_kedushah.json entries
// [1..6, 8]. Strips chazan/kahal cue labels which the printed source
// occasionally prefixes ("לש"ץ -", "קו"ח -", etc).
{
  const src = load('_ash_musaf_rc_kedushah.json');
  const stripCues = (s) => s
    .replace(/^(לש"ץ|קו"ח|חזן|חזן ש"ץ|הקהל|קהל|הש"ץ)\s*[-:–]\s*/gm, '')
    .trim();
  const parts = [
    src[1],   // נקדש את שמך
    src[2],   // קדוש קדוש קדוש
    src[3],   // לעומתם ברוך יאמרו
    src[4],   // ברוך כבוד ה'
    src[5],   // ובדברי קדשך
    src[6],   // ימלוך ה' לעולם
    stripCues(src[8]), // לדור ודור (Ledor Vador) — strip the "לש"ץ -" prefix
  ].filter(Boolean);
  const text = parts.join(' ');
  const dst = path.join(ASSETS, 'musaf', 'amidah', 'nusach', 'ashkenaz', 'kedushah_musaf.json');
  writeJson(dst, {
    id: 'kedushah_musaf',
    sections: parts.map((p) => ({
      text: (() => { const a = splitToArray(stripCues(p)); return a.length === 1 ? a[0] : a; })(),
      condition_flags: [], exclude_flags: [],
    })),
  });
  manifest.nusach.ashkenaz.kedushah_musaf = rel(dst);
  console.log(`  ashkenaz kedushah_musaf: ${rel(dst)} (${parts.length} sections, ${text.length} chars)`);
}

// Sfard — "Keter Yitnu Lecha" + Ledor Vador.
// Source: _sef_musaf_rc.json [9] (Keter) + [10] (Ledor Vador).
{
  const src = load('_sef_musaf_rc.json');
  const stripCues = (s) => s.replace(/(קו"ח|חזן|הקהל|קהל)\s*[:\-]\s*/g, '').trim();
  const sections = [
    stripCues(src[9]),
    stripCues(src[10]),
  ];
  const dst = path.join(ASSETS, 'musaf', 'amidah', 'nusach', 'sfard', 'kedushah_musaf.json');
  writeJson(dst, {
    id: 'kedushah_musaf',
    sections: sections.map((p) => ({
      text: (() => { const a = splitToArray(p); return a.length === 1 ? a[0] : a; })(),
      condition_flags: [], exclude_flags: [],
    })),
  });
  manifest.nusach.sfard.kedushah_musaf = rel(dst);
  const text = sections.join(' ');
  console.log(`  sfard kedushah_musaf: ${rel(dst)} (${sections.length} sections, ${text.length} chars)`);
}

// Edot HaMizrach — Keter only (no Ledor Vador in EM Musaf kedushah).
// Source: _em_musaf_rc.json [7].
{
  const src = load('_em_musaf_rc.json');
  const sections = [src[7]];
  const dst = path.join(ASSETS, 'musaf', 'amidah', 'nusach', 'edot_mizrach', 'kedushah_musaf.json');
  writeJson(dst, {
    id: 'kedushah_musaf',
    sections: sections.map((p) => ({
      text: (() => { const a = splitToArray(p); return a.length === 1 ? a[0] : a; })(),
      condition_flags: [], exclude_flags: [],
    })),
  });
  manifest.nusach.edot_mizrach.kedushah_musaf = rel(dst);
  const text = sections.join(' ');
  console.log(`  edot_mizrach kedushah_musaf: ${rel(dst)} (${sections.length} sections, ${text.length} chars)`);
}

// ─── Rewrite chazarat_hashatz_musaf template ──────────────────────────────
function entry(opts) {
  return {
    ...(opts.segmentId ? { segment_id: opts.segmentId } : {}),
    ...(opts.subTemplateId ? { sub_template_id: opts.subTemplateId } : {}),
    condition_flags: opts.condition_flags || [],
    exclude_flags: opts.exclude_flags || [],
    ...(opts.optional ? { optional: true } : {}),
  };
}

{
  const dst = path.join(PROJECT, 'assets', 'prayers', 'templates', 'musaf', 'chazarat_hashatz_musaf.json');
  writeJson(dst, {
    id: 'chazarat_hashatz_musaf',
    name: 'חזרת הש״ץ — מוסף',
    segments: [
      entry({ segmentId: 'amidah_intro' }),
      entry({ segmentId: 'amidah_avot' }),
      entry({ segmentId: 'amidah_gevurot' }),
      // Kedushah block (chazara-only insertion between Gevurot and the
      // Kedushat HaShem bracha's chatima).
      entry({ segmentId: 'kedushah_musaf' }),
      entry({ segmentId: 'amidah_kedushah_hashem' }),
      // Middle bracha — same per-chag content as the silent amida.
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
      // Closing 3 brachot, with Modim Derabbanan said by congregation while
      // chazan recites Modim, and Birkat Kohanim (or its fallback) before
      // Sim Shalom.
      entry({ segmentId: 'amidah_retzeh' }),
      entry({ segmentId: 'amidah_modim' }),
      entry({ segmentId: 'modim_derabanan' }),
      entry({ segmentId: 'birkat_kohanim', condition_flags: ['kohanim'] }),
      entry({
        segmentId: 'elokeinu_velohei_avoteinu',
        exclude_flags: ['kohanim'],
      }),
      entry({ segmentId: 'amidah_shalom' }),
      entry({ segmentId: 'amidah_conclusion' }),
    ],
  });
  console.log(`  ${rel(dst)} (full Musaf chazara, ${15} segments)`);
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
