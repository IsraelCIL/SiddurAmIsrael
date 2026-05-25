// Batch B: Hotzaat S"T + Hachnasat S"T restructure (per-nusach).
//
// HOTZAAT (kriat_hatorah_hotzaah):
//   - Ashkenaz / Sfard order:
//       Brich Shmei → Vayehi BiNso'a + Ki Mitzion + Baruch Shenatan →
//       Shema Yisrael + Echad Elokeinu (shema_hotzaah only) →
//       Gadlu LaShem (always) → Lecha Hashem HaGedullah →
//       Av HaRachamim Hu Yerachem → V'tigaleh V'teiraeh (Gabbai) →
//       קהל: V'atem HaDvekim.
//     Av HaRachamim + V'tigaleh + V'atem are NEW (user request).
//   - EM: completely different sequence sourced verbatim from Sefaria
//     Siddur Edot HaMizrach Torah Reading entry [6] — split into pesukim:
//       Baruch HaMakom → Ashrei HaAm → Gadlu → Romemu pasuk x2 → Ein Kadosh →
//       Ki Mi Eloah → Torah Tziva → Etz Chayim → Drachecha → Shalom Rav →
//       Hashem Oz LeAmo.
//
// HACHNASAT (kriat_hatorah_hachnasah):
//   - Ashkenaz / Sfard: Yehalelu (+ rubric "הקהל עונים:") → Hodo Al Eretz →
//     LeDavid Mizmor (Psalm 24 full) → Uvenucho Yomar + Kumah + Kohanecha +
//     Ba'avur David + Ki Lekach Tov → Etz Chayim + Drachecha + Hashivenu.
//     (Previously missing the bracketed pesukim between Uvenucho and Etz
//     Chayim — added from Sefaria Ashkenaz Uvenucho Yomar leaf.)
//   - EM: Sefaria has no dedicated "Returning Sefer to Aron" section for
//     EM. Most of what Ashk/Sfard recite at Hachnasah is bundled into the
//     EM Hotzaah block by Sefaria. For EM we write a brief minimal
//     Hachnasah file ("Hashem Oz LeAmo") so the segment exists; further
//     EM-specific Hachnasah text needs the user's siddur (flagged to the
//     user, not fabricated).
//
// Source caches (in project root, fetched earlier):
//   _ash_av_harachamim.json    _ash_vetigaleh.json    _ash_uvenucho.json
//   _ash_ledavid_mizmor.json   _ash_yehalelu.json
//   _sef_torah_reading_full.json   _em_torah_reading_full.json
//
// Run from project root:  node scripts/phase_b_hotzaah_hachnasah.js

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
    .replace(/[֑-֯]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}
function loadEntry(cacheFile, idx) {
  const d = readJson(path.join(PROJECT, cacheFile));
  return flat(d.versions[0].text).map(clean)[idx];
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
  const out = []; let cur = '';
  for (const s of small) {
    if (cur.length === 0) { cur = s; continue; }
    if ((cur + ' ' + s).length <= maxLen) cur += ' ' + s;
    else { out.push(cur); cur = s; }
  }
  if (cur) out.push(cur);
  return out;
}
function sec(text, conditionFlags = [], excludeFlags = []) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: conditionFlags,
    exclude_flags: excludeFlags,
  };
}
// Rubric helper (no niqqud → smaller font at render time, per project rule).
function rubric(text, conditionFlags = [], excludeFlags = []) {
  return {
    text,
    condition_flags: conditionFlags,
    exclude_flags: excludeFlags,
  };
}

const manifest = readJson(MANIFEST_PATH);

// ─── Pull Sefaria texts ────────────────────────────────────────────────────
const BRICH_SHMEI =
  // Ashkenaz/Sfard share this Aramaic Zohar passage; use the existing common
  // file's clean rendering (already split nicely; we will respect its line
  // breaks). We keep this as a single section in both per-nusach files.
  readJson(path.join(ASSETS, 'shacharit/acharei_amidah/common/kriat_hatorah_hotzaah.json'))
    .sections[0].text;

const VAYEHI_BINSOA_LINES =
  readJson(path.join(ASSETS, 'shacharit/acharei_amidah/common/kriat_hatorah_hotzaah.json'))
    .sections[1].text;

// Shema/Echad block (Hoshana Rabba etc.) — currently lives as section[2]
// of the common file. We will keep just the Shema/Echad pair here, and
// move Gadlu + Lecha to a separate (always-recited) section.
const SHEMA_HOTZAAH = [
  'שְׁמַע יִשְׂרָאֵל יְהֹוָה אֱלֹהֵינוּ יְהֹוָה אֶחָד:',
  'אֶחָד אֱלֹהֵינוּ גָּדוֹל אֲדוֹנֵינוּ קָדוֹשׁ שְׁמוֹ:',
];

const GADLU = ['גַּדְּלוּ לַיהֹוָה אִתִּי וּנְרוֹמְמָה שְׁמוֹ יַחְדָּו:'];

const LECHA_HASHEM = [
  'לְךָ יְהֹוָה הַגְּדֻלָּה וְהַגְּבוּרָה וְהַתִּפְאֶרֶת וְהַנֵּצַח וְהַהוֹד',
  'כִּי כֹל בַּשָּׁמַיִם וּבָאָרֶץ לְךָ יְהֹוָה הַמַּמְלָכָה',
  'וְהַמִּתְנַשֵּׂא לְכֹל לְרֹאשׁ:',
  'רוֹמְמוּ יְהֹוָה אֱלֹהֵינוּ וְהִשְׁתַּחֲווּ לַהֲדֹם רַגְלָיו קָדוֹשׁ הוּא:',
  'רוֹמְמוּ יְהֹוָה אֱלֹהֵינוּ וְהִשְׁתַּחֲווּ לְהַר קָדְשׁוֹ',
  'כִּי קָדוֹשׁ יְהֹוָה אֱלֹהֵינוּ:',
];

const AV_HARACHAMIM = loadEntry('_ash_av_harachamim.json', 0);
const VETIGALEH = loadEntry('_ash_vetigaleh.json', 1);
const VATEM_HADVEKIM = loadEntry('_ash_vetigaleh.json', 3);

const UVENUCHO_FULL = loadEntry('_ash_uvenucho.json', 0);
const LEDAVID_MIZMOR = loadEntry('_ash_ledavid_mizmor.json', 0);
const YEHALELU_MAIN = loadEntry('_ash_yehalelu.json', 1);
const HODO_AL_ERETZ = loadEntry('_ash_yehalelu.json', 2)
  .replace(/^קהל:\s*/, '');  // strip leading "קהל:" rubric — emitted as separate rubric below

const EM_HOTZAAH = loadEntry('_em_torah_reading_full.json', 6)
  .replace(/^שמוציאים ספר תורה אומרים\s*/, '');

// ─── Build Ashkenaz / Sfard Hotzaat (same content) ─────────────────────────
function buildAshSfardHotzaah() {
  return {
    id: 'kriat_hatorah_hotzaah',
    sections: [
      sec(BRICH_SHMEI),
      sec(VAYEHI_BINSOA_LINES),
      sec(SHEMA_HOTZAAH, ['shema_hotzaah']),
      sec(GADLU),
      sec(LECHA_HASHEM),
      sec(AV_HARACHAMIM),
      sec(VETIGALEH),
      rubric(['הקהל עונים:']),
      sec(VATEM_HADVEKIM),
    ],
  };
}

// ─── Build EM Hotzaat from Sefaria entry [6] ────────────────────────────────
function buildEmHotzaah() {
  // Split the long entry by ׃ (sof pasuk) or : into discrete pesukim. Each
  // pasuk becomes its own section so rendering can space them naturally.
  // We use the same matcher splitToArray uses (already handles ׃/:/. ).
  // First split on terminal punctuation followed by space:
  const cells = [];
  let buf = '';
  for (let i = 0; i < EM_HOTZAAH.length; i++) {
    buf += EM_HOTZAAH[i];
    const ch = EM_HOTZAAH[i];
    const next = EM_HOTZAAH[i + 1];
    if ((ch === '׃' || ch === ':') && (next === ' ' || next === undefined)) {
      cells.push(buf.trim());
      buf = '';
    }
  }
  if (buf.trim()) cells.push(buf.trim());
  // The first cell starts with "ברוך המקום..." — leave it intact.
  return {
    id: 'kriat_hatorah_hotzaah',
    sections: [
      rubric(['שמוציאים ספר תורה אומרים:']),
      ...cells.map((c) => sec(c)),
    ],
  };
}

// ─── Build Ashkenaz / Sfard Hachnasah ──────────────────────────────────────
function buildAshSfardHachnasah() {
  return {
    id: 'kriat_hatorah_hachnasah',
    sections: [
      rubric(['ואומר החזן:']),
      sec(YEHALELU_MAIN),
      rubric(['הקהל עונים:']),
      sec(HODO_AL_ERETZ),
      sec(LEDAVID_MIZMOR),
      sec(UVENUCHO_FULL),
    ],
  };
}

// ─── Build EM Hachnasah (minimal — full text not in Sefaria EM) ────────────
function buildEmHachnasah() {
  return {
    id: 'kriat_hatorah_hachnasah',
    sections: [
      rubric(['בעת החזרת ספר התורה להיכל אומרים:']),
      sec('יְהֹוָה עֹז לְעַמּוֹ יִתֵּן יְהֹוָה יְבָרֵךְ אֶת עַמּוֹ בַשָּׁלוֹם:'),
    ],
  };
}

// ─── Write everything per-nusach + remove common ───────────────────────────
console.log('=== Hotzaat S"T per-nusach ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const obj = nusach === 'edot_mizrach'
    ? buildEmHotzaah()
    : buildAshSfardHotzaah();
  const dst = path.join(
    ASSETS,
    'shacharit/acharei_amidah/nusach',
    nusach,
    'kriat_hatorah_hotzaah.json',
  );
  writeJson(dst, obj);
  manifest.nusach[nusach].kriat_hatorah_hotzaah = rel(dst);
  console.log(`  ${nusach}: ${obj.sections.length} sections`);
}
{
  const oldPath = manifest.common.kriat_hatorah_hotzaah;
  if (oldPath) {
    const abs = path.join(PROJECT, oldPath);
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
    delete manifest.common.kriat_hatorah_hotzaah;
    console.log(`  deleted ${oldPath}`);
  }
}

console.log('\n=== Hachnasat S"T per-nusach ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const obj = nusach === 'edot_mizrach'
    ? buildEmHachnasah()
    : buildAshSfardHachnasah();
  const dst = path.join(
    ASSETS,
    'shacharit/acharei_amidah/nusach',
    nusach,
    'kriat_hatorah_hachnasah.json',
  );
  writeJson(dst, obj);
  manifest.nusach[nusach].kriat_hatorah_hachnasah = rel(dst);
  console.log(`  ${nusach}: ${obj.sections.length} sections`);
}
{
  const oldPath = manifest.common.kriat_hatorah_hachnasah;
  if (oldPath) {
    const abs = path.join(PROJECT, oldPath);
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
    delete manifest.common.kriat_hatorah_hachnasah;
    console.log(`  deleted ${oldPath}`);
  }
}

// ─── Write manifest ────────────────────────────────────────────────────────
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(
  MANIFEST_PATH,
  JSON.stringify(sortKeys(manifest), null, 2) + '\n',
  'utf8',
);

console.log('\nDONE.');
