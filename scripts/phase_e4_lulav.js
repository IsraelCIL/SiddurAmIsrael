// Phase E.4 — Birkat HaLulav + L'shem Yichud (Sukkot, before Hallel).
//
// Sources (per user, 2026-05-24):
//   • L'shem Yichud (Yehi Ratzon kavanah): Sefaria Siddur Sefard, Shaking Lulav 3
//   • Birkat HaLulav + Shehechiyanu: Sefaria Siddur Ashkenaz, Festivals, Sukkot
//
// Per user, content is identical across all three nusachim for now (he will
// flag if EM diverges). Stored under `common/` for de-duplication.
//
// Output:
//   • assets/prayers/shacharit/acharei_amidah/common/lulav_lshem_yichud.json
//   • assets/prayers/shacharit/acharei_amidah/common/lulav_bracha.json
//   • Manifest: registered under `common`
//   • Templates: acharei_amidah_<nusach>.json get two new entries inserted
//     immediately before the existing `hallel` segment, gated on `lulav_day`.
//
// Run from project root:  node scripts/phase_e4_lulav.js

const fs = require('fs');
const path = require('path');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const COMMON_DIR = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

// ── Texts ────────────────────────────────────────────────────────────────────

// Sfard, Shaking Lulav 3 — split at natural clause boundaries.
const LSHEM_YICHUD_TEXT = [
  'יְהִי רָצוֹן מִלְּפָנֶיךָ יְהֹוָה אֱלֹהַי וֵאלֹהֵי אֲבוֹתַי,',
  'בִּפְרִי עֵץ הָדָר וְכַפֹּת תְּמָרִים וַעֲנַף עֵץ עָבוֹת וְעַרְבֵי נָחַל',
  'אוֹתִיּוֹת שִׁמְךָ הַמְּיֻחָד תְּקָרֵב אֶחָד אֶל אֶחָד',
  'וְהָיוּ לַאֲחָדִים בְּיָדִי וְלֵידַע אֵיךְ שִׁמְךָ נִקְרָא עָלַי',
  'וְיִירְאוּ מִגֶּשֶּׁת אֵלַי',
  'וּבְנַעֲנוּעִי אוֹתָם תַּשְׁפִּיעַ שֶׁפַע בְּרָכוֹת',
  'מִדַּעַת עֶלְיוֹן לִנְוֵה אַפִּרְיוֹן לִמְכוֹן בֵּית אֱלֹהֵינוּ,',
  'וּתְהֵא חֲשׁוּבָה לְפָנֶיךָ מִצְוַת אַרְבָּעָה מִינִים אֵלּוּ,',
  'כְּאִלּוּ קִיַּמְתִּיהָ בְּכָל פְּרָטוֹתֶיהָ וְשָׁרָשֶׁיהָ',
  'וְתַרְיַ"ג מִצְוֹת הַתְּלוּיִם בָּהּ.',
  'כִּי כַוָּנָתִי לְיַחֲדָא שְׁמָא דְקוּדְשָׁא בְּרִיךְ הוּא וּשְׁכִינְתֵּיהּ',
  'בִּדְחִילוּ וּרְחִימוּ לְיַחֵד שֵׁם י"ה בּו"ה בְּיִחוּדָא שְׁלִים',
  'בְּשֵׁם כָּל יִשְׂרָאֵל אָמֵן:',
  'בָּרוּךְ יְהֹוָה לְעוֹלָם אָמֵן וְאָמֵן:',
];

// Ashkenaz, Festivals, Sukkot, Blessing on Lulav.
const BIRKAT_LULAV_TEXT = [
  'בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם,',
  'אֲשֶׁר קִדְּשָׁנוּ בְּמִצְוֹתָיו, וְצִוָּנוּ עַל נְטִילַת לוּלָב:',
];

// Header line lifted verbatim from Sefaria Ashkenaz source — printed as an
// in-text instruction so the user knows to add Shehechiyanu on the first
// time only.
const SHEHECHIYANU_HEADER = 'בפעם הראשון שמברך על הלולב מברך גם שהחיינו:';
const SHEHECHIYANU_TEXT = [
  'בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם,',
  'שֶׁהֶחֱיָנוּ וְקִיְּמָנוּ וְהִגִּיעָנוּ לַזְמַן הַזֶּה:',
];

// ── Write segment files ──────────────────────────────────────────────────────

const lshemYichudPath = path.join(COMMON_DIR, 'lulav_lshem_yichud.json');
writeJson(lshemYichudPath, {
  id: 'lulav_lshem_yichud',
  sections: [
    {
      text: LSHEM_YICHUD_TEXT,
      condition_flags: [],
      exclude_flags: [],
    },
  ],
});

const birkatLulavPath = path.join(COMMON_DIR, 'lulav_bracha.json');
writeJson(birkatLulavPath, {
  id: 'lulav_bracha',
  sections: [
    {
      // Birkat Netilat Lulav — always recited on lulav_day.
      text: BIRKAT_LULAV_TEXT,
      condition_flags: [],
      exclude_flags: [],
    },
    {
      // Shehechiyanu — printed with the standard "first time only"
      // instruction header. Halachically said only the very first time one
      // takes the lulav each season (typically first day of Sukkot).
      text: [SHEHECHIYANU_HEADER, ...SHEHECHIYANU_TEXT],
      condition_flags: [],
      exclude_flags: [],
    },
  ],
});

// ── Register in manifest ─────────────────────────────────────────────────────

const manifest = readJson(MANIFEST_PATH);
manifest.common['lulav_lshem_yichud'] = rel(lshemYichudPath);
manifest.common['lulav_bracha'] = rel(birkatLulavPath);

// ── Inject into acharei_amidah_<nusach> templates ────────────────────────────

const TEMPLATES_DIR = path.join(ASSETS, 'templates', 'shacharit');
const NUSACHIM = ['ashkenaz', 'sfard', 'edot_mizrach'];

let injectedCount = 0;
for (const n of NUSACHIM) {
  const tplPath = path.join(TEMPLATES_DIR, `acharei_amidah_${n}.json`);
  const tpl = readJson(tplPath);
  // Skip if already injected (idempotent re-runs).
  if (tpl.segments.some((s) => s.segment_id === 'lulav_bracha')) {
    console.log(`  ${rel(tplPath)}: lulav already present — skipped`);
    continue;
  }
  const hallelIdx = tpl.segments.findIndex((s) => s.segment_id === 'hallel');
  if (hallelIdx < 0) {
    throw new Error(`hallel segment not found in ${rel(tplPath)}`);
  }
  const newEntries = [
    {
      segment_id: 'lulav_lshem_yichud',
      condition_flags: ['lulav_day'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    },
    {
      segment_id: 'lulav_bracha',
      condition_flags: ['lulav_day'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    },
  ];
  tpl.segments.splice(hallelIdx, 0, ...newEntries);
  writeJson(tplPath, tpl);
  injectedCount++;
  console.log(`  ${rel(tplPath)}: inserted lulav_lshem_yichud + lulav_bracha before hallel`);
}

// ── Sort + persist manifest ──────────────────────────────────────────────────

function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

console.log(`\nWrote: ${rel(lshemYichudPath)}`);
console.log(`Wrote: ${rel(birkatLulavPath)}`);
console.log(`Templates patched: ${injectedCount}/${NUSACHIM.length}`);
console.log('\nDONE.');
