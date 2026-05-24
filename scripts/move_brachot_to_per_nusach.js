// Refactor: move every Birchot HaShachar bracha from common/ to per-nusach.
// Per the user's principle: common/ holds only TRULY shared content (mostly
// biblical verses appearing in the same order in all nusachim). Brachot
// belong to a nusach's tradition even when the text happens to coincide.
//
// For each bracha listed below, this script:
//   1. Extracts the per-nusach Hebrew text from the corresponding Sefaria
//      source file already on disk.
//   2. Writes nusach/{ashkenaz,sfard,edot_mizrach}/{bracha}.json with that text.
//   3. Deletes the common/{bracha}.json file (no longer needed; the assembler
//      will resolve directly from the nusach folder).
//
// Pesukim segments stay in common (birchot_hatorah_pesukim, elu_devarim).

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';

function stripHtml(t) { return (t || '').replace(/<[^>]+>/g, ''); }
function stripTrope(t) { return t.replace(/[֑-֯]/g, ''); }
function normSpaces(t) { return t.replace(/\s+/g, ' ').trim(); }
function clean(t) { return normSpaces(stripTrope(stripHtml(t))); }
function flatten(x) { return Array.isArray(x) ? x.flatMap(flatten) : [x]; }

function matchable(s) {
  return s.replace(/[־]/g, ' ').replace(/[֑-ֿׁ-ׇ]/g, '').replace(/[,.׃:;()״"'׳״\-]/g, ' ').replace(/\s+/g, ' ').trim();
}

function loadSefaria(key) {
  const d = JSON.parse(fs.readFileSync(path.join(PROJECT, `_${key}.json`), 'utf8'));
  return flatten(d.versions[0].text).map(clean);
}

const ASH_MB = loadSefaria('ash_morning_blessings');
const SEF_MB = loadSefaria('sef_morning_blessings');
const SEF_TB = loadSefaria('sef_torah_blessings');
const EM_MB  = loadSefaria('em_morning_blessings');

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

function sec(text, condFlags = [], excludeFlags = []) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

function writeSeg(nusach, segId, sections) {
  const obj = { id: segId, sections };
  const rel = `assets/prayers/nusach/${nusach}/${segId}.json`;
  const full = path.join(PROJECT, rel);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

function findByKeywords(entries, ...keywords) {
  for (let i = 0; i < entries.length; i++) {
    const bare = matchable(entries[i]);
    if (keywords.every(k => bare.includes(k))) return entries[i];
  }
  return null;
}

function findRange(entries, startKws, endKws) {
  let start = -1, end = -1;
  for (let i = 0; i < entries.length; i++) {
    const bare = matchable(entries[i]);
    if (start < 0 && startKws.every(k => bare.includes(k))) start = i;
    if (start >= 0 && endKws.every(k => bare.includes(k))) { end = i; break; }
  }
  if (start < 0) return null;
  if (end < 0) end = start;
  return entries.slice(start, end + 1).join(' ');
}

// ────────────────────────────────────────────────────────────────────────────
// Brachot definitions:
//   segId, [match keywords], optional extra (e.g., chatima end-marker), opts
//
// Each entry produces three per-nusach files. If a nusach source lacks the
// bracha, the script logs a warning and skips that nusach.

const BRACHOT = [
  { segId: 'al_netilat_yadayim',     kws: ['על נטילת ידים'] },
  { segId: 'asher_yatzar',           kws: ['אשר יצר את האדם'] },
  { segId: 'pokeach_ivrim',          kws: ['פוקח עורים'] },
  { segId: 'matir_asurim',           kws: ['מתיר אסורים'] },
  { segId: 'zokef_kefufim',          kws: ['זוקף כפופים'] },
  { segId: 'malbish_arumim',         kws: ['מלביש ערמים'] },
  { segId: 'rokea_haaretz',          kws: ['רוקע הארץ'] },
  { segId: 'hamechin_mitzedei_gever',kws: ['המכין מצעדי גבר'] },
  { segId: 'ozer_yisrael',           kws: ['אוזר ישראל'] },
  { segId: 'oter_yisrael',           kws: ['עוטר ישראל'] },
  { segId: 'hanoten_layaef_koach',   kws: ['הנותן ליעף כח'] },
  { segId: 'shelo_asani_goy',        kws: ['שלא עשני גוי'] },
  { segId: 'shelo_asani_eved',       kws: ['שלא עשני עבד'] },
  { segId: 'shelo_asani_ishah',      kws: ['שלא עשני אשה'] },
];

const sources = {
  ashkenaz: ASH_MB,
  sfard:    SEF_TB,   // Sefard puts BHS in "Blessings on Torah" section
  edot_mizrach: EM_MB,
};
// Sefard's al_netilat / asher_yatzar / elokai_neshama actually live in
// SEF_MB (the dedicated Morning Blessings section). Use a secondary source.
const sfardEarly = SEF_MB;

console.log('=== moving brachot to per-nusach ===');
for (const b of BRACHOT) {
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    let src = sources[nusach];
    if (nusach === 'sfard' && ['al_netilat_yadayim','asher_yatzar'].includes(b.segId)) {
      src = sfardEarly;
    }
    let text = findByKeywords(src, ...b.kws);
    // Ashkenaz Sefaria source ("Morning Blessings") lacks al_netilat_yadayim
    // and asher_yatzar (they live under Modeh Ani / washing rubric, not the
    // BHS section). Fall back to the Sefard source for these universal
    // brachot — text is liturgically identical across nusachim.
    if (!text && nusach === 'ashkenaz') {
      text = findByKeywords(SEF_MB, ...b.kws) || findByKeywords(EM_MB, ...b.kws);
    }
    if (!text) { console.log(`  !! ${nusach}/${b.segId}: not found`); continue; }
    writeSeg(nusach, b.segId, [sec(text)]);
  }
}

// Hanoten Lasechvi — text varies between nusachim:
//   Ashkenaz opens "אשר נתן לשכוי בינה" (talmudic phrasing)
//   Sefard/EM open "הנותן לשכוי בינה" (more common siddur phrasing)
// Match on the distinctive "לשכוי" alone.
console.log('\n=== hanoten_lasechvi: ensure all 3 nusachim ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const src = nusach === 'ashkenaz' ? ASH_MB
            : nusach === 'sfard'    ? SEF_TB
            :                         EM_MB;
  const text = findByKeywords(src, 'לשכוי');
  if (!text) { console.log(`  !! ${nusach}/hanoten_lasechvi: not found`); continue; }
  writeSeg(nusach, 'hanoten_lasechvi', [sec(text)]);
}

// Elokai Neshama with gender variant (per nusach)
console.log('\n=== elokai_neshama (with gender variant) ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const src = nusach === 'ashkenaz' ? ASH_MB
            : nusach === 'sfard'    ? SEF_MB
            :                         EM_MB;
  let male = findByKeywords(src, 'אלהי', 'נשמה');
  if (!male) {
    // Ashkenaz Sefaria source doesn't include it in Morning Blessings
    // section — fall back to SEF_MB (text matches Ashkenaz custom).
    male = findByKeywords(SEF_MB, 'אלהי', 'נשמה') || findByKeywords(EM_MB, 'אלהי', 'נשמה');
  }
  if (!male) { console.log(`  !! ${nusach}/elokai_neshama: not found`); continue; }
  const female = male
    .replace(/מוֹדֶה אֲנִי/g, 'מוֹדָה אֲנִי')
    .replace(/מוֹדֶה לְפָנֶיךָ/g, 'מוֹדָה לְפָנֶיךָ');
  writeSeg(nusach, 'elokai_neshama', [
    sec(male,   ['gender_male']),
    sec(female, ['gender_female']),
  ]);
}

// Hanoten Lasechvi — already per-nusach for EM; build Ashkenaz/Sfard.
console.log('\n=== hanoten_lasechvi per nusach ===');
const hlsAsh = findByKeywords(ASH_MB, 'הנותן לשכוי בינה');
if (hlsAsh) writeSeg('ashkenaz', 'hanoten_lasechvi', [sec(hlsAsh)]);
const hlsSef = findByKeywords(SEF_TB, 'הנותן לשכוי בינה');
if (hlsSef) writeSeg('sfard', 'hanoten_lasechvi', [sec(hlsSef)]);
// EM already exists from earlier — don't overwrite if present.

// Sheasah Li Kol Tzorki — keep TB/YK exclude flag per nusach.
console.log('\n=== sheasah_li_kol_tzorki per nusach (with TB/YK exclude) ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const src = sources[nusach];
  const text = findByKeywords(src, 'שעשה לי כל צרכי');
  if (!text) { console.log(`  !! ${nusach}/sheasah_li_kol_tzorki: not found`); continue; }
  writeSeg(nusach, 'sheasah_li_kol_tzorki', [sec(text, [], ['tisha_beav', 'yom_kippur'])]);
}

// Sheasani Kirtzono — per nusach (Ash/Sfard with shem v'malchut; EM short form).
console.log('\n=== sheasani_kirtzono per nusach ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const src = sources[nusach];
  let text = findByKeywords(src, 'שעשני כרצונו');
  if (!text) { console.log(`  !! ${nusach}/sheasani_kirtzono: not found`); continue; }
  // Ashkenaz source wraps it in "(נשים אומרות: ...)"
  text = text.replace(/^\(נשים אומרות:\s*/, '').replace(/\)$/, '').trim();
  writeSeg(nusach, 'sheasani_kirtzono', [sec(text, ['gender_female'])]);
}

// Delete orphaned common files (now superseded by per-nusach versions).
console.log('\n=== removing orphaned common files ===');
const toDelete = [
  'al_netilat_yadayim','asher_yatzar','elokai_neshama','hanoten_lasechvi',
  'pokeach_ivrim','matir_asurim','zokef_kefufim','malbish_arumim',
  'rokea_haaretz','hamechin_mitzedei_gever','ozer_yisrael','oter_yisrael',
  'hanoten_layaef_koach','sheasah_li_kol_tzorki','sheasani_kirtzono',
  'shelo_asani_goy','shelo_asani_eved','shelo_asani_ishah',
];
for (const segId of toDelete) {
  const p = path.join(PROJECT, `assets/prayers/common/${segId}.json`);
  if (fs.existsSync(p)) {
    fs.unlinkSync(p);
    console.log('  deleted common/' + segId + '.json');
  }
}

// Verify every nusach has every segment
console.log('\n=== verification ===');
const required = [
  ...toDelete,
];
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  let missing = 0;
  for (const segId of required) {
    const p = path.join(PROJECT, `assets/prayers/nusach/${nusach}/${segId}.json`);
    if (!fs.existsSync(p)) { console.log(`  !! ${nusach}/${segId} missing`); missing++; }
  }
  console.log(`  ${nusach}: ${required.length - missing}/${required.length} segments present`);
}

console.log('\nDONE.');
