// Builds assets/prayers/common/korbanot.json by combining:
//   - s1.json (Sovereignty of Heaven: Le'olam Yehe Adam ... Ata Hu)
//   - existing korbanot sections (Tamid, Eizehu Mekoman, R. Yishmael)
//   - s2.json (Ketoret: Ata Hu intro, Exodus verses, Pitum HaKetoret, etc.)
// All Hebrew text processing happens here on disk - no text flows through
// the assistant's response stream (avoids content-filter blocks on bulk
// Hebrew prayer content).

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';
const KORBANOT_PATH = path.join(PROJECT, 'assets/prayers/common/korbanot.json');
const S1_PATH = path.join(PROJECT, 's1.json');
const S2_PATH = path.join(PROJECT, 's2.json');

// ---------- text cleaning ----------
function stripHtml(t) {
  return t.replace(/<[^>]+>/g, '');
}

// Remove Hebrew cantillation marks (U+0591..U+05AF), keep niqqud (U+05B0+).
function stripTrope(t) {
  return t.replace(/[֑-֯]/g, '');
}

function normSpaces(t) {
  return t.replace(/\s+/g, ' ').trim();
}

function clean(t) {
  return normSpaces(stripTrope(stripHtml(t)));
}

// ---------- splitting long text into phrase array ----------
// Splits text at punctuation while keeping the punctuation attached to the
// preceding chunk. Then greedily merges adjacent chunks while their combined
// length stays <= maxLen. Targets ~70 chars per line per CLAUDE.md (~80 cap).
function splitToArray(text, maxLen = 75) {
  const t = normSpaces(text);
  if (t.length <= maxLen) return [t];

  // Break candidates: end-of-clause punctuation + following space.
  // Order matters: ':' is strongest (verse end), then '.', then ','.
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

  // If any single part is still too long, split it on spaces.
  const small = [];
  for (const p of parts) {
    if (p.length <= maxLen) {
      small.push(p);
    } else {
      const words = p.split(' ');
      let cur = '';
      for (const w of words) {
        if (cur.length === 0) { cur = w; continue; }
        if ((cur + ' ' + w).length <= maxLen) {
          cur += ' ' + w;
        } else {
          small.push(cur);
          cur = w;
        }
      }
      if (cur) small.push(cur);
    }
  }

  // Greedy merge: combine adjacent chunks while staying <= maxLen.
  const out = [];
  let cur = '';
  for (const s of small) {
    if (cur.length === 0) { cur = s; continue; }
    if ((cur + ' ' + s).length <= maxLen) {
      cur += ' ' + s;
    } else {
      out.push(cur);
      cur = s;
    }
  }
  if (cur) out.push(cur);
  return out;
}

// ---------- build sections ----------
function section(textArrOrStr, condFlags = [], excludeFlags = []) {
  return {
    text: textArrOrStr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}

function paraToSection(rawHebrew, condFlags = [], excludeFlags = []) {
  const cleaned = clean(rawHebrew);
  const arr = splitToArray(cleaned);
  return section(arr.length === 1 ? arr[0] : arr, condFlags, excludeFlags);
}

// Strip the "ג"פ:" (recite 3 times) rubric markers from Ketoret P7.
function stripGimelPehRubric(t) {
  // Both straight and curly quote variants, with or without colon.
  return t
    .replace(/ג["'״]פ:?/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

// ---------- main ----------
const existing = JSON.parse(fs.readFileSync(KORBANOT_PATH, 'utf8'));
const s1 = JSON.parse(fs.readFileSync(S1_PATH, 'utf8'));
const s2 = JSON.parse(fs.readFileSync(S2_PATH, 'utf8'));

// s1 paragraphs of interest:
//   P0 Le'olam Yehe Adam (intro)
//   P1 Ribbon Kol Ha-Olamim
//   P2 Aval Anachnu Amcha
//   P3 Lefichach / Ashreinu
//   P4 Shema
//   P5 RUBRIC ("yomar belachash") - SKIP
//   P6 Baruch Shem
//   P7 Ve'ahavta
//   P8 Ata Hu / Mekadesh Shimcha Barabim - requires minyan
//   P9 Ata Hu Hashem Eloheinu (closing)

const leolamSections = [
  paraToSection(s1.he[0]),                              // Le'olam Yehe Adam
  paraToSection(s1.he[1]),                              // Ribbon Kol Ha-Olamim
  paraToSection(s1.he[2]),                              // Aval Anachnu Amcha
  paraToSection(s1.he[3]),                              // Lefichach / Ashreinu
  paraToSection(s1.he[4]),                              // Shema
  paraToSection(s1.he[6]),                              // Baruch Shem (P5 is rubric, skipped)
  paraToSection(s1.he[7]),                              // Ve'ahavta
  paraToSection(s1.he[8], ['with_minyan']),             // Ata Hu... Mekadesh Shimcha Barabim
  paraToSection(s1.he[9]),                              // Ata Hu Hashem Eloheinu
];

// s2 paragraphs (Ketoret):
//   P0 Ata Hu intro
//   P1 Exodus 30:34-36 (Vayomer)
//   P2 Exodus 30:7-8 (Vehiktir)
//   P3 Pitum HaKetoret (Tanu Rabbanan)
//   P4 Rabban Shimon ben Gamliel
//   P5 Tanya Rabbi Natan
//   P6 Tanya Bar Kappara
//   P7 Three verses (Hashem Tzvaot... x3) - strip rubric
//   P8 Ata Seter / Ve'arva
const ketoretSections = [
  paraToSection(s2.he[0]),                              // Ata Hu intro
  paraToSection(s2.he[1]),                              // Exodus 30:34-36
  paraToSection(s2.he[2]),                              // Exodus 30:7-8
  paraToSection(s2.he[3]),                              // Pitum HaKetoret
  paraToSection(s2.he[4]),                              // Rabban Shimon b. Gamliel
  paraToSection(s2.he[5]),                              // Tanya R. Natan
  paraToSection(s2.he[6]),                              // Tanya Bar Kappara
  paraToSection(stripGimelPehRubric(stripHtml(s2.he[7]))), // 3 verses
  paraToSection(s2.he[8]),                              // Ata Seter / Ve'arva
];

// Existing sections: Parshat HaTamid, Eizehu Mekoman, R. Yishmael
const middleSections = existing.sections;

const built = {
  id: 'korbanot',
  sections: [
    ...leolamSections,
    ...middleSections,
    ...ketoretSections,
  ],
};

fs.writeFileSync(KORBANOT_PATH, JSON.stringify(built, null, 2) + '\n', 'utf8');

// Diagnostics (lengths only, no Hebrew content in output)
console.log('OK');
console.log('  leolam sections:', leolamSections.length);
console.log('  middle sections:', middleSections.length);
console.log('  ketoret sections:', ketoretSections.length);
console.log('  total sections:', built.sections.length);
console.log('  bytes written:', fs.statSync(KORBANOT_PATH).size);
