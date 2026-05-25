// B3: Restructure Avinu Malkeinu
//
// 1) common/avinu_malkeinu.json — split the existing Ashkenaz/Sfard text into
//    sections by flag:
//      • "חדש עלינו שנה טובה"            → condition_flags: ["aseret_yemei_teshuva"]
//      • "ברך עלינו שנה טובה"             → condition_flags: ["fast_day"],
//                                            exclude_flags: ["aseret_yemei_teshuva","tisha_beav"]
//      • 5 כתבנו lines                    → condition_flags: ["aseret_yemei_teshuva"]
//      • 5 זכרנו ל-X lines                → condition_flags: ["fast_day"],
//                                            exclude_flags: ["aseret_yemei_teshuva","tisha_beav"]
//      • everything else                  → always (when avinu_malkeinu is triggered)
//    The text is taken from the existing file so we preserve the editorial
//    decisions already made (line splits, exact niqqud).
//
// 2) nusach/edot_mizrach/avinu_malkeinu.json — built fresh from Sefaria
//    "Siddur Edot HaMizrach, Weekday Mincha, Amida" entries 72–104.
//    EM has only one כתבנו block (no separate זכרנו block on regular fasts).
//
// 3) nusach/edot_mizrach/yehi_shem.json — NEW segment for em_minamida[106]
//    (psalmic verses said after Amida on non-tachanun days in EM). These were
//    embedded inside the Sefaria Avinu Malkeinu block but logically belong
//    elsewhere; flagged condition_flags: ["skip_tachanun"].

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

function sec(text, condFlags = [], excludeFlags = []) {
  const txt = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: txt.length === 1 ? txt[0] : txt,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

function writeJson(relPath, obj) {
  const fullPath = path.join(PROJECT, relPath);
  fs.mkdirSync(path.dirname(fullPath), { recursive: true });
  fs.writeFileSync(fullPath, JSON.stringify(obj, null, 2) + '\n', 'utf8');
  console.log('  wrote', relPath);
}

// ──────────────────────────────────────────────────────────────────────────────
// (1) Restructure common/avinu_malkeinu.json
//     Identify keyword markers in existing lines (not from memory — match by
//     a distinctive Hebrew substring already present in the file).
// ──────────────────────────────────────────────────────────────────────────────

const curFile = path.join(PROJECT, 'assets/prayers/common/avinu_malkeinu.json');
const cur = JSON.parse(fs.readFileSync(curFile, 'utf8'));
// Idempotent: gather all lines regardless of whether the file is in flat
// (single section, array of 50 lines) or already-split (7 sections) shape.
const lines = cur.sections.flatMap(s => Array.isArray(s.text) ? s.text : [s.text]);

// Build keyword index — find lines containing distinctive words.
function findIdx(substr) {
  const idx = lines.findIndex(l => l.includes(substr));
  if (idx < 0) throw new Error('not found: ' + substr);
  return idx;
}

const idx_chadesh = findIdx('חַדֵּשׁ');                 // חדש עלינו שנה טובה
const idx_barech  = findIdx('בָּרֵךְ');                  // ברך עלינו שנה טובה (only on fasts)
// Note: 'בְָּרֵד' = "בָּרֵד" wouldn't match; just use ברך directly
const idx_katvenu_first = findIdx('כָּתְבֵנוּ בְּסֵפֶר חַיִּים');
const idx_zochrenu_first = findIdx('זָכְרֵנוּ לְחַיִּים');

// Verify expected ranges
console.log('  marker indices:');
console.log('    חדש=' + idx_chadesh, 'ברך=' + idx_barech, 'כתבנו[0]=' + idx_katvenu_first, 'זכרנו ל[0]=' + idx_zochrenu_first);

// Build sections
// All before chadesh: introduction (always)
// chadesh: aseret_yemei_teshuva
// barech: fast_day & not aseret
// middle (between barech+1 and katvenu_first-1): always
// 5 katvenu lines: aseret_yemei_teshuva
// 5 zochrenu lines: fast_day & not aseret
// rest: always

// Sanity: katvenu lines are 5 contiguous, then zochrenu 5 contiguous
const katvenuLines = lines.slice(idx_katvenu_first, idx_katvenu_first + 5);
const zochrenuLines = lines.slice(idx_zochrenu_first, idx_zochrenu_first + 5);
console.log('  katvenu lines start:', katvenuLines[0].slice(0, 30));
console.log('  zochrenu lines start:', zochrenuLines[0].slice(0, 30));

const introBeforeChadesh = lines.slice(0, idx_chadesh);
const middleBlock = lines.slice(idx_barech + 1, idx_katvenu_first);
const tailBlock = lines.slice(idx_zochrenu_first + 5);

const newSections = [
  sec(introBeforeChadesh),                                              // always (intro)
  sec([lines[idx_chadesh]], ['aseret_yemei_teshuva']),                  // חדש
  sec([lines[idx_barech]], ['fast_day'], ['aseret_yemei_teshuva', 'tisha_beav']), // ברך
  sec(middleBlock),                                                     // always (middle)
  sec(katvenuLines, ['aseret_yemei_teshuva']),                          // 5 כתבנו
  sec(zochrenuLines, ['fast_day'], ['aseret_yemei_teshuva', 'tisha_beav']), // 5 זכרנו
  sec(tailBlock),                                                       // always (tail)
];

writeJson('assets/prayers/common/avinu_malkeinu.json', {
  id: 'avinu_malkeinu',
  sections: newSections,
});

newSections.forEach((s, i) => {
  const arr = Array.isArray(s.text) ? s.text : [s.text];
  console.log('    [' + i + '] lines=' + arr.length + ' cond=' + JSON.stringify(s.condition_flags) + ' excl=' + JSON.stringify(s.exclude_flags));
});

// ──────────────────────────────────────────────────────────────────────────────
// (2) Build nusach/edot_mizrach/avinu_malkeinu.json from Sefaria EM Mincha
// ──────────────────────────────────────────────────────────────────────────────

console.log('\n--- EM Avinu Malkeinu ---');
const em = JSON.parse(fs.readFileSync(path.join(PROJECT, '_em_minamida.json'), 'utf8'));
const emFlat = flatten(em.versions[0].text);

// EM Avinu Malkeinu lines: only Avinu Malkeinu lines themselves (skip rubrics
// and skip [105]-[106] which are non-AM verses said after amida on non-tachanun
// days — those go into yehi_shem.json below).
// Strip niqqud for matching marker substrings (the actual stored text keeps niqqud).
function stripNiqqud(s) { return s.replace(/[֑-ׇ]/g, ''); }

const emAmLines = [];
let katvenuStart = -1, katvenuEnd = -1;
for (let i = 73; i <= 104; i++) {
  const c = clean(emFlat[i]);
  if (c.length === 0) continue;
  // Strip an inline parenthetical kavvanah like "(יכוין בשם קר\"ע שט\"ן)"
  const stripped = c.replace(/\s*\([^)]*\)\s*$/, '').trim();
  emAmLines.push({ idx: i, text: stripped });
  const bare = stripNiqqud(stripped);
  // First כתבנו line is always "כתבנו בספר חיים טובים"
  if (bare.includes('כתבנו בספר חיים')) katvenuStart = emAmLines.length - 1;
  // Last כתבנו line in EM is "כתבנו בספר גאלה וישועה" (em_minamida[94]) -
  // niqqud-stripped form uses qubuts, so the bare form is "גאלה" not "גאולה".
  if (bare.includes('בספר גאלה') && katvenuStart >= 0) katvenuEnd = emAmLines.length - 1;
}
// Fallback: if we found a start but no explicit end, take the last contiguous
// line that still says "כתבנו" after katvenuStart.
if (katvenuStart >= 0 && katvenuEnd < 0) {
  let i = katvenuStart;
  while (i < emAmLines.length && stripNiqqud(emAmLines[i].text).includes('כתבנו')) i++;
  katvenuEnd = i - 1;
}
console.log('  EM Avinu lines:', emAmLines.length, 'katvenu range:', katvenuStart, '..', katvenuEnd);

const emIntro = emAmLines.slice(0, katvenuStart).map(l => sec(l.text)).flatMap(s => Array.isArray(s.text) ? s.text : [s.text]);
const emKatvenu = emAmLines.slice(katvenuStart, katvenuEnd + 1).flatMap(l => splitToArray(l.text));
const emTail = emAmLines.slice(katvenuEnd + 1).flatMap(l => splitToArray(l.text));

writeJson('assets/prayers/nusach/edot_mizrach/avinu_malkeinu.json', {
  id: 'avinu_malkeinu',
  sections: [
    sec(emIntro),                                  // always (intro)
    sec(emKatvenu, ['aseret_yemei_teshuva']),      // כתבנו lines
    sec(emTail),                                   // always (tail)
  ],
});

// ──────────────────────────────────────────────────────────────────────────────
// (3) Build nusach/edot_mizrach/yehi_shem.json from em_minamida[106]
// ──────────────────────────────────────────────────────────────────────────────

console.log('\n--- EM yehi_shem (post-amida, non-tachanun days) ---');
// em_minamida[106]: "יהי שם ה' מבורך מעתה ועד עולם... ואחר כך אומר הש''צ חצי קדיש"
// Strip trailing instruction sentence.
let yehiShem = clean(emFlat[106]);
// Trim trailing instructional Hebrew sentence (rubric-like) that begins after the last sof-pasuk.
yehiShem = yehiShem.replace(/׃[^׃]*אומר[^׃]*$/, '׃').trim();
console.log('  yehi_shem length:', yehiShem.length);

writeJson('assets/prayers/nusach/edot_mizrach/yehi_shem.json', {
  id: 'yehi_shem',
  sections: [sec(yehiShem)],
});

console.log('\nDONE.');
