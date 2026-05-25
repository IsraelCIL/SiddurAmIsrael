// Builds assets/prayers/nusach/edot_mizrach/kriat_hatorah_hotzaah.json
// Source: Sefaria "Siddur Edot HaMizrach, Weekday Shacharit, Torah Reading"
//   tr_3 + tr_4 = El Erech Apayim (EM version, 2 stanzas) - days with Tachanun
//   tr_6        = Yehi Hashem (Psalms verses) - days WITHOUT Tachanun
//   tr_7        = main procession block (the EM equivalent that replaces Berich Shmei)
// Note: Vezot HaTorah + Torah Tzivah + HaEl Tamim (tr_9) goes into hagbahah.json
// since it accompanies the lifting/showing of the Torah, not the procession itself.
// All Hebrew text processing on disk - nothing flows through assistant response.

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';
const OUT_PATH = path.join(PROJECT, 'assets/prayers/nusach/edot_mizrach/kriat_hatorah_hotzaah.json');

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
    if ((ch === ':' || ch === '.' || ch === ',') && (next === ' ' || next === undefined)) {
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
  const arr = splitToArray(clean(textRaw));
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

function readTr(n) {
  const p = path.join(PROJECT, `em_tr_${n}.json`);
  const d = JSON.parse(fs.readFileSync(p, 'utf8'));
  // d.he can be a string OR an array of strings (mostly single-element array here)
  return Array.isArray(d.he) ? d.he.join(' ') : d.he;
}

// El Erech Apayim - EM version, 2 stanzas, said on days with Tachanun
// (= NOT said on skip_tachanun days)
const elErech1 = section(readTr(3), [], ['skip_tachanun']);
const elErech2 = section(readTr(4), [], ['skip_tachanun']);

// Yehi Hashem - said on days WITHOUT Tachanun
const yehiHashem = section(readTr(6), ['skip_tachanun'], []);

// Main procession block (the EM equivalent of "what is said when taking out the Torah",
// replacing the Ashkenazi Berich Shmei). Always said.
const procession = section(readTr(7), [], []);

const built = {
  id: 'kriat_hatorah_hotzaah',
  sections: [elErech1, elErech2, yehiHashem, procession],
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
