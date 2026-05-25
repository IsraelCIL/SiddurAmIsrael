// B5: Restructure Birchot HaShachar and Birchot HaTorah into per-bracha segments.
//
// Strategy:
//   1. Each individual bracha = its own segment file in common/ (text identical
//      across nusachim), OR in nusach/{nusach}/ (text varies).
//   2. Per-nusach TEMPLATES (birchot_hashachar_ashkenaz, _sfard, _edot_mizrach
//      and birchot_hatorah_*) wire the segments in the right order.
//   3. Main shacharit templates reference the per-nusach birchot templates via
//      sub_template_id (handled in a follow-up script).
//
// Sources on disk (already fetched earlier this session):
//   _ash_morning_blessings.json  Sefaria Ashkenaz, Shacharit Preparatory, Morning Blessings (18 entries)
//   _ash_torah_blessings.json    Sefaria Ashkenaz, Shacharit Preparatory, Torah Blessings (3 entries)
//   _sef_morning_blessings.json  Sefaria Sefard, Weekday Shacharit, Morning Blessings (3 entries)
//   _sef_torah_blessings.json    Sefaria Sefard, Weekday Shacharit, Blessings on Torah (26 entries — contains
//                                the rest of Birchot HaShachar that comes after Torah Blessings in Sefard)
//   _em_morning_blessings.json   Sefaria EM, Preparatory Prayers, Morning Blessings (27 entries with rubrics)
//   _em_torah_blessings.json     Sefaria EM, Preparatory Prayers, Torah Blessings (5 entries)
//
// All Hebrew text processed on disk. Nothing flows through assistant response.

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';

// ─── utilities ────────────────────────────────────────────────────────────────
function stripHtml(t) { return (t || '').replace(/<[^>]+>/g, ''); }
function stripTrope(t) { return t.replace(/[֑-֯]/g, ''); }
function normSpaces(t) { return t.replace(/\s+/g, ' ').trim(); }
function clean(t) { return normSpaces(stripTrope(stripHtml(t))); }
function flatten(x) { return Array.isArray(x) ? x.flatMap(flatten) : [x]; }
function stripNiqqud(s) { return s.replace(/[֑-ׇ]/g, ''); }

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
  const arr = Array.isArray(text) ? text : splitToArray(clean(text));
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

function writeSeg(relPath, segId, sections) {
  const obj = { id: segId, sections };
  const full = path.join(PROJECT, relPath);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, JSON.stringify(obj, null, 2) + '\n', 'utf8');
  const maxLine = sections.flatMap(s => Array.isArray(s.text) ? s.text : [s.text])
    .reduce((m, l) => Math.max(m, l.length), 0);
  console.log(`  ${relPath} (${segId}) — sections=${sections.length} maxLine=${maxLine}`);
}

function loadSefariaFlat(key) {
  const d = JSON.parse(fs.readFileSync(path.join(PROJECT, `_${key}.json`), 'utf8'));
  return flatten(d.versions[0].text).map(s => clean(s)).map(s => s.replace(/\s*\([^)]*\)\s*/g, ' ').trim());
  // The above strips inline parentheticals like "(נשים אומרות:" and "(האשה אומרת:...)".
}

// Re-load without stripping parentheticals (we sometimes need them, e.g., for
// matching markers that come with parenthetical rubrics).
function loadSefariaRaw(key) {
  const d = JSON.parse(fs.readFileSync(path.join(PROJECT, `_${key}.json`), 'utf8'));
  return flatten(d.versions[0].text).map(s => clean(s));
}

// Find first entry whose bare (no-niqqud, no-punct) text contains all keyword substrings.
function matchable(s) {
  // Strip vowels/marks and any non-Hebrew-letter, non-space punctuation (incl.
  // maqaf ־ U+05BE, geresh ׳, gershayim ״, etc.) so keywords match robustly.
  // IMPORTANT: replace maqaf with space BEFORE stripping niqqud range
  // (the maqaf is in U+05BE which falls inside U+05B0-U+05BF; stripping it
  //  would join "כל־צרכי" into "כלצרכי").
  return s
    .replace(/[־]/g, ' ')                // maqaf → space (must come first)
    .replace(/[֑-ֿׁ-ׇ]/g, '')              // strip remaining marks/vowels
    .replace(/[,.׃:;()״"'׳״\-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}
function findEntry(entries, ...keywords) {
  for (let i = 0; i < entries.length; i++) {
    const bare = matchable(entries[i]);
    if (keywords.every(k => bare.includes(k))) return { idx: i, text: entries[i] };
  }
  return null;
}

// ─── load Sefaria sources ─────────────────────────────────────────────────────
const ASH_MB = loadSefariaRaw('ash_morning_blessings');  // 18 entries
const ASH_TB = loadSefariaRaw('ash_torah_blessings');    // 3 entries
const SEF_MB = loadSefariaRaw('sef_morning_blessings');  // 3 entries
const SEF_TB = loadSefariaRaw('sef_torah_blessings');    // 26 entries (includes BHS tail)
const EM_MB  = loadSefariaRaw('em_morning_blessings');   // 27 entries
const EM_TB  = loadSefariaRaw('em_torah_blessings');     // 5 entries

// ─── (1) COMMON brachot — built from Ashkenaz source (standard text) ─────────
//        These are also said by Sfard and EM with identical wording, unless
//        the per-nusach overrides below replace them.

console.log('\n=== B5: Common (shared) brachot ===');

// Al Netilat Yadayim — from Sefard or EM source (Ashkenaz doesn't include it in
// this Sefaria section, but the text is universal).
const alNetilat = findEntry(SEF_MB, 'על נטילת ידים');
writeSeg('assets/prayers/common/al_netilat_yadayim.json', 'al_netilat_yadayim', [sec(alNetilat.text)]);

// Asher Yatzar — universal (Sefard and EM both have it; pick Sefard's).
const asherYatzar = findEntry(SEF_MB, 'אשר יצר את האדם') || findEntry(EM_MB, 'אשר יצר את האדם');
writeSeg('assets/prayers/common/asher_yatzar.json', 'asher_yatzar', [sec(asherYatzar.text)]);

// Elokai Neshama with gender variant for "מודה"/"מודה".
// The Sefaria text is masculine ("מודה אני"). We add a parallel female section.
const eloka_iSrc = findEntry(SEF_MB, 'אלהי נשמה') || findEntry(EM_MB, 'אלהי נשמה');
const eloka_iMale = eloka_iSrc.text;
// Replace masculine "מוֹדֶה אֲנִי" with feminine "מוֹדָה אֲנִי" (cholam → kamatz on dalet).
const eloka_iFemale = eloka_iMale
  .replace(/מוֹדֶה אֲנִי/g, 'מוֹדָה אֲנִי')   // primary form
  .replace(/מוֹדֶה לְפָנֶיךָ/g, 'מוֹדָה לְפָנֶיךָ'); // variant phrasing if present
writeSeg('assets/prayers/common/elokai_neshama.json', 'elokai_neshama', [
  sec(eloka_iMale, ['gender_male']),
  sec(eloka_iFemale, ['gender_female']),
]);

// The "negative" brachot — text identical across nusachim.
function copyBracha(filename, segId, keywords) {
  // Prefer Ashkenaz source if it has it, then fall back to Sefard/EM.
  let found = findEntry(ASH_MB, ...keywords)
           || findEntry(SEF_TB, ...keywords)
           || findEntry(SEF_MB, ...keywords)
           || findEntry(EM_MB, ...keywords);
  if (!found) { console.log('  !! NOT FOUND:', segId); return; }
  writeSeg('assets/prayers/common/' + filename, segId, [sec(found.text)]);
}

copyBracha('pokeach_ivrim.json',         'pokeach_ivrim',          'פוקח עורים');
copyBracha('matir_asurim.json',          'matir_asurim',           'מתיר אסורים');
copyBracha('zokef_kefufim.json',         'zokef_kefufim',          'זוקף כפופים');
copyBracha('malbish_arumim.json',        'malbish_arumim',         'מלביש ערמים'); // qubuts on resh; in Ashk this is "מַלְבִּישׁ עֲרֻמִּים" → bare "מלביש ערמים"
copyBracha('rokea_haaretz.json',         'rokea_haaretz',          'רוקע הארץ');
copyBracha('hamechin_mitzedei_gever.json','hamechin_mitzedei_gever','המכין מצעדי גבר');
copyBracha('ozer_yisrael.json',          'ozer_yisrael',           'אוזר ישראל');
copyBracha('oter_yisrael.json',          'oter_yisrael',           'עוטר ישראל');
copyBracha('hanoten_layaef_koach.json',  'hanoten_layaef_koach',   'הנותן ליעף כח');
copyBracha('shelo_asani_goy.json',       'shelo_asani_goy',        'שלא עשני גוי');
copyBracha('shelo_asani_eved.json',      'shelo_asani_eved',       'שלא עשני עבד');
copyBracha('shelo_asani_ishah.json',     'shelo_asani_ishah',      'שלא עשני אשה');

// Sheasah Li Kol Tzorki — excluded on Tisha B'Av and Yom Kippur per EM rubric
// at em_minamida... wait, the rubric is in em_morning_blessings[15]. Carry the
// exclude on the segment so it works regardless of nusach.
const sheasahLi = findEntry(ASH_MB, 'שעשה לי כל צרכי') || findEntry(EM_MB, 'שעשה לי כל צרכי');
writeSeg('assets/prayers/common/sheasah_li_kol_tzorki.json', 'sheasah_li_kol_tzorki', [
  sec(sheasahLi.text, [], ['tisha_beav', 'yom_kippur']),
]);

// ─── (2) Per-nusach Hanoten Lasechvi Binah (different text in EM) ────────────

console.log('\n=== B5: per-nusach Hanoten Lasechvi ===');

// Ashkenaz/Sfard text → common file
const hlsAshSfard = findEntry(ASH_MB, 'הנותן לשכוי בינה') || findEntry(SEF_TB, 'הנותן לשכוי בינה');
writeSeg('assets/prayers/common/hanoten_lasechvi.json', 'hanoten_lasechvi', [sec(hlsAshSfard.text)]);

// EM text → per-nusach override
const hlsEm = findEntry(EM_MB, 'הנותן לשכוי בינה');
if (hlsEm) writeSeg('assets/prayers/nusach/edot_mizrach/hanoten_lasechvi.json', 'hanoten_lasechvi', [sec(hlsEm.text)]);

// ─── (3) Per-nusach Sheasani Kirtzono (EM lacks shem v'malchut) ──────────────

console.log('\n=== B5: per-nusach Sheasani Kirtzono (female) ===');

// Ashkenaz/Sfard: full bracha with shem v'malchut
// (Ashkenaz source has it inside parentheses "(נשים אומרות: ...")", strip those.)
let skAshSfardRaw = findEntry(ASH_MB, 'שעשני כרצונו')
                 || findEntry(SEF_TB, 'שעשני כרצונו');
let skAshSfard = skAshSfardRaw.text
  .replace(/^\(נשים אומרות:\s*/, '')
  .replace(/\)$/, '')
  .trim();
writeSeg('assets/prayers/common/sheasani_kirtzono.json', 'sheasani_kirtzono', [
  sec(skAshSfard, ['gender_female']),
]);

// EM: short form "ברוך שעשני כרצונו" — no shem v'malchut
const skEm = findEntry(EM_MB, 'שעשני כרצונו');
if (skEm) {
  let emTxt = skEm.text;
  // Match the EM source exactly: "בָּרוּךְ שֶׁעָשַׂנִי כִּרְצוֹנוֹ:"
  // (if it includes a longer wrapper, strip non-bracha lead-in)
  writeSeg('assets/prayers/nusach/edot_mizrach/sheasani_kirtzono.json', 'sheasani_kirtzono', [
    sec(emTxt, ['gender_female']),
  ]);
}

// ─── (4) Per-nusach Hamaavir Sheinah + chatima ───────────────────────────────

console.log('\n=== B5: per-nusach Hamaavir Sheinah (with chatima) ===');

// Ashkenaz: combine entries [15] (bracha opening) + [16] (yehi ratzon body
// ending with chatima "הגומל חסדים טובים לעמו ישראל"). These are split in
// Sefaria but constitute a single bracha liturgically.
function findHamaavirRange(entries) {
  // Search by "המעביר" alone — EM adds "חבלי" between "המעביר" and "שנה"
  // ("המעביר חבלי שנה"), while Ashkenaz/Sfard go "המעביר שינה" / "המעביר שנה".
  let openIdx = entries.findIndex(t => matchable(t).includes('המעביר'));
  if (openIdx < 0) return null;
  // The "chatima" line ends with "לעמו ישראל". Look for the next line ending
  // in that phrase.
  let endIdx = openIdx;
  for (let j = openIdx; j < entries.length; j++) {
    if (stripNiqqud(entries[j]).includes('הגומל חסדים טובים לעמו ישראל')) {
      endIdx = j;
      break;
    }
  }
  return { openIdx, endIdx };
}

const ashHmRange = findHamaavirRange(ASH_MB);
const ashHm = ASH_MB.slice(ashHmRange.openIdx, ashHmRange.endIdx + 1).join(' ');
writeSeg('assets/prayers/nusach/ashkenaz/hamaavir_sheinah.json', 'hamaavir_sheinah', [sec(ashHm)]);

const sefHmRange = findHamaavirRange(SEF_TB);
const sefHm = SEF_TB.slice(sefHmRange.openIdx, sefHmRange.endIdx + 1).join(' ');
writeSeg('assets/prayers/nusach/sfard/hamaavir_sheinah.json', 'hamaavir_sheinah', [sec(sefHm)]);

const emHmRange = findHamaavirRange(EM_MB);
// EM has it as a single entry (em_morning_blessings[25])
const emHm = EM_MB.slice(emHmRange.openIdx, emHmRange.endIdx + 1).join(' ');
writeSeg('assets/prayers/nusach/edot_mizrach/hamaavir_sheinah.json', 'hamaavir_sheinah', [sec(emHm)]);

// ─── (5) Per-nusach Yehi Ratzon Shelo Yavo (concluding yehi ratzon) ───────────

console.log('\n=== B5: per-nusach Yehi Ratzon Shelo Yavo ===');

// "יהי רצון... שלא יבא לידי עברה ולא לידי עון..."
function findYehiRatzonShelo(entries) {
  // Distinctive: starts with "יהי רצון", contains "שתצילני" and "מעזי פנים".
  return entries.findIndex(t => {
    const b = matchable(t);
    return b.startsWith('יהי רצון') && b.includes('שתצילני') && b.includes('מעזי פנים');
  });
}

const ashYr = ASH_MB[findYehiRatzonShelo(ASH_MB)];
if (ashYr) writeSeg('assets/prayers/nusach/ashkenaz/yehi_ratzon_shelo_yavo.json', 'yehi_ratzon_shelo_yavo', [sec(ashYr)]);

const sefYr = SEF_TB[findYehiRatzonShelo(SEF_TB)];
if (sefYr) writeSeg('assets/prayers/nusach/sfard/yehi_ratzon_shelo_yavo.json', 'yehi_ratzon_shelo_yavo', [sec(sefYr)]);

const emYr = EM_MB[findYehiRatzonShelo(EM_MB)];
if (emYr) writeSeg('assets/prayers/nusach/edot_mizrach/yehi_ratzon_shelo_yavo.json', 'yehi_ratzon_shelo_yavo', [sec(emYr)]);

// ─── (6) Per-nusach Birchot HaTorah ──────────────────────────────────────────

console.log('\n=== B5: per-nusach Birchot HaTorah ===');

// First Birchat HaTorah ("...אשר קדשנו במצותיו וצונו... בדברי תורה").
// Renamed conceptually: this is "asher_kidshanu" (the first of three), not
// "asher_bachar" which is the third. Keep findAsherBachar() as the function
// name since callers reference it; segment filename remains la'asok-oriented.
function findAsherBachar(entries) {
  return entries.findIndex(t => {
    const b = matchable(t);
    return b.includes('אשר קדשנו') && b.includes('דברי תורה');
  });
}

['ashkenaz', 'sfard', 'edot_mizrach'].forEach(nusach => {
  const src = { ashkenaz: ASH_TB, sfard: SEF_TB, edot_mizrach: EM_TB }[nusach];
  const i = findAsherBachar(src);
  if (i < 0) { console.log('  !! Asher Bachar not found in', nusach); return; }
  writeSeg(`assets/prayers/nusach/${nusach}/birchot_hatorah_asher_bachar.json`, 'birchot_hatorah_asher_bachar', [sec(src[i])]);
});

// Vehaarev Na — second bracha
function findVehaarev(entries) {
  return entries.findIndex(t => matchable(t).includes('והערב נא'));
}
['ashkenaz', 'sfard', 'edot_mizrach'].forEach(nusach => {
  const src = { ashkenaz: ASH_TB, sfard: SEF_TB, edot_mizrach: EM_TB }[nusach];
  const i = findVehaarev(src);
  if (i < 0) { console.log('  !! Vehaarev not found in', nusach); return; }
  writeSeg(`assets/prayers/nusach/${nusach}/birchot_hatorah_vehaarev.json`, 'birchot_hatorah_vehaarev', [sec(src[i])]);
});

// Asher Bachar... Natan Torah — third bracha
function findNatanTorah(entries) {
  return entries.findIndex(t => matchable(t).includes('נותן התורה'));
}
['ashkenaz', 'sfard', 'edot_mizrach'].forEach(nusach => {
  const src = { ashkenaz: ASH_TB, sfard: SEF_TB, edot_mizrach: EM_TB }[nusach];
  const i = findNatanTorah(src);
  if (i < 0) { console.log('  !! Natan Torah not found in', nusach); return; }
  writeSeg(`assets/prayers/nusach/${nusach}/birchot_hatorah_natan_torah.json`, 'birchot_hatorah_natan_torah', [sec(src[i])]);
});

// Torah verses (Vayedaber + Birkat Kohanim pesukim) — shared text
// Ashkenaz Sefaria splits across multiple lines; Sefard has it more compact.
// We pick the Sefard packaging (entries [3]+[4]+[5] of sef_torah_blessings).
function findTorahVerses() {
  // Look for "וידבר ה'" introducing the verses
  const idx = SEF_TB.findIndex(t => matchable(t).includes('וידבר') && matchable(t).includes('משה'));
  if (idx < 0) return null;
  // Concatenate up to 3 lines (Vayedaber + Birkat Kohanim + Vesamu)
  const lines = [SEF_TB[idx]];
  for (let j = idx + 1; j < Math.min(idx + 3, SEF_TB.length); j++) {
    const b = stripNiqqud(SEF_TB[j]);
    if (b.includes('יברכך') || b.includes('יאר') || b.includes('ישא') || b.includes('ושמו')) {
      lines.push(SEF_TB[j]);
    } else break;
  }
  return lines.join(' ');
}
const torahVerses = findTorahVerses();
if (torahVerses) writeSeg('assets/prayers/common/birchot_hatorah_pesukim.json', 'birchot_hatorah_pesukim', [sec(torahVerses)]);

// Eilu Devarim (text common across nusachim)
const eluDevarim = findEntry(SEF_TB, 'אלו דברים שאין להם שעור');
if (eluDevarim) writeSeg('assets/prayers/common/elu_devarim.json', 'elu_devarim', [sec(eluDevarim.text)]);

console.log('\nDONE.');
