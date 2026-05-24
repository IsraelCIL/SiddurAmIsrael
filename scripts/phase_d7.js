// Batch D.7 — Sefirat HaOmer (data layer only; Dart code changes in D.7b)
//
// Sources (cached in project root):
//   _ash_omer.json — Sefaria Siddur Ashkenaz, Weekday, Maariv, Sefirat HaOmer
//   _sef_omer.json — Sefaria Siddur Sefard, Weekday Maariv, Sefirat HaOmer
//   _em_omer.json  — Sefaria Siddur Edot HaMizrach, Counting of the Omer
//
// Architecture (per user-approved schema):
//   • `_omer_mapping.json` holds one entry per day (1..49) with the full
//     vocalized counting text per nusach, the sefira name, and the yismechu
//     letter. Ana/Lamenatzeach word positions are derivable from day number.
//   • Segment JSON files contain plain liturgical text. At assembly time, the
//     PrayerAssembler injects:
//       - day_count text from the mapping into `sefirat_haomer_day_count`
//       - `<b>...</b>` tokens around the day's word in Ana BeKoach and
//         Lamenatzeach (and around the yismechu letter inside Lamenatzeach)
//       - the day's sefira name into the placeholder in Ribono Shel Olam
//   • L'shem Yichud: per-nusach. EM has a SHORT (default, inline) and a LONG
//     (kabbalistic, accordion) version.
//   • HaRachaman: per-nusach (EM omits "לנו" and "סלה").
//   • Birshut Morai V'Rabotai (EM only): inserted before the bracha.
//
// Position in Maariv (per user):
//   Ashkenaz       — before Aleinu
//   Sfard          — between final Barchu and Aleinu
//   Edot Mizrach   — after Aleinu
//
// Run from project root:  node scripts/phase_d7.js

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
    .replace(/[֑-֯]/g, '')   // strip trope (cantillation)
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
function sec(text, opts = {}) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: opts.condition_flags || [],
    exclude_flags: opts.exclude_flags || [],
  };
}

// ─── Load Sefaria caches ───────────────────────────────────────────────────
const ash = readJson(path.join(PROJECT, '_ash_omer.json'));
const sef = readJson(path.join(PROJECT, '_sef_omer.json'));
const em  = readJson(path.join(PROJECT, '_em_omer.json'));
const aAll = flat(ash.versions[0].text).map(clean);
const sAll = flat(sef.versions[0].text).map(clean);
const eAll = flat(em.versions[0].text).map(clean);

// ─── Vocalized sefirot table (constructive form + "שב" form) ───────────────
const SEFIROT = [
  'חֶסֶד', 'גְּבוּרָה', 'תִּפְאֶרֶת', 'נֶצַח', 'הוֹד', 'יְסוֹד', 'מַלְכוּת',
];
const SEFIROT_SHE = [
  'שֶׁבְּחֶסֶד', 'שֶׁבִּגְבוּרָה', 'שֶׁבְּתִפְאֶרֶת',
  'שֶׁבְּנֶצַח', 'שֶׁבְּהוֹד', 'שֶׁבִּיסוֹד', 'שֶׁבְּמַלְכוּת',
];

// ─── Helpers to parse counting text out of each source ─────────────────────
function parseAshkSfardDay(entry) {
  // Pattern: "{date} {N}. {הַיּוֹם ... [בל]ָעֹמֶר}: {mapping}"
  const m = entry.match(/^(\S+(\s+\S+)?)\s+(\d+)\.\s+(.+)$/);
  if (!m) return null;
  const rest = m[4]; // "הַיּוֹם ... לָעֹֽמֶר: mapping"
  const colonIdx = rest.indexOf(':');
  const countText = rest.substring(0, colonIdx).trim() + ':';
  const mapping = rest.substring(colonIdx + 1).trim();
  return { countText, mapping };
}

function parseEmDay(dateEntry, countEntry, mappingEntry) {
  // EM format: counting is on its own entry already, prepended with "הַיּוֹם" implicitly.
  // Actual EM siddur convention pronounces "הַיּוֹם" — prepend it for parity with Ashk/Sfard.
  return {
    countText: 'הַיּוֹם ' + countEntry,
    mapping: mappingEntry,
  };
}

// ─── Parse all 49 days from all 3 nusachim ─────────────────────────────────
// EM mapping suffix format per day (entries [6 + 3*(d-1)]):
//   d % 7 !== 0:  "{ana_word} {sefira_word1} {sefira_word2} {lamenatz_word} {yism_letter}"
//   d % 7 === 0:  "{ana_acronym1} {ana_acronym2} {sefira_word1} {sefira_word2} {lamenatz_word} {yism_letter}"
//     (end-of-week → ana token is a 2-piece acronym like 'אב"ג ית"ץ')
function parseEmMapping(d, mappingText) {
  const tokens = mappingText.split(/\s+/);
  if (d % 7 === 0) {
    return {
      ana_word: tokens.slice(0, 2).join(' '),
      lamenatzeach_word: tokens[4],
      yismechu_letter: tokens[5],
    };
  }
  return {
    ana_word: tokens[0],
    lamenatzeach_word: tokens[3],
    yismechu_letter: tokens[4],
  };
}

const days = [];
for (let d = 1; d <= 49; d++) {
  const week = Math.ceil(d / 7);
  const dow = ((d - 1) % 7) + 1;
  const sefira = SEFIROT[dow - 1] + ' ' + SEFIROT_SHE[week - 1];

  // Ashk: entries [5..53], Sfard: [4..52]
  const ashParsed = parseAshkSfardDay(aAll[4 + d]);
  const sefParsed = parseAshkSfardDay(sAll[3 + d]);
  // EM: triplets starting at [4]: date=[4+3(d-1)], count=[5+3(d-1)], mapping=[6+3(d-1)]
  const emParsed = parseEmDay(
    eAll[4 + 3 * (d - 1)],
    eAll[5 + 3 * (d - 1)],
    eAll[6 + 3 * (d - 1)],
  );

  if (!ashParsed || !sefParsed) {
    throw new Error(`Failed to parse day ${d}: ash=${!!ashParsed}, sef=${!!sefParsed}`);
  }

  const emMapping = parseEmMapping(d, eAll[6 + 3 * (d - 1)]);

  days.push({
    day: d,
    week,
    day_in_week: dow,
    text_ashkenaz: ashParsed.countText,
    text_sfard: sefParsed.countText,
    text_edot_mizrach: emParsed.countText,
    sefira,
    ana_word: emMapping.ana_word,
    lamenatzeach_word: emMapping.lamenatzeach_word,
    yismechu_letter: emMapping.yismechu_letter,
  });
}

console.log('=== Parsed 49 days ===');
for (const d of [1, 7, 8, 14, 33, 49]) {
  const x = days[d - 1];
  console.log(`  day ${d}: sefira=${x.sefira} | ana=${x.ana_word} | lamenatz=${x.lamenatzeach_word} | yism=${x.yismechu_letter}`);
}

// ─── Write _omer_mapping.json ──────────────────────────────────────────────
const MAPPING_PATH = path.join(ASSETS, 'maariv', 'sefirat_haomer', '_omer_mapping.json');
writeJson(MAPPING_PATH, { days });
console.log(`\n  ${rel(MAPPING_PATH)}: ${days.length} days`);

// ─── Build segment files ───────────────────────────────────────────────────
const manifest = readJson(MANIFEST_PATH);

function ensureNusach(n) {
  if (!manifest.nusach[n]) manifest.nusach[n] = {};
}
['ashkenaz', 'sfard', 'edot_mizrach'].forEach(ensureNusach);

// ── L'shem Yichud per-nusach (SHORT, default inline) ──────────────────────
// Ashk: entries [1] (lshem yichud) + [2] (hineni mukhan) + [3] (vihi noam)
// Sfard: entries [1] (lshem yichud) + [2] (hineni mukhan)
// EM: the "short" variant inside entry [1], after the marker "יש אומרים נוסך קצרה"
{
  const ashLshem = aAll[1];
  const ashHineni = aAll[2];
  const ashVihiNoam = aAll[3];
  const ashCombined = [ashLshem, ashHineni, ashVihiNoam].join(' ');

  const sefLshem = sAll[1];
  const sefHineni = sAll[2];
  const sefCombined = [sefLshem, sefHineni].join(' ');

  // EM short version — find marker and extract after.
  const emFull = eAll[1];
  const marker = 'יש אומרים נוסך קצרה';
  const idx = emFull.indexOf(marker);
  if (idx < 0) throw new Error('EM short L\'shem Yichud marker not found');
  const emShort = emFull.substring(idx + marker.length).trim();
  const emLong  = emFull.substring(0, idx).trim();

  const entries = {
    ashkenaz: ashCombined,
    sfard: sefCombined,
    edot_mizrach: emShort,
  };
  for (const n of Object.keys(entries)) {
    const dst = path.join(
      ASSETS, 'maariv', 'sefirat_haomer', 'nusach', n, 'sefirat_haomer_lshem_yichud.json',
    );
    writeJson(dst, {
      id: 'sefirat_haomer_lshem_yichud',
      sections: [sec(entries[n])],
    });
    manifest.nusach[n].sefirat_haomer_lshem_yichud = rel(dst);
    console.log(`  ${n}: ${rel(dst)} (${entries[n].length} chars)`);
  }

  // EM long version (accordion).
  const dstLong = path.join(
    ASSETS, 'maariv', 'sefirat_haomer', 'nusach', 'edot_mizrach',
    'sefirat_haomer_lshem_yichud_long.json',
  );
  writeJson(dstLong, {
    id: 'sefirat_haomer_lshem_yichud_long',
    sections: [sec(emLong)],
  });
  manifest.nusach.edot_mizrach.sefirat_haomer_lshem_yichud_long = rel(dstLong);
  console.log(`  edot_mizrach (long): ${rel(dstLong)} (${emLong.length} chars)`);
}

// ── EM-only Birshut Morai V'Rabotai ───────────────────────────────────────
{
  const txt = eAll[2]; // 'הש"ץ אומר: בִּרְשׁוּת ... והקהל עונים: שָׁמַיִם'
  const dst = path.join(
    ASSETS, 'maariv', 'sefirat_haomer', 'nusach', 'edot_mizrach',
    'sefirat_haomer_birshut.json',
  );
  writeJson(dst, {
    id: 'sefirat_haomer_birshut',
    sections: [sec(txt)],
  });
  manifest.nusach.edot_mizrach.sefirat_haomer_birshut = rel(dst);
  console.log(`  edot_mizrach: ${rel(dst)} (${txt.length} chars)`);
}

// ── Bracha (shared) ────────────────────────────────────────────────────────
{
  // Use Ashk entry [4] (Sfard [3] is identical word-for-word). Trim trailing
  // "הַיּוֹם" if EM-source appended it as a hint (EM entry [3] does).
  let txt = aAll[4];
  // remove anything after the colon (the bracha ends with ":")
  const lastColon = txt.lastIndexOf(':');
  if (lastColon > 0) txt = txt.substring(0, lastColon + 1);
  const dst = path.join(
    ASSETS, 'maariv', 'sefirat_haomer', 'common', 'sefirat_haomer_bracha.json',
  );
  writeJson(dst, {
    id: 'sefirat_haomer_bracha',
    sections: [sec(txt)],
  });
  manifest.common.sefirat_haomer_bracha = rel(dst);
  console.log(`  common: ${rel(dst)} (${txt.length} chars)`);
}

// ── Day-count placeholder (assembler fills from _omer_mapping.json) ───────
{
  const dst = path.join(
    ASSETS, 'maariv', 'sefirat_haomer', 'common', 'sefirat_haomer_day_count.json',
  );
  writeJson(dst, {
    id: 'sefirat_haomer_day_count',
    sections: [{
      text: '{{omer_day_count}}',
      condition_flags: [],
      exclude_flags: [],
    }],
  });
  manifest.common.sefirat_haomer_day_count = rel(dst);
  console.log(`  common: ${rel(dst)} (placeholder)`);
}

// ── HaRachaman per-nusach ─────────────────────────────────────────────────
{
  const ashHaR = aAll[54]; // "הָרַחֲמָן הוּא יַחֲזִיר לָנוּ עֲבוֹדַת ... אָמֵן סֶֽלָה:"
  const sefHaR = sAll[53]; // similar to Ashk
  const emHaR  = eAll[151]; // "הָרַחֲמָן הוּא יַחֲזִיר עֲבוֹדַת ... בְיָמֵֽינוּ אָמֵן:" (no לנו, no סלה)
  const entries = { ashkenaz: ashHaR, sfard: sefHaR, edot_mizrach: emHaR };
  for (const n of Object.keys(entries)) {
    const dst = path.join(
      ASSETS, 'maariv', 'sefirat_haomer', 'nusach', n,
      'sefirat_haomer_harachaman.json',
    );
    writeJson(dst, {
      id: 'sefirat_haomer_harachaman',
      sections: [sec(entries[n])],
    });
    manifest.nusach[n].sefirat_haomer_harachaman = rel(dst);
    console.log(`  ${n}: ${rel(dst)} (${entries[n].length} chars)`);
  }
}

// ── Lamenatzeach (Psalm 67) — shared ──────────────────────────────────────
// The assembler will inject <b>...</b> around:
//   • the word at position `day` (in the psalm body, after the heading)
//   • the letter at position `day-1` inside the "ישמחו וירננו..." verse
{
  const txt = sAll[54]; // full Psalm 67 — same liturgical text in all nusachim
  const dst = path.join(
    ASSETS, 'maariv', 'sefirat_haomer', 'common', 'sefirat_haomer_lamenatzeach.json',
  );
  writeJson(dst, {
    id: 'sefirat_haomer_lamenatzeach',
    sections: [sec(txt)],
  });
  manifest.common.sefirat_haomer_lamenatzeach = rel(dst);
  console.log(`  common: ${rel(dst)} (${txt.length} chars)`);
}

// ── Ana BeKoach (shared, 7 lines) ─────────────────────────────────────────
// Assembler will inject <b>...</b> around word ((day-1) mod 7) of line
// ceil(day/7). On end-of-week (day % 7 === 0), it highlights the line's
// acronym (in parens).
{
  // Use Ashk entries [56..62] + [63] (Baruch Shem). Ashk lacks acronyms in
  // parens — we use the standard EM/Sephardic style with parenthetical
  // acronyms appended to each line.
  const ASHK_LINES = [aAll[56], aAll[57], aAll[58], aAll[59], aAll[60], aAll[61], aAll[62]];
  const ACRONYMS = [
    'אב"ג ית"ץ', 'קר"ע שט"ן', 'נג"ד יכ"ש',
    'בט"ר צת"ג', 'חק"ב טנ"ע', 'יג"ל פז"ק', 'שק"ו צי"ת',
  ];
  const lines = ASHK_LINES.map((l, i) => {
    // strip trailing ":" before appending acronym
    const base = l.replace(/[:׃]\s*$/, '');
    return `${base}: (${ACRONYMS[i]})`;
  });
  // Whispered Baruch Shem at end:
  lines.push('(בלחש) בָּרוּךְ שֵׁם כְּבוֹד מַלְכוּתוֹ לְעוֹלָם וָעֶד:');
  const dst = path.join(
    ASSETS, 'maariv', 'sefirat_haomer', 'common', 'sefirat_haomer_ana_bekoach.json',
  );
  writeJson(dst, {
    id: 'sefirat_haomer_ana_bekoach',
    sections: lines.map((l) => sec(l)),
  });
  manifest.common.sefirat_haomer_ana_bekoach = rel(dst);
  console.log(`  common: ${rel(dst)} (8 sections)`);
}

// ── Ribono Shel Olam (shared) ─────────────────────────────────────────────
// Standard text used in Ashk + Sfard + EM (with placeholder for the day's
// sefira). EM siddur on Sefaria omits this prayer but it appears in many
// Sephardic siddurim with very similar wording.
{
  const txt = aAll[64]; // Ashk full text with "(השייכת לאותו הלילה)" placeholder
  // Replace the parenthetical with our placeholder token.
  const withPlaceholder = txt.replace(/\(השייכת לאותו הלילה\)/, '{{omer_sefira}}');
  const dst = path.join(
    ASSETS, 'maariv', 'sefirat_haomer', 'common', 'sefirat_haomer_ribono_shel_olam.json',
  );
  writeJson(dst, {
    id: 'sefirat_haomer_ribono_shel_olam',
    sections: [sec(withPlaceholder)],
  });
  manifest.common.sefirat_haomer_ribono_shel_olam = rel(dst);
  console.log(`  common: ${rel(dst)} (${withPlaceholder.length} chars)`);
}

// ─── Build per-nusach sub-templates ────────────────────────────────────────
function buildSubTemplate(nusach) {
  const segments = [];
  // L'shem Yichud (short, inline)
  segments.push({ segment_id: 'sefirat_haomer_lshem_yichud' });
  // EM-only: long L'shem Yichud (accordion) + Birshut intro
  if (nusach === 'edot_mizrach') {
    segments.push({ segment_id: 'sefirat_haomer_lshem_yichud_long', optional: true });
    segments.push({ segment_id: 'sefirat_haomer_birshut' });
  }
  // Bracha
  segments.push({ segment_id: 'sefirat_haomer_bracha' });
  // Day count
  segments.push({ segment_id: 'sefirat_haomer_day_count' });
  // HaRachaman
  segments.push({ segment_id: 'sefirat_haomer_harachaman' });
  // Lamenatzeach, Ana BeKoach, Ribono Shel Olam (inline in all 3 nusachim)
  segments.push({ segment_id: 'sefirat_haomer_lamenatzeach' });
  segments.push({ segment_id: 'sefirat_haomer_ana_bekoach' });
  segments.push({ segment_id: 'sefirat_haomer_ribono_shel_olam' });

  const id = `sefirat_haomer_${nusach}`;
  const dst = path.join(PROJECT, 'assets', 'prayers', 'templates', 'maariv', `${id}.json`);
  writeJson(dst, {
    id,
    name: 'ספירת העומר',
    segments,
  });
  manifest.templates[id] = rel(dst);
  console.log(`  ${rel(dst)} (${segments.length} segments)`);
  return id;
}

console.log('\n=== Build sub-templates ===');
const subTemplateIds = {};
for (const n of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  subTemplateIds[n] = buildSubTemplate(n);
}

// ─── Update Maariv templates ──────────────────────────────────────────────
// Insert position:
//   Ashk — before aleinu (segment with segment_id === 'aleinu')
//   Sfard — before aleinu (which sits after the post-prayer barchu accordion)
//   EM    — after aleinu
console.log('\n=== Update Maariv templates ===');
function insertSefiratHaOmer(nusach, beforeAleinu) {
  const tp = path.join(PROJECT, manifest.templates[`maariv_${nusach}`]);
  const data = readJson(tp);
  const aleinuIdx = data.segments.findIndex((s) => s.segment_id === 'aleinu');
  if (aleinuIdx < 0) throw new Error(`aleinu not found in maariv_${nusach}`);
  const insertIdx = beforeAleinu ? aleinuIdx : aleinuIdx + 1;
  const entry = {
    sub_template_id: subTemplateIds[nusach],
    condition_flags: ['omer_period'],
    exclude_flags: [],
  };
  // Idempotent: remove any existing reference to our sub-template first.
  data.segments = data.segments.filter(
    (s) => s.sub_template_id !== subTemplateIds[nusach],
  );
  // Recompute aleinuIdx after filter (it may have shifted).
  const newAleinuIdx = data.segments.findIndex((s) => s.segment_id === 'aleinu');
  const finalIdx = beforeAleinu ? newAleinuIdx : newAleinuIdx + 1;
  data.segments.splice(finalIdx, 0, entry);
  writeJson(tp, data);
  console.log(`  maariv_${nusach}: inserted at idx ${finalIdx} (${beforeAleinu ? 'before' : 'after'} aleinu)`);
}
insertSefiratHaOmer('ashkenaz', true);
insertSefiratHaOmer('sfard', true);
insertSefiratHaOmer('edot_mizrach', false);

// ─── Write manifest ────────────────────────────────────────────────────────
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');
console.log('\nDONE.');
