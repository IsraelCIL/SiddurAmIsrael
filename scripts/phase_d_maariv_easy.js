// Batch D — easy Maariv fixes + cleanup:
//   • Delete 6 orphan sub-templates (birchot_hashachar_*, birchot_hatorah_*)
//     that no longer have references after the Batch C inlining.
//   • D.6  Remove psalm_091 (yoshev_beseter) from EM Maariv — added by
//     mistake; not in the standard EM weekday Maariv liturgy.
//   • D.4  shir_hamaalot accordion in Sfard + EM Maariv: mark psalm_121,
//     the kaddish_yatom that follows, and the barchu after it as optional.
//   • D.5  Move yehi_shem from shacharit/acharei_amidah → shared_global.
//          Add it to EM Maariv right after kaddish_titkabal under
//          condition_flags=[skip_tachanun]. (Already used in Mincha EM via
//          manifest lookup — the move keeps that working.)
//   • D.3  hashem_tzvaot_maariv Sfard: expand to the full text the user
//          supplied (3× set + 6 follow-up pesukim through Vaya'azrem).
//          Apply same text to EM (per user spec earlier it's used in both).
//
// Run from project root:  node scripts/phase_d_maariv_easy.js

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

// ─── Cleanup: orphan sub-templates ─────────────────────────────────────────
console.log('=== cleanup orphan sub-templates ===');
{
  const orphans = [
    'birchot_hashachar_ashkenaz', 'birchot_hashachar_sfard', 'birchot_hashachar_edot_mizrach',
    'birchot_hatorah_ashkenaz', 'birchot_hatorah_sfard', 'birchot_hatorah_edot_mizrach',
  ];
  for (const id of orphans) {
    const p = manifest.templates[id];
    if (!p) continue;
    const abs = path.join(PROJECT, p);
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
    delete manifest.templates[id];
    console.log(`  deleted ${p}`);
  }
}

// ─── D.6: remove psalm_091 from EM Maariv template ─────────────────────────
console.log('\n=== D.6 remove psalm_091 from EM Maariv ===');
{
  const tp = path.join(PROJECT, manifest.templates.maariv_edot_mizrach);
  const data = readJson(tp);
  const before = data.segments.length;
  data.segments = data.segments.filter((s) => s.segment_id !== 'psalm_091');
  console.log(`  EM Maariv segments: ${before} → ${data.segments.length}`);
  writeJson(tp, data);
}

// ─── D.4: shir_hamaalot accordion (Sfard + EM Maariv) ──────────────────────
console.log('\n=== D.4 shir_hamaalot accordion ===');
{
  for (const nusach of ['sfard', 'edot_mizrach']) {
    const tp = path.join(PROJECT, manifest.templates[`maariv_${nusach}`]);
    const data = readJson(tp);
    // Find psalm_121 entry. Mark it + the kaddish_yatom right after + the
    // barchu right after that as optional. (Accordion display = collapse-by-
    // default at render time; the segment-level `optional: true` flag is the
    // signal.)
    let psalmIdx = data.segments.findIndex((s) => s.segment_id === 'psalm_121');
    if (psalmIdx < 0) {
      console.log(`  ! ${nusach}: psalm_121 not found`);
      continue;
    }
    data.segments[psalmIdx].optional = true;
    // The next entry should be the kaddish_yatom that pairs with the psalm.
    let next = psalmIdx + 1;
    if (data.segments[next] && data.segments[next].sub_template_id === 'kaddish_yatom') {
      data.segments[next].optional = true;
      next++;
    }
    if (data.segments[next] && data.segments[next].segment_id === 'barchu') {
      data.segments[next].optional = true;
    }
    writeJson(tp, data);
    console.log(`  ${nusach}: marked psalm_121 (idx ${psalmIdx}) + following kaddish_yatom + barchu as optional`);
  }
}

// ─── D.5: move yehi_shem to shared_global + add to EM Maariv ───────────────
console.log('\n=== D.5 yehi_shem → shared_global + EM Maariv entry ===');
{
  const oldRel = manifest.nusach.edot_mizrach.yehi_shem;
  if (!oldRel) {
    console.log('  ! yehi_shem not found in EM manifest');
  } else if (!oldRel.includes('shared_global')) {
    const oldAbs = path.join(PROJECT, oldRel);
    const newAbs = path.join(ASSETS, 'shared_global/nusach/edot_mizrach/yehi_shem.json');
    fs.mkdirSync(path.dirname(newAbs), { recursive: true });
    fs.renameSync(oldAbs, newAbs);
    manifest.nusach.edot_mizrach.yehi_shem = rel(newAbs);
    console.log(`  moved ${oldRel} → ${rel(newAbs)}`);
  } else {
    console.log('  already in shared_global');
  }

  // Add entry to EM Maariv template (after kaddish_titkabal, condition: skip_tachanun)
  const tp = path.join(PROJECT, manifest.templates.maariv_edot_mizrach);
  const data = readJson(tp);
  if (!data.segments.some((s) => s.segment_id === 'yehi_shem')) {
    const idx = data.segments.findIndex(
      (s) => s.sub_template_id === 'kaddish_titkabal',
    );
    if (idx < 0) {
      console.log('  ! kaddish_titkabal not found in EM Maariv');
    } else {
      data.segments.splice(idx + 1, 0, {
        segment_id: 'yehi_shem',
        condition_flags: ['skip_tachanun'],
        exclude_flags: [],
        optional: false,
        allowed_nusach: [],
      });
      writeJson(tp, data);
      console.log(`  inserted yehi_shem at idx ${idx + 1} (after kaddish_titkabal, skip_tachanun)`);
    }
  } else {
    console.log('  yehi_shem already in EM Maariv');
  }

  // Also update the EM shacharit sub-template (acharei_amidah_edot_mizrach)
  // since the segment moved — the segment_id reference still resolves via
  // manifest so no template change is needed there. Mincha + Shacharit
  // EM references the same segment_id and will find it at the new path.
  console.log('  (shacharit + mincha references unchanged — resolved via manifest)');
}

// ─── D.3: expand hashem_tzvaot_maariv text (Sfard + EM same) ───────────────
console.log('\n=== D.3 hashem_tzvaot_maariv full text (Sfard + EM) ===');
{
  const fullText = [
    '(שלוש פעמים:)',
    'יְהֹוָה צְבָאוֹת עִמָּנוּ, מִשְׂגָּב לָנוּ אֱלֹהֵי יַעֲקֹב סֶלָה:',
    '(שלוש פעמים:)',
    'יְהֹוָה צְבָאוֹת אַשְׁרֵי אָדָם בּוֹטֵחַ בָּךְ:',
    '(שלוש פעמים:)',
    'יְהֹוָה הוֹשִׁיעָה, הַמֶּלֶךְ יַעֲנֵנוּ בְיוֹם קָרְאֵנוּ:',
    'הוֹשִׁיעָה אֶת עַמֶּךָ וּבָרֵךְ אֶת נַחֲלָתֶךָ',
    'וּרְעֵם וְנַשְּׂאֵם עַד הָעוֹלָם:',
    'מִי יִתֵּן מִצִּיּוֹן יְשׁוּעַת יִשְׂרָאֵל',
    'בְּשׁוּב יְהֹוָה שְׁבוּת עַמּוֹ, יָגֵל יַעֲקֹב יִשְׂמַח יִשְׂרָאֵל:',
    'בְּשָׁלוֹם יַחְדָּו אֶשְׁכְּבָה וְאִישָׁן,',
    'כִּי אַתָּה יְהֹוָה לְבָדָד לָבֶטַח תּוֹשִׁיבֵנִי:',
    'יוֹמָם יְצַוֶּה יְהֹוָה חַסְדּוֹ,',
    'וּבַלַּיְלָה שִׁירֹה עִמִּי, תְּפִלָּה לְאֵל חַיָּי:',
    'וּתְשׁוּעַת צַדִּיקִים מֵיְהֹוָה, מָעוּזָּם בְּעֵת צָרָה:',
    'וַיַּעְזְרֵם יְהֹוָה וַיְפַלְּטֵם,',
    'יְפַלְּטֵם מֵרְשָׁעִים וְיוֹשִׁיעֵם כִּי חָסוּ בוֹ:',
  ];
  for (const nusach of ['sfard', 'edot_mizrach']) {
    const p = path.join(PROJECT, manifest.nusach[nusach].hashem_tzvaot_maariv);
    writeJson(p, {
      id: 'hashem_tzvaot_maariv',
      sections: [{ text: fullText, condition_flags: [], exclude_flags: [] }],
    });
    console.log(`  ${nusach}: ${rel(p)} (${fullText.length} lines)`);
  }
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
