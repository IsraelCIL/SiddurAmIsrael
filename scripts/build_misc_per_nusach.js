// User-requested fixes:
//   • hashem_melech — the current common/hashem_melech.json has the wrong text
//     (a fragment of Yehi Kevod). Replace with the correct passage from Sefaria
//     Siddur_Sefard,_Weekday_Shacharit,_Hodu.10 (only Sfard + EM say it).
//   • hashem_tzvaot_maariv — said only in Sfard + EM Maariv (Ashkenaz omits).
//     Move from common to per-nusach.
//   • hashkivenu — Maariv blessing; varies per nusach. Build per-nusach files.

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';

function stripHtml(t) { return (t || '').replace(/<[^>]+>/g, ''); }
function stripTrope(t) { return t.replace(/[֑-֯]/g, ''); }
function normSpaces(t) { return t.replace(/\s+/g, ' ').trim(); }
function clean(t) { return normSpaces(stripTrope(stripHtml(t))); }
function flatten(x) { return Array.isArray(x) ? x.flatMap(flatten) : [x]; }
function loadSefaria(key) {
  const d = JSON.parse(fs.readFileSync(path.join(PROJECT, `_${key}.json`), 'utf8'));
  return flatten(d.versions[0].text).map(clean);
}

function splitToArray(text, maxLen = 75) {
  const t = normSpaces(text);
  if (t.length <= maxLen) return [t];
  const parts = [];
  let buf = '';
  for (let i = 0; i < t.length; i++) {
    buf += t[i];
    const ch = t[i], next = t[i+1];
    if ((ch===':'||ch==='.'||ch===','||ch==='׃') && (next===' '||next===undefined)) {
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

function sec(text, condFlags = [], excludeFlags = []) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
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
  console.log(`  ${relPath} maxLine=${maxLine}`);
}

// ─── (1) hashem_melech — correct source (Sfard Hodu.10) ──────────────────────
// Used only in Sfard + EM Shacharit (templates confirm Ashkenaz doesn't say it).
// Sefaria only exposes the Sfard version; EM Sefaria uses the same liturgical
// passage but it's bundled into Hodu/Pesukei Dezimra rather than as its own
// section. We use the Sfard text for both nusachim (per user instruction this
// is correct for both).

console.log('\n=== hashem_melech (correct source, Sfard + EM only) ===');
const hashemMelech = loadSefaria('hashem_melech');  // 1 entry, 281 chars
console.log('  source has', hashemMelech.length, 'entries; first len=' + (hashemMelech[0] || '').length);
const melechText = hashemMelech.find(t => t.length > 50);
writeSeg('assets/prayers/nusach/sfard/hashem_melech.json', 'hashem_melech', [sec(melechText)]);
writeSeg('assets/prayers/nusach/edot_mizrach/hashem_melech.json', 'hashem_melech', [sec(melechText)]);

// Delete the wrong common/hashem_melech.json
const wrongMelech = path.join(PROJECT, 'assets/prayers/common/hashem_melech.json');
if (fs.existsSync(wrongMelech)) {
  fs.unlinkSync(wrongMelech);
  console.log('  deleted common/hashem_melech.json (wrong content)');
}

// ─── (2) hashem_tzvaot_maariv — Sfard + EM only ───────────────────────────────
// Verses said at start of Maariv ("ה' צבאות עמנו... ה' צבאות אשרי אדם בוטח בך
// ... ה' הושיעה המלך יעננו ביום קראנו"). Templates show Sfard + EM use it,
// Ashkenaz doesn't.
// Move common → per-nusach (Sfard + EM both get the same text).

console.log('\n=== hashem_tzvaot_maariv (Sfard + EM only) ===');
const oldTzvaotPath = path.join(PROJECT, 'assets/prayers/common/hashem_tzvaot_maariv.json');
if (fs.existsSync(oldTzvaotPath)) {
  const old = JSON.parse(fs.readFileSync(oldTzvaotPath, 'utf8'));
  const text = old.sections[0].text;
  const flatText = Array.isArray(text) ? text.join(' ') : text;
  writeSeg('assets/prayers/nusach/sfard/hashem_tzvaot_maariv.json', 'hashem_tzvaot_maariv', [sec(flatText)]);
  writeSeg('assets/prayers/nusach/edot_mizrach/hashem_tzvaot_maariv.json', 'hashem_tzvaot_maariv', [sec(flatText)]);
  fs.unlinkSync(oldTzvaotPath);
  console.log('  deleted common/hashem_tzvaot_maariv.json');
}

// ─── (3) hashkivenu — per nusach (all 3) ──────────────────────────────────────
// Sources:
//   Ashkenaz: _ash_hashkivenu.json   (Sefaria: Siddur Ashkenaz, Weekday, Maariv, Blessings of the Shema, Second Blessing after Shema)
//   Sefard:   _sef_maariv_shema.json[25]
//   EM:       _em_arvit_shema.json[10]

console.log('\n=== hashkivenu per nusach ===');

const ashHk = loadSefaria('ash_hashkivenu');
// Find the actual bracha (longest non-rubric entry — rubrics are short).
const ashText = ashHk.filter(t => t.length > 100).sort((a, b) => b.length - a.length)[0];
if (ashText) writeSeg('assets/prayers/nusach/ashkenaz/hashkivenu.json', 'hashkivenu', [sec(ashText)]);
else console.log('  !! ashkenaz hashkivenu not found');

const sefMaariv = loadSefaria('sef_maariv_shema');
const sefHashk = sefMaariv[25];
if (sefHashk) writeSeg('assets/prayers/nusach/sfard/hashkivenu.json', 'hashkivenu', [sec(sefHashk)]);

const emArvit = loadSefaria('em_arvit_shema');
const emHashk = emArvit[10];
if (emHashk) writeSeg('assets/prayers/nusach/edot_mizrach/hashkivenu.json', 'hashkivenu', [sec(emHashk)]);

// Delete common/hashkivenu.json (now superseded by per-nusach versions).
const oldHashk = path.join(PROJECT, 'assets/prayers/common/hashkivenu.json');
if (fs.existsSync(oldHashk)) {
  fs.unlinkSync(oldHashk);
  console.log('  deleted common/hashkivenu.json');
}

console.log('\nDONE.');
