// Builds assets/prayers/nusach/edot_mizrach/hagbahah.json
// Source: Sefaria "Siddur Edot HaMizrach, Weekday Shacharit, Torah Reading 9"
// (the "lifting/showing" block; in EM it accompanies the procession-to-bimah,
// before reading - but logically belongs to hagbahah since it's said when the
// scroll is raised). EM diverges from Ashkenaz here in two ways:
//   1. The "וזאת התורה" verse is only the first half (no "על פי ה' ביד משה")
//   2. Two extra verses are added: Torah Tzivah (Deut 33:4), HaEl Tamim (Ps 18:31)
// Creating a per-nusach override file is cleaner than threading nusach
// condition_flags through the common file.

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';
const OUT_PATH = path.join(PROJECT, 'assets/prayers/nusach/edot_mizrach/hagbahah.json');

function stripHtml(t) { return t.replace(/<[^>]+>/g, ''); }
function stripTrope(t) { return t.replace(/[֑-֯]/g, ''); }
function normSpaces(t) { return t.replace(/\s+/g, ' ').trim(); }
function clean(t) { return normSpaces(stripTrope(stripHtml(t))); }

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

const d = JSON.parse(fs.readFileSync(path.join(PROJECT, 'em_tr_9.json'), 'utf8'));
const fullText = clean(Array.isArray(d.he) ? d.he.join(' ') : d.he);

// Split into verses on Hebrew sof pasuk ׃ (some verses end with ׃, some with :).
const verses = fullText.split(/(?<=[׃:])\s+/).filter(s => s.trim().length);
if (verses.length !== 3) {
  console.error('Expected 3 verses in tr_9, got', verses.length);
  process.exit(1);
}

function section(raw, condFlags = [], excludeFlags = []) {
  const arr = splitToArray(raw);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

const built = {
  id: 'hagbahah',
  sections: [
    section(verses[0]),  // וזאת התורה (EM: only first half)
    section(verses[1]),  // תורה צוה לנו משה
    section(verses[2]),  // האל תמים דרכו
  ],
};

fs.mkdirSync(path.dirname(OUT_PATH), { recursive: true });
fs.writeFileSync(OUT_PATH, JSON.stringify(built, null, 2) + '\n', 'utf8');

console.log('OK');
console.log('  sections:', built.sections.length);
built.sections.forEach((s, i) => {
  const isArr = Array.isArray(s.text);
  const totalLen = isArr ? s.text.join(' ').length : s.text.length;
  const maxLineLen = isArr ? Math.max(...s.text.map(x => x.length)) : s.text.length;
  console.log(`  [${i}] lines=${isArr ? s.text.length : 1} totalLen=${totalLen} maxLine=${maxLineLen}`);
});
console.log('  bytes written:', fs.statSync(OUT_PATH).size);
