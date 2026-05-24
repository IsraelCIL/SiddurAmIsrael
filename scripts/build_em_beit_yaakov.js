// Builds assets/prayers/nusach/edot_mizrach/beit_yaakov.json
// Source: Sefaria "Siddur Edot HaMizrach, Weekday Shacharit, Beit Yaakov"
// Said after Kaddish Titkabal on days with Torah reading (Mon/Thu),
// when returning the Torah to the ark.
//
//   by_3 = Tefilah LeDavid = Psalm 86. Rubric (by_2) states:
//          "On days when Tachanun is not said, Tefilah LeDavid is not said."
//          => exclude_flags: ["skip_tachanun"]
//   by_4 = Beit Yaakov verses (Isaiah 2:5, Micah 4:5, I Kings 8:57-60, etc.) - always
//   by_5 = Shir (Psalm 124) - always

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';
const OUT_PATH = path.join(PROJECT, 'assets/prayers/nusach/edot_mizrach/beit_yaakov.json');

function stripHtml(t) { return t.replace(/<[^>]+>/g, ''); }
function stripTrope(t) { return t.replace(/[֑-֯]/g, ''); }
function normSpaces(t) { return t.replace(/\s+/g, ' ').trim(); }
function clean(t) { return normSpaces(stripTrope(stripHtml(t))); }

// Strip Sefaria's parenthetical chapter/verse refs like "(תהלים פו)" or
// "(תהילים קכ״ד:א)" which sometimes appear at the start of a section.
function stripChapterRef(t) {
  return t.replace(/^\s*\([^)]*\)\s*/, '').trim();
}

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

function section(textRaw, condFlags = [], excludeFlags = []) {
  const arr = splitToArray(stripChapterRef(clean(textRaw)));
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

function readBy(n) {
  const p = path.join(PROJECT, `em_by_${n}.json`);
  const d = JSON.parse(fs.readFileSync(p, 'utf8'));
  return Array.isArray(d.he) ? d.he.join(' ') : d.he;
}

const tefilahLeDavid = section(readBy(3), [], ['skip_tachanun']);
const beitYaakov = section(readBy(4));
const psalm124 = section(readBy(5));

const built = {
  id: 'beit_yaakov',
  sections: [tefilahLeDavid, beitYaakov, psalm124],
};

fs.mkdirSync(path.dirname(OUT_PATH), { recursive: true });
fs.writeFileSync(OUT_PATH, JSON.stringify(built, null, 2) + '\n', 'utf8');

console.log('OK');
console.log('  sections:', built.sections.length);
built.sections.forEach((s, i) => {
  const isArr = Array.isArray(s.text);
  const totalLen = isArr ? s.text.join(' ').length : s.text.length;
  const maxLineLen = isArr ? Math.max(...s.text.map(x => x.length)) : s.text.length;
  console.log(`  [${i}] lines=${isArr ? s.text.length : 1} totalLen=${totalLen} maxLine=${maxLineLen} cond=${JSON.stringify(s.condition_flags)} excl=${JSON.stringify(s.exclude_flags)}`);
});
console.log('  bytes written:', fs.statSync(OUT_PATH).size);
