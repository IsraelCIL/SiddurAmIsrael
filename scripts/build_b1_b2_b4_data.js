// One-shot script for content fixes B1, B2, B4 (data files only).
// B1 = Ahavat Olam (Maariv) per nusach (Sfard, EM)
// B2 = Akeidah Yehi Ratzon (post-parsha) per nusach (Ashkenaz, Sfard, EM)
// B4 = Nachem flag fix in amidah_yerushalayim (all 3 nusachim) + EM TB'A Mincha chatima
//
// All Hebrew text comes from on-disk Sefaria JSON files (already fetched via
// the curl block earlier in this session). No Hebrew text passes through the
// assistant response stream.
//
// Sources on disk:
//   _ash_akedah.json           = Sefaria Ashkenaz, Shacharit Preparatory Prayers, Akedah
//   _sef_morningprayer.json    = Sefaria Sefard, Weekday Shacharit, Morning Prayer
//   _em_morningprayer.json     = Sefaria EM, Weekday Shacharit, Morning Prayer
//   _sef_maariv_shema.json     = Sefaria Sefard, Weekday Maariv, The Shema
//   _em_arvit_shema.json       = Sefaria EM, Weekday Arvit, The Shema
//   _em_minamida.json          = Sefaria EM, Weekday Mincha, Amida (for TB'A chatima)
//
// Existing files we MODIFY (rather than overwrite):
//   nusach/ashkenaz/amidah_yerushalayim.json
//   nusach/sfard/amidah_yerushalayim.json
//   nusach/edot_mizrach/amidah_yerushalayim.json

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';

function stripHtml(t) { return (t || '').replace(/<[^>]+>/g, ''); }
function stripTrope(t) { return t.replace(/[֑-֯]/g, ''); }
function normSpaces(t) { return t.replace(/\s+/g, ' ').trim(); }
function clean(t) { return normSpaces(stripTrope(stripHtml(t))); }
function flatten(x) { return Array.isArray(x) ? x.flatMap(flatten) : [x]; }

function splitToArray(text, maxLen = 75) {
  const t = normSpaces(text);
  if (t.length <= maxLen) return [t];
  const parts = [];
  let buf = '';
  for (let i = 0; i < t.length; i++) {
    buf += t[i];
    const ch = t[i];
    const next = t[i + 1];
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

  const out = [];
  let cur = '';
  for (const s of small) {
    if (cur.length === 0) { cur = s; continue; }
    if ((cur + ' ' + s).length <= maxLen) cur += ' ' + s;
    else { out.push(cur); cur = s; }
  }
  if (cur) out.push(cur);
  return out;
}

function makeSection(rawText, condFlags = [], excludeFlags = []) {
  const arr = splitToArray(clean(rawText));
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

function writeFile(relPath, segId, sections) {
  const out = { id: segId, sections };
  const fullPath = path.join(PROJECT, relPath);
  fs.mkdirSync(path.dirname(fullPath), { recursive: true });
  fs.writeFileSync(fullPath, JSON.stringify(out, null, 2) + '\n', 'utf8');
  const maxLine = sections.flatMap(s => Array.isArray(s.text) ? s.text : [s.text])
    .reduce((m, l) => Math.max(m, l.length), 0);
  console.log(`  ${relPath} — sections=${sections.length} maxLine=${maxLine}`);
}

function readSefaria(key) {
  const d = JSON.parse(fs.readFileSync(path.join(PROJECT, `_${key}.json`), 'utf8'));
  return flatten(d.versions[0].text);
}

// ──────────────────────────────────────────────────────────────────────────────
// B2: Akeidah Yehi Ratzon (post-parsha)
//   Ashkenaz: ash_akedah[2]    — 806 chars
//   Sfard:    sef_morningprayer[3] — 2181 chars, exclude_flags: skip_tachanun
//             (Sefard custom: this long Yehi Ratzon is NOT said on non-Tachanun days)
//   EM:       em_morningprayer[7]  — 540 chars
// ──────────────────────────────────────────────────────────────────────────────

console.log('\n=== B2: Akeidah Yehi Ratzon ===');

const ashAk = readSefaria('ash_akedah');
writeFile(
  'assets/prayers/nusach/ashkenaz/akeidah_yehi_ratzon.json',
  'akeidah_yehi_ratzon',
  [makeSection(ashAk[2])],
);

const sefMp = readSefaria('sef_morningprayer');
writeFile(
  'assets/prayers/nusach/sfard/akeidah_yehi_ratzon.json',
  'akeidah_yehi_ratzon',
  [makeSection(sefMp[3], [], ['skip_tachanun'])],
);

const emMp = readSefaria('em_morningprayer');
writeFile(
  'assets/prayers/nusach/edot_mizrach/akeidah_yehi_ratzon.json',
  'akeidah_yehi_ratzon',
  [makeSection(emMp[7])],
);

// ──────────────────────────────────────────────────────────────────────────────
// B1: Ahavat Olam (Maariv) per nusach
//   common/ahavat_olam.json is already the Ashkenaz Maariv version (~421 chars).
//   Add per-nusach overrides for Sfard and Edot HaMizrach.
//   Sfard:  sef_maariv_shema[7] — 445 chars
//   EM:     em_arvit_shema[2]   — 482 chars
// ──────────────────────────────────────────────────────────────────────────────

console.log('\n=== B1: Ahavat Olam (Maariv) per nusach ===');

const sefMariv = readSefaria('sef_maariv_shema');
writeFile(
  'assets/prayers/nusach/sfard/ahavat_olam.json',
  'ahavat_olam',
  [makeSection(sefMariv[7])],
);

const emArvit = readSefaria('em_arvit_shema');
writeFile(
  'assets/prayers/nusach/edot_mizrach/ahavat_olam.json',
  'ahavat_olam',
  [makeSection(emArvit[2])],
);

// ──────────────────────────────────────────────────────────────────────────────
// B4: Nachem fix in amidah_yerushalayim
//   - Change `tisha_beav` → `tisha_beav_mincha` (Nachem is Mincha-only, not whole day)
//   - For EM: add new section with Tisha B'Av Mincha chatima (different from regular)
//     from em_minamida[27] "ברוך אתה ה' מנחם ציון ובונה ירושלים"
// ──────────────────────────────────────────────────────────────────────────────

console.log('\n=== B4: Nachem flag fix + EM TB\'A Mincha chatima ===');

function fixAmidahYerushalayim(relPath, addEmTbaChatima = false) {
  const fullPath = path.join(PROJECT, relPath);
  const d = JSON.parse(fs.readFileSync(fullPath, 'utf8'));

  // Rewrite flags: tisha_beav → tisha_beav_mincha
  d.sections.forEach(s => {
    s.condition_flags = (s.condition_flags || []).map(f => f === 'tisha_beav' ? 'tisha_beav_mincha' : f);
    s.exclude_flags = (s.exclude_flags || []).map(f => f === 'tisha_beav' ? 'tisha_beav_mincha' : f);
  });

  // For EM only: append a Tisha B'Av Mincha-specific chatima section
  if (addEmTbaChatima) {
    const emMinAmida = readSefaria('em_minamida');
    // em_minamida[27] is the EM Tisha B'Av Mincha chatima
    // "בָּרוּךְ אַתָּה יְהֹוָה מְנַחֵם צִיּוֹן וּבוֹנֵה יְרוּשָׁלָֽיִם:"
    // The raw entry also has a trailing "וממשיכים את צמח וכו'" rubric -
    // strip rubric text after the colon-period of the bracha.
    let chatima = clean(emMinAmida[27]);
    // Cut at first colon that ends the bracha (last "ירושלים:")
    const m = chatima.match(/(.+?ירוּשָׁלָֽ?י?ם:)/);
    if (m) chatima = m[1];
    d.sections.push(makeSection(chatima, ['tisha_beav_mincha'], []));
  }

  fs.writeFileSync(fullPath, JSON.stringify(d, null, 2) + '\n', 'utf8');
  const lines = d.sections.flatMap(s => Array.isArray(s.text) ? s.text : [s.text]);
  const maxLine = lines.reduce((m, l) => Math.max(m, l.length), 0);
  console.log(`  ${relPath} — sections=${d.sections.length} maxLine=${maxLine}`);
  d.sections.forEach((s, i) => {
    console.log(`     [${i}] cond=${JSON.stringify(s.condition_flags)} excl=${JSON.stringify(s.exclude_flags)}`);
  });
}

fixAmidahYerushalayim('assets/prayers/nusach/ashkenaz/amidah_yerushalayim.json');
fixAmidahYerushalayim('assets/prayers/nusach/sfard/amidah_yerushalayim.json');
fixAmidahYerushalayim('assets/prayers/nusach/edot_mizrach/amidah_yerushalayim.json', true);

console.log('\nDONE.');
