// Batch D.1 — small follow-ups on Batch C:
//   1. Adon Olam EM: extended Sephardic text (15 verses). Per-nusach with
//      the EM template entry marked optional (accordion).
//   2. Birkat Tzitzit Katan EM: remove (EM siddur only shows Tallit Gadol).
//      Delete the file and remove the template entry.
//   3. Split common/adon_olam.json → per-nusach so each nusach has its own
//      file. Ashkenaz+Sfard keep the current 10-verse Ashkenaz text.
//
// Run from project root:  node scripts/phase_d1.js

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

const manifest = readJson(MANIFEST_PATH);

// ─── 1. Adon Olam per-nusach (split common) ────────────────────────────────
console.log('=== 1. adon_olam per-nusach ===');
{
  // Existing Ashkenaz text from current common file.
  const commonPath = path.join(PROJECT, manifest.common.adon_olam);
  const commonData = readJson(commonPath);
  const ashSfardSections = commonData.sections;

  // EM extended version — 15 verses (each ≤75 chars, split at commas).
  const emLines = [
    'אֲדוֹן עוֹלָם אֲשֶׁר מָלַךְ, בְּטֶרֶם כָּל יְצִיר נִבְרָא:',
    'לְעֵת נַעֲשָׂה בְחֶפְצוֹ כֹּל, אֲזַי מֶלֶךְ שְׁמוֹ נִקְרָא:',
    'וְאַחֲרֵי כִּכְלוֹת הַכֹּל, לְבַדּוֹ יִמְלֹךְ נוֹרָא:',
    'וְהוּא הָיָה וְהוּא הוֹוֶה, וְהוּא יִהְיֶה בְּתִפְאָרָה:',
    'וְהוּא אֶחָד וְאֵין שֵׁנִי, לְהַמְשִׁילוֹ וּלְהַחְבִּירָה:',
    'בְּלִי רֵאשִׁית בְּלִי תַכְלִית, וְלוֹ הָעֹז וְהַמִּשְׂרָה:',
    'בְּלִי עֵרֶךְ בְּלִי דִּמְיוֹן, בְּלִי שִׁנּוּי וּתְמוּרָה:',
    'בְּלִי חִבּוּר בְּלִי פֵרוּד, גְּדָל כֹּחַ וּגְבוּרָה:',
    'וְהוּא אֵלִי וְחַי גּוֹאֲלִי, וְצוּר חֶבְלִי בְּיוֹם צָרָה:',
    'וְהוּא נִסִּי וּמָנוֹס לִי, מְנָת כּוֹסִי בְּיוֹם אֶקְרָא:',
    'וְהוּא רוֹפֵא וְהוּא מַרְפֵּא, וְהוּא צוֹפֶה וְהוּא עֶזְרָה:',
    'בְּיָדוֹ אַפְקִיד רוּחִי, בְּעֵת אִישַׁן וְאָעִירָה:',
    'וְעִם רוּחִי גְּוִיָּתִי, אֲדֹנָי לִי וְלֹא אִירָא:',
    'בְּמִקְדָּשׁוֹ תָּגֵל נַפְשִׁי, מְשִׁיחֵנוּ יִשְׁלַח מְהֵרָה:',
    'וְאָז נָשִׁיר בְּבֵית קָדְשִׁי, אָמֵן אָמֵן שֵׁם הַנּוֹרָא:',
  ];

  const variants = {
    ashkenaz: ashSfardSections,
    sfard:    ashSfardSections,
    edot_mizrach: [
      { text: emLines, condition_flags: [], exclude_flags: [] },
    ],
  };

  for (const n of Object.keys(variants)) {
    const dst = path.join(
      ASSETS, 'shacharit/lifnei_hatfila/nusach', n, 'adon_olam.json'
    );
    writeJson(dst, { id: 'adon_olam', sections: variants[n] });
    manifest.nusach[n].adon_olam = rel(dst);
    console.log(`  ${n}: ${rel(dst)}`);
  }

  // Delete the common file.
  if (fs.existsSync(commonPath)) fs.unlinkSync(commonPath);
  delete manifest.common.adon_olam;
  console.log(`  deleted ${rel(commonPath)}`);
}

// ─── 2. Remove EM birkat_tzitzit_katan ─────────────────────────────────────
console.log('\n=== 2. remove EM birkat_tzitzit_katan ===');
{
  const p = manifest.nusach.edot_mizrach.birkat_tzitzit_katan;
  if (p) {
    const abs = path.join(PROJECT, p);
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
    delete manifest.nusach.edot_mizrach.birkat_tzitzit_katan;
    console.log(`  deleted ${p}`);
  } else {
    console.log('  not present');
  }
}

// ─── 3. EM template — remove birkat_tzitzit_katan entry, mark adon_olam optional ─
console.log('\n=== 3. EM shacharit template patches ===');
{
  const tp = path.join(PROJECT, manifest.templates.shacharit_edot_mizrach);
  const data = readJson(tp);

  // Remove birkat_tzitzit_katan entry.
  const before = data.segments.length;
  data.segments = data.segments.filter((s) => s.segment_id !== 'birkat_tzitzit_katan');
  console.log(`  removed birkat_tzitzit_katan: ${before} → ${data.segments.length}`);

  // Mark adon_olam optional (accordion).
  const ao = data.segments.find((s) => s.segment_id === 'adon_olam');
  if (ao) {
    ao.optional = true;
    console.log('  adon_olam marked optional');
  } else {
    console.log('  ! adon_olam not found');
  }

  writeJson(tp, data);
}

// ─── Write manifest ────────────────────────────────────────────────────────
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');
console.log('\nDONE.');
