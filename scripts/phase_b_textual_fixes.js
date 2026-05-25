// Phase B textual fixes (no inline-variant parser yet — that's separate):
//   1. Consolidate to common: mizmor_letodah, yehi_kevod, hodu — verified
//      identical across nusachim (hodu differs only in one line-break, same
//      text). Delete the 9 per-nusach files.
//   2. Rename birchot_hatorah_asher_bachar → birchot_hatorah_la_asok everywhere
//      (the first BHT bracha is "אשר קדשנו במצותיו וצונו לעסוק בדברי תורה",
//      not "אשר בחר בנו" — that's the third bracha).
//   3. Ashkenaz asher_yatzar: remove "אפילו שעה אחת." line (per user input;
//      note: Sefaria's Metsudah Ashkenaz includes it, but user states the
//      Ashkenaz nusach in our scope does not — flag for user verification).
//   4. Ashkenaz hamaavir_sheinah: append continuation through chatima
//      "ברוך אתה ה' גומל חסדים טובים לעמו ישראל". Source: Sefaria
//      Siddur Ashkenaz Morning Blessings entry [16].
//   5. Sfard hanoten_lasechvi: "הנותן" → "אשר נתן" (matches Ashkenaz).
//   6. Regenerate _manifest.json (re-running reorganize_assets.js would
//      re-categorize, which is dangerous now that things are already in
//      place — we patch the manifest in place instead).
//
// Run from project root:  node scripts/phase_b_textual_fixes.js

const fs = require('fs');
const path = require('path');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');

function rel(p) {
  return path.relative(PROJECT, p).replace(/\\/g, '/');
}

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

const manifest = readJson(MANIFEST_PATH);

// ─── 1. Consolidate 3 segments to common ───────────────────────────────────
console.log('=== Step 1: consolidate to common ===');
{
  const targets = ['mizmor_letodah', 'yehi_kevod', 'hodu'];
  const commonDir = path.join(ASSETS, 'shacharit', 'pesukei_dezimra', 'common');
  fs.mkdirSync(commonDir, { recursive: true });

  for (const segId of targets) {
    // Use the Sfard version as canonical (single-line for hodu matches biblical verses).
    const sources = ['sfard', 'ashkenaz', 'edot_mizrach'];
    let canonical = null;
    for (const n of sources) {
      const p = manifest.nusach[n][segId];
      if (p) {
        canonical = readJson(path.join(PROJECT, p));
        break;
      }
    }
    if (!canonical) {
      console.log(`  ! skip ${segId}: no source file found`);
      continue;
    }

    const dst = path.join(commonDir, `${segId}.json`);
    writeJson(dst, canonical);
    console.log(`  → ${rel(dst)}`);

    // Delete per-nusach files and remove from manifest.
    for (const n of ['ashkenaz', 'sfard', 'edot_mizrach']) {
      const p = manifest.nusach[n][segId];
      if (p) {
        const abs = path.join(PROJECT, p);
        if (fs.existsSync(abs)) fs.unlinkSync(abs);
        delete manifest.nusach[n][segId];
      }
    }
    manifest.common[segId] = rel(dst);
  }
}

// ─── 2. Rename birchot_hatorah_asher_bachar → birchot_hatorah_la_asok ─────
console.log('\n=== Step 2: rename birchot_hatorah_asher_bachar → birchot_hatorah_la_asok ===');
{
  const OLD = 'birchot_hatorah_asher_bachar';
  const NEW = 'birchot_hatorah_la_asok';

  for (const n of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const oldPath = manifest.nusach[n][OLD];
    if (!oldPath) continue;
    const oldAbs = path.join(PROJECT, oldPath);
    const newAbs = oldAbs.replace(/asher_bachar/g, 'la_asok');
    const data = readJson(oldAbs);
    data.id = NEW;
    writeJson(newAbs, data);
    fs.unlinkSync(oldAbs);
    delete manifest.nusach[n][OLD];
    manifest.nusach[n][NEW] = rel(newAbs);
    console.log(`  ${n}: ${rel(oldAbs)} → ${rel(newAbs)}`);
  }

  // Update template references.
  for (const tmpl of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tp = manifest.templates[`birchot_hatorah_${tmpl}`];
    if (!tp) continue;
    const abs = path.join(PROJECT, tp);
    const raw = fs.readFileSync(abs, 'utf8');
    if (raw.includes(OLD)) {
      const replaced = raw.replace(new RegExp(OLD, 'g'), NEW);
      fs.writeFileSync(abs, replaced, 'utf8');
      console.log(`  template ${tmpl} updated`);
    }
  }
}

// ─── 3. Ashkenaz asher_yatzar: remove "אפילו שעה אחת." ────────────────────
console.log('\n=== Step 3: Ashkenaz asher_yatzar — remove "אפילו שעה אחת." ===');
{
  const p = path.join(PROJECT, manifest.nusach.ashkenaz.asher_yatzar);
  const data = readJson(p);
  const before = data.sections[0].text.length;
  data.sections[0].text = data.sections[0].text.filter(
    (s) => !/אֲפִילוּ\s+שָׁעָה/.test(s),
  );
  // Also stitch ending — the previous line ended with "לפניך" and next was "ברוך אתה...".
  // If line ends without trailing period, fine; the array join inserts a space.
  // Append a period to the line ending with "לפניך" if missing.
  const lines = data.sections[0].text;
  for (let i = 0; i < lines.length; i++) {
    if (/לְפָנֶֽיךָ\s*$/.test(lines[i])) {
      lines[i] = lines[i].replace(/לְפָנֶֽיךָ\s*$/, 'לְפָנֶֽיךָ.');
    }
  }
  writeJson(p, data);
  console.log(`  sections[0].text: ${before} → ${data.sections[0].text.length} lines`);
}

// ─── 4. Ashkenaz hamaavir_sheinah: append continuation through chatima ────
console.log('\n=== Step 4: Ashkenaz hamaavir_sheinah — append continuation ===');
{
  // Continuation taken from Sefaria Siddur Ashkenaz Morning Blessings entry [16].
  // Splitting into ≤75-char chunks at natural breakpoints.
  const continuation = [
    'וִיהִי רָצוֹן מִלְּפָנֶֽיךָ יְהֹוָה אֱלֹהֵֽינוּ וֵאלֹהֵי אֲבוֹתֵֽינוּ',
    'שֶׁתַּרְגִּילֵֽנוּ בְּתוֹרָתֶֽךָ וְדַבְּקֵֽנוּ בְּמִצְוֹתֶֽיךָ,',
    'וְאַל תְּבִיאֵֽנוּ לֹא לִידֵי חֵטְא וְלֹא לִידֵי עֲבֵרָה וְעָוֹן',
    'וְלֹא לִידֵי נִסָּיוֹן וְלֹא לִידֵי בִזָּיוֹן,',
    'וְאַל יִשְׁלֹט בָּֽנוּ יֵֽצֶר הָרָע,',
    'וְהַרְחִיקֵֽנוּ מֵאָדָם רָע וּמֵחָבֵר רָע,',
    'וְדַבְּקֵֽנוּ בְּיֵֽצֶר הַטּוֹב וּבְמַעֲשִׂים טוֹבִים,',
    'וְכוֹף אֶת יִצְרֵֽנוּ לְהִשְׁתַּעְבֶּד לָךְ,',
    'וּתְנֵֽנוּ הַיּוֹם וּבְכָל יוֹם לְחֵן וּלְחֶֽסֶד וּלְרַחֲמִים',
    'בְּעֵינֶֽיךָ וּבְעֵינֵי כָל רוֹאֵֽינוּ,',
    'וְתִגְמְלֵֽנוּ חֲסָדִים טוֹבִים:',
    'בָּרוּךְ אַתָּה יְהֹוָה גּוֹמֵל חֲסָדִים טוֹבִים לְעַמּוֹ יִשְׂרָאֵל:',
  ];
  const p = path.join(PROJECT, manifest.nusach.ashkenaz.hamaavir_sheinah);
  const data = readJson(p);
  // Replace ending colon on previous last line with comma to flow naturally.
  // Existing last line: "מֵעֵינָי וּתְנוּמָה מֵעַפְעַפָּי:" → change to ","
  const lines = data.sections[0].text;
  if (/מֵעַפְעַפָּי:?$/.test(lines[lines.length - 1])) {
    lines[lines.length - 1] = lines[lines.length - 1].replace(
      /מֵעַפְעַפָּי:?$/,
      'מֵעַפְעַפָּי,',
    );
  }
  data.sections[0].text = [...lines, ...continuation];
  writeJson(p, data);
  console.log(`  sections[0].text now ${data.sections[0].text.length} lines`);
}

// ─── 5. Sfard hanoten_lasechvi: "הנותן" → "אשר נתן" ────────────────────────
console.log('\n=== Step 5: Sfard hanoten_lasechvi — "הנותן" → "אשר נתן" ===');
{
  const p = path.join(PROJECT, manifest.nusach.sfard.hanoten_lasechvi);
  // Replace with the Ashkenaz wording verbatim.
  const newData = {
    id: 'hanoten_lasechvi',
    sections: [
      {
        text: [
          'בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵֽינוּ מֶֽלֶךְ הָעוֹלָם אֲשֶׁר נָתַן',
          'לַשֶּֽׂכְוִי בִינָה לְהַבְחִין בֵּין יוֹם וּבֵין לָֽיְלָה:',
        ],
        condition_flags: [],
        exclude_flags: [],
      },
    ],
  };
  writeJson(p, newData);
  console.log(`  updated ${rel(p)}`);
}

// ─── 6. Write back manifest ────────────────────────────────────────────────
console.log('\n=== Step 6: re-sort + write manifest ===');
{
  function sortKeys(o) {
    if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
    const out = {};
    for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
    return out;
  }
  const sorted = sortKeys(manifest);
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sorted, null, 2) + '\n', 'utf8');
  console.log(`  manifest entries: templates=${Object.keys(sorted.templates).length}, common=${Object.keys(sorted.common).length}, ash=${Object.keys(sorted.nusach.ashkenaz).length}, sfard=${Object.keys(sorted.nusach.sfard).length}, em=${Object.keys(sorted.nusach.edot_mizrach).length}`);
}

console.log('\nDONE.');
