// Batch A — quick structural/textual fixes:
//   1. Templates: add `condition_flags: ["gender_female"]` to the
//      `sheasani_kirtzono` entry in all 3 birchot_hashachar_* templates.
//   2. Templates: reorder so `vayevarech_david` precedes `az_yashir` in all 3
//      shacharit_* templates.
//   3. EM elokai_neshama: give each gendered section its own clean text —
//      male gets only "מודה", female gets only "מודה" (different vowels),
//      no inline parenthetical instruction.
//   4. kriat_hatorah_shacharit: split common file into 3 per-nusach files.
//      Add קהל/חזן/עולה labels (as rubric sections — no niqqud, rendered
//      smaller) around the doubled "ברוך ה' המבורך". EM gets the extra
//      "את תורתו" before "תורת אמת" in the after-blessing. Delete the
//      common original.
//   5. Shema (shared_global/common): append a final "אמת" section + rubric
//      "החזן חוזר ואומר" + repeated "ה' אלקיכם אמת" (with_minyan only).
//
// Run from project root:  node scripts/phase_b_batch_a.js

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

// ─── 1. sheasani_kirtzono gender_female in templates ───────────────────────
console.log('=== 1. add gender_female to sheasani_kirtzono in templates ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const tp = manifest.templates[`birchot_hashachar_${nusach}`];
  const abs = path.join(PROJECT, tp);
  const data = readJson(abs);
  let changed = 0;
  for (const seg of data.segments) {
    if (seg.segment_id === 'sheasani_kirtzono') {
      if (!seg.condition_flags.includes('gender_female')) {
        seg.condition_flags = ['gender_female'];
        changed++;
      }
    }
  }
  writeJson(abs, data);
  console.log(`  ${nusach}: ${changed} entry updated`);
}

// ─── 2. Reorder vayevarech_david BEFORE az_yashir in all 3 shacharit_* ────
console.log('\n=== 2. swap order: vayevarech_david → az_yashir ===');
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const tp = manifest.templates[`shacharit_${nusach}`];
  const abs = path.join(PROJECT, tp);
  const data = readJson(abs);
  const idxAz = data.segments.findIndex((s) => s.segment_id === 'az_yashir');
  const idxVd = data.segments.findIndex((s) => s.segment_id === 'vayevarech_david');
  if (idxAz >= 0 && idxVd > idxAz) {
    const [vd] = data.segments.splice(idxVd, 1);
    data.segments.splice(idxAz, 0, vd);
    writeJson(abs, data);
    console.log(`  ${nusach}: moved vayevarech_david from #${idxVd} to #${idxAz}`);
  } else {
    console.log(`  ${nusach}: already in order (az=${idxAz}, vd=${idxVd})`);
  }
}

// ─── 3. EM elokai_neshama — distinct text per gender ──────────────────────
console.log('\n=== 3. EM elokai_neshama distinct gender sections ===');
{
  const p = path.join(PROJECT, manifest.nusach.edot_mizrach.elokai_neshama);
  const newData = {
    id: 'elokai_neshama',
    sections: [
      {
        text: [
          'אֱלֹהַי, נְשָׁמָה שֶׁנָּתַתָּ בִּי טְהוֹרָה, אַתָּה בְרָאתָהּ,',
          'אַתָּה יְצַרְתָּהּ, אַתָּה נְפַחְתָּהּ בִּי,',
          'וְאַתָּה מְשַׁמְּרָהּ בְּקִרְבִּי, וְאַתָּה עָתִיד לִטְּלָהּ מִמֶּנִּי,',
          'וּלְהַחֲזִירָהּ בִּי לֶעָתִיד לָבוֹא, כָּל־זְמַן שֶׁהַנְּשָׁמָה בְקִרְבִּי,',
          'מוֹדֶה אֲנִי לְפָנֶיךָ יְהֹוָה אֱלֹהַי וֵאלֹהֵי אֲבוֹתַי,',
          'רִבּוֹן כָּל־הַמַּעֲשִׂים אֲדוֹן כָּל־הַנְּשָׁמוֹת.',
          'בָּרוּךְ אַתָּה יְהֹוָה, הַמַּחֲזִיר נְשָׁמוֹת לִפְגָרִים מֵתִים:',
        ],
        condition_flags: ['gender_male'],
        exclude_flags: [],
      },
      {
        text: [
          'אֱלֹהַי, נְשָׁמָה שֶׁנָּתַתָּ בִּי טְהוֹרָה, אַתָּה בְרָאתָהּ,',
          'אַתָּה יְצַרְתָּהּ, אַתָּה נְפַחְתָּהּ בִּי,',
          'וְאַתָּה מְשַׁמְּרָהּ בְּקִרְבִּי, וְאַתָּה עָתִיד לִטְּלָהּ מִמֶּנִּי,',
          'וּלְהַחֲזִירָהּ בִּי לֶעָתִיד לָבוֹא, כָּל־זְמַן שֶׁהַנְּשָׁמָה בְקִרְבִּי,',
          'מוֹדָה אֲנִי לְפָנֶיךָ יְהֹוָה אֱלֹהַי וֵאלֹהֵי אֲבוֹתַי,',
          'רִבּוֹן כָּל־הַמַּעֲשִׂים אֲדוֹן כָּל־הַנְּשָׁמוֹת.',
          'בְּרוּכָה אַתָּה יְהֹוָה, הַמַּחֲזִיר נְשָׁמוֹת לִפְגָרִים מֵתִים:',
        ],
        condition_flags: ['gender_female'],
        exclude_flags: [],
      },
    ],
  };
  writeJson(p, newData);
  console.log(`  ${rel(p)}: 2 distinct gendered sections`);
}

// ─── 4. kriat_hatorah_shacharit — split per-nusach + labels + EM variant ──
console.log('\n=== 4. kriat_hatorah_shacharit split per-nusach ===');
{
  // Common building blocks
  const buildSections = ({ withEtTorato }) => [
    // Oleh calls the congregation
    {
      text: ['בָּרְכוּ אֶת יְהֹוָה הַמְבֹרָךְ:'],
      condition_flags: [],
      exclude_flags: [],
    },
    // Rubric: congregation answers (no niqqud → renders smaller)
    {
      text: ['הקהל עונים:'],
      condition_flags: [],
      exclude_flags: [],
    },
    {
      text: ['בָּרוּךְ יְהֹוָה הַמְבֹרָךְ לְעוֹלָם וָעֶד:'],
      condition_flags: [],
      exclude_flags: [],
    },
    // Rubric: oleh repeats
    {
      text: ['העולה חוזר:'],
      condition_flags: [],
      exclude_flags: [],
    },
    {
      text: ['בָּרוּךְ יְהֹוָה הַמְבֹרָךְ לְעוֹלָם וָעֶד:'],
      condition_flags: [],
      exclude_flags: [],
    },
    // Before-bracha
    {
      text: [
        'בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם',
        'אֲשֶׁר בָּחַר בָּנוּ מִכָּל הָעַמִּים',
        'וְנָתַן לָנוּ אֶת תּוֹרָתוֹ:',
        'בָּרוּךְ אַתָּה יְהֹוָה נוֹתֵן הַתּוֹרָה:',
      ],
      condition_flags: [],
      exclude_flags: [],
    },
    // Rubric: after the aliyah
    {
      text: ['ולאחר הקריאה מברך:'],
      condition_flags: [],
      exclude_flags: [],
    },
    // After-bracha (EM: "אשר נתן לנו את תורתו תורת אמת"; Ash/Sfard: "אשר נתן לנו תורת אמת")
    {
      text: withEtTorato
        ? [
            'בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם',
            'אֲשֶׁר נָתַן לָנוּ אֶת תּוֹרָתוֹ תּוֹרַת אֱמֶת',
            'וְחַיֵּי עוֹלָם נָטַע בְּתוֹכֵנוּ:',
            'בָּרוּךְ אַתָּה יְהֹוָה נוֹתֵן הַתּוֹרָה:',
          ]
        : [
            'בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם',
            'אֲשֶׁר נָתַן לָנוּ תּוֹרַת אֱמֶת',
            'וְחַיֵּי עוֹלָם נָטַע בְּתוֹכֵנוּ:',
            'בָּרוּךְ אַתָּה יְהֹוָה נוֹתֵן הַתּוֹרָה:',
          ],
      condition_flags: [],
      exclude_flags: [],
    },
  ];

  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const sections = buildSections({ withEtTorato: nusach === 'edot_mizrach' });
    const dst = path.join(
      ASSETS,
      'shacharit/acharei_amidah/nusach',
      nusach,
      'kriat_hatorah_shacharit.json',
    );
    writeJson(dst, { id: 'kriat_hatorah_shacharit', sections });
    manifest.nusach[nusach].kriat_hatorah_shacharit = rel(dst);
    console.log(`  ${nusach}: ${rel(dst)}`);
  }

  // Delete common original.
  const oldCommon = manifest.common.kriat_hatorah_shacharit;
  if (oldCommon) {
    const oldAbs = path.join(PROJECT, oldCommon);
    if (fs.existsSync(oldAbs)) fs.unlinkSync(oldAbs);
    delete manifest.common.kriat_hatorah_shacharit;
    console.log(`  deleted ${oldCommon}`);
  }
}

// ─── 5. Shema — append אמת + chazzan repetition ────────────────────────────
console.log('\n=== 5. shema: append אמת + chazzan repetition ===');
{
  const p = path.join(PROJECT, manifest.common.shema);
  const data = readJson(p);
  // Final small "אמת" said by everyone, attached to Shema
  data.sections.push({
    text: ['אֱמֶת:'],
    condition_flags: [],
    exclude_flags: [],
  });
  // Rubric — chazzan repeats (with minyan only)
  data.sections.push({
    text: ['החזן חוזר ואומר:'],
    condition_flags: ['with_minyan'],
    exclude_flags: [],
  });
  data.sections.push({
    text: ['יְהֹוָה אֱלֹהֵיכֶם אֱמֶת:'],
    condition_flags: ['with_minyan'],
    exclude_flags: [],
  });
  writeJson(p, data);
  console.log(`  ${rel(p)}: 3 sections appended`);
}

// ─── 6. Delete orphaned common/birchot_hashachar.json ──────────────────────
console.log('\n=== 6. delete orphan common/birchot_hashachar.json ===');
{
  const p = manifest.common.birchot_hashachar;
  if (p) {
    const abs = path.join(PROJECT, p);
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
    delete manifest.common.birchot_hashachar;
    console.log(`  deleted ${p}`);
  } else {
    console.log('  not in manifest (nothing to do)');
  }
}

// ─── 7. Re-sort + write manifest ────────────────────────────────────────────
console.log('\n=== 7. write manifest ===');
{
  function sortKeys(o) {
    if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
    const out = {};
    for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
    return out;
  }
  const sorted = sortKeys(manifest);
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sorted, null, 2) + '\n', 'utf8');
}

console.log('\nDONE.');
