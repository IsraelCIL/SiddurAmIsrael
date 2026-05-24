// Batch C — add the pre-BHS preparatory liturgy:
//
//   modeh_ani (gendered) → BHS first 3 brachot (netilat/asher_yatzar/elokai)
//   → birchot_hatorah → tzitzit (2 variants gated by wears_tallit_gadol)
//   → seder_tefillin (lshem yichud + 2 brachot + post-bracha verses
//     + parshat kadesh + parshat vehaya ki yeviacha)
//   → ma_tovu → adon_olam → yigdal → rest-of-BHS → akeidah ...
//
// EM order differs (after BHT): petihat_eliyahu (accordion) → adon_olam →
//   tzitzit → seder_tefillin → vatitpalel_channa → lshem_yichud → akeidah.
//
// Texts are pulled from the fetched Sefaria caches in project root. All
// segment files are written under shacharit/lifnei_hatfila/{common,nusach/<n>}.
//
// Templates (shacharit_{ashkenaz,sfard,edot_mizrach}.json) are rebuilt:
// the sub-template references for birchot_hashachar / birchot_hatorah are
// inlined as explicit segment entries so we can insert the new items at
// the precise positions the user specified.
//
// Run from project root:  node scripts/phase_c_pre_bhs.js

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
function sec(text, conditionFlags = [], excludeFlags = []) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: conditionFlags,
    exclude_flags: excludeFlags,
  };
}
function rubric(text, conditionFlags = [], excludeFlags = []) {
  return {
    text: Array.isArray(text) ? text : [text],
    condition_flags: conditionFlags,
    exclude_flags: excludeFlags,
  };
}

const manifest = readJson(MANIFEST_PATH);

// ─── 1. modeh_ani — gendered, per-nusach ───────────────────────────────────
// Ashkenaz/Sfard: Sefaria Modeh Ani entry [0]. Replace nothing; we add an
// explicit female variant by substituting the verb. EM uses the same text
// (entry [3] with parenthetical stripped).
console.log('=== modeh_ani ===');
{
  const ashMale = loadEntry('_ash_modeh_ani.json', 0);  // starts מוֹדֶה
  const ashFemale = ashMale.replace('מוֹדֶה אֲנִי', 'מוֹדָה אֲנִי');
  // EM source has "מוֹדֶה האשה אומרת: מוֹדָה אֲנִי..." — strip the parenthetical.
  const emRaw = loadEntry('_em_modeh_ani.json', 3);
  const emMale = emRaw.replace(/מוֹדֶה\s+האשה אומרת:\s*מוֹדָה/, 'מוֹדֶה');
  const emFemale = emRaw.replace(/מוֹדֶה\s+האשה אומרת:\s*מוֹדָה/, 'מוֹדָה');

  const sources = {
    ashkenaz: { male: ashMale, female: ashFemale },
    sfard:    { male: ashMale, female: ashFemale }, // Sfard uses same text
    edot_mizrach: { male: emMale, female: emFemale },
  };
  for (const n of Object.keys(sources)) {
    const obj = {
      id: 'modeh_ani',
      sections: [
        sec(sources[n].male,   ['gender_male']),
        sec(sources[n].female, ['gender_female']),
      ],
    };
    const dst = path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach', n, 'modeh_ani.json');
    writeJson(dst, obj);
    manifest.nusach[n].modeh_ani = rel(dst);
  }
  console.log('  written for all 3 nusachim');
}

// ─── 2. ma_tovu (common — text identical across nusachim) ──────────────────
console.log('\n=== ma_tovu ===');
{
  const text = loadEntry('_ash_ma_tovu.json', 0);
  const dst = path.join(ASSETS, 'shacharit/lifnei_hatfila/common/ma_tovu.json');
  writeJson(dst, { id: 'ma_tovu', sections: [sec(text)] });
  manifest.common.ma_tovu = rel(dst);
  console.log(`  ${rel(dst)}`);
}

// ─── 3. adon_olam (common — same piyut) ────────────────────────────────────
console.log('\n=== adon_olam ===');
{
  // Collect lines 0..9 of the piyut.
  const lines = [];
  for (let i = 0; i < 10; i++) {
    const v = loadEntry('_ash_adon_olam.json', i);
    if (v) lines.push(v);
  }
  const dst = path.join(ASSETS, 'shacharit/lifnei_hatfila/common/adon_olam.json');
  writeJson(dst, { id: 'adon_olam', sections: [sec(lines)] });
  manifest.common.adon_olam = rel(dst);
  console.log(`  ${rel(dst)}: ${lines.length} lines`);
}

// ─── 4. yigdal (common — same piyut, 13 verses) ────────────────────────────
console.log('\n=== yigdal ===');
{
  // Sefaria interleaves principle-headers with verses. The verses are the
  // odd-indexed entries starting from [2]: 2,4,6,8,10,12,14,16,18,20,22,24,26
  const verses = [];
  for (const i of [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]) {
    const v = loadEntry('_ash_yigdal.json', i);
    if (v) verses.push(v);
  }
  const dst = path.join(ASSETS, 'shacharit/lifnei_hatfila/common/yigdal.json');
  writeJson(dst, { id: 'yigdal', sections: [sec(verses)] });
  manifest.common.yigdal = rel(dst);
  console.log(`  ${rel(dst)}: ${verses.length} verses`);
}

// ─── 5. parshat_kadesh + parshat_vehaya_ki_yeviacha (common — biblical) ───
console.log('\n=== parshat tefillin (common) ===');
{
  const kadesh = loadEntry('_ash_tefillin.json', 11);
  const vehaya = loadEntry('_ash_tefillin.json', 12);
  for (const [id, text] of [['parshat_kadesh', kadesh], ['parshat_vehaya_ki_yeviacha', vehaya]]) {
    const dst = path.join(ASSETS, 'shacharit/lifnei_hatfila/common', `${id}.json`);
    writeJson(dst, { id, sections: [sec(text)] });
    manifest.common[id] = rel(dst);
    console.log(`  ${rel(dst)}: ${text.length} chars`);
  }
}

// ─── 6. Tzitzit segments — per-nusach ──────────────────────────────────────
console.log('\n=== tzitzit segments ===');
{
  // Ashkenaz / Sfard share the same texts (Sefaria Sfard tzitzit not separately fetched).
  const yehiRatzon = loadEntry('_ash_tzitzit.json', 1);
  const ashKatan = loadEntry('_ash_tzitzit.json', 0);    // "על מצות ציצית"
  const ashGadol = loadEntry('_ash_tallit.json', 3);     // "להתעטף בציצית"
  const mahYakar = loadEntry('_ash_tallit.json', 4);
  const emGadol = loadEntry('_em_talit.json', 2);        // EM "להתעטף בציצית"

  for (const n of ['ashkenaz', 'sfard']) {
    writeJson(
      path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach', n, 'yehi_ratzon_tzitzit.json'),
      { id: 'yehi_ratzon_tzitzit', sections: [sec(yehiRatzon, ['wears_tallit_gadol'])] },
    );
    manifest.nusach[n].yehi_ratzon_tzitzit =
      `assets/prayers/shacharit/lifnei_hatfila/nusach/${n}/yehi_ratzon_tzitzit.json`;

    writeJson(
      path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach', n, 'birkat_tzitzit_katan.json'),
      { id: 'birkat_tzitzit_katan', sections: [sec(ashKatan, [], ['wears_tallit_gadol'])] },
    );
    manifest.nusach[n].birkat_tzitzit_katan =
      `assets/prayers/shacharit/lifnei_hatfila/nusach/${n}/birkat_tzitzit_katan.json`;

    writeJson(
      path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach', n, 'birkat_tzitzit_gadol.json'),
      { id: 'birkat_tzitzit_gadol', sections: [sec(ashGadol, ['wears_tallit_gadol'])] },
    );
    manifest.nusach[n].birkat_tzitzit_gadol =
      `assets/prayers/shacharit/lifnei_hatfila/nusach/${n}/birkat_tzitzit_gadol.json`;

    writeJson(
      path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach', n, 'mah_yakar_tallit.json'),
      { id: 'mah_yakar_tallit', sections: [sec(mahYakar, ['wears_tallit_gadol'])] },
    );
    manifest.nusach[n].mah_yakar_tallit =
      `assets/prayers/shacharit/lifnei_hatfila/nusach/${n}/mah_yakar_tallit.json`;
  }

  // EM: only the gadol bracha (Sephardim normally wear only Tallit Gadol;
  // we still include the katan bracha for those who wear it under clothing).
  writeJson(
    path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach/edot_mizrach/birkat_tzitzit_katan.json'),
    { id: 'birkat_tzitzit_katan', sections: [sec(ashKatan, [], ['wears_tallit_gadol'])] },
  );
  manifest.nusach.edot_mizrach.birkat_tzitzit_katan =
    'assets/prayers/shacharit/lifnei_hatfila/nusach/edot_mizrach/birkat_tzitzit_katan.json';

  writeJson(
    path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach/edot_mizrach/birkat_tzitzit_gadol.json'),
    { id: 'birkat_tzitzit_gadol', sections: [sec(emGadol, ['wears_tallit_gadol'])] },
  );
  manifest.nusach.edot_mizrach.birkat_tzitzit_gadol =
    'assets/prayers/shacharit/lifnei_hatfila/nusach/edot_mizrach/birkat_tzitzit_gadol.json';
  console.log('  tzitzit segments written for all 3 nusachim');
}

// ─── 7. Seder Hanachat Tefillin — per-nusach ───────────────────────────────
console.log('\n=== seder_tefillin ===');
{
  const ashLshem = loadEntry('_ash_tefillin.json', 0);
  const ashBerYad = loadEntry('_ash_tefillin.json', 2);    // להניח תפילין
  const ashBerRosh = loadEntry('_ash_tefillin.json', 4);   // על מצות תפילין
  const ashBaruchShem = loadEntry('_ash_tefillin.json', 6);
  const ashUmechochmatcha = loadEntry('_ash_tefillin.json', 7);
  const ashVaarastich = loadEntry('_ash_tefillin.json', 9);

  const emLshem = loadEntry('_em_tefillin.json', 1);
  const emBerYad = 'בָּרוּךְ אַתָּה יְהֹוָה, אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם, אֲשֶׁר קִדְּשָׁנוּ בְּמִצְוֹתָיו, וְצִוָּנוּ לְהָנִיחַ תְּפִלִּין:';
  const emBerRosh = 'בָּרוּךְ אַתָּה יְהֹוָה, אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם, אֲשֶׁר קִדְּשָׁנוּ בְּמִצְוֹתָיו, וְצִוָּנוּ עַל מִצְוַת תְּפִלִּין:';

  function buildAshSfard(lshem, yad, rosh, baruchShem, umech, vaar) {
    return {
      id: 'seder_tefillin',
      sections: [
        sec(lshem),
        rubric(['יניח תפילין של יד על קיבורת ידו, וקודם שיהדק יברך:']),
        sec(yad),
        rubric(['ויכרוך שבע כריכות סביב זרועו, ואחר כך יניח של ראש, וקודם שיהדק יברך:']),
        sec(rosh),
        rubric(['ואחר שיהדק הרצועה על ראשו יאמר:']),
        sec(baruchShem),
        sec(umech),
        rubric(['ואחר כך כורך הרצועה של יד על אצבעו ואומר:']),
        sec(vaar),
      ],
    };
  }
  function buildEm(lshem, yad, rosh) {
    return {
      id: 'seder_tefillin',
      sections: [
        sec(lshem),
        rubric(['יניח תפילין של יד על קיבורת ידו, וקודם שיהדק יברך:']),
        sec(yad),
        rubric(['ואחר כך מניח של ראש בלא ברכה (אלא אם הפסיק בין יד לראש שאז מברך):']),
        sec(rosh, ['hefsek_tefillin']),
      ],
    };
  }

  const objs = {
    ashkenaz: buildAshSfard(ashLshem, ashBerYad, ashBerRosh, ashBaruchShem, ashUmechochmatcha, ashVaarastich),
    sfard:    buildAshSfard(ashLshem, ashBerYad, ashBerRosh, ashBaruchShem, ashUmechochmatcha, ashVaarastich),
    edot_mizrach: buildEm(emLshem, emBerYad, emBerRosh),
  };
  for (const n of Object.keys(objs)) {
    const dst = path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach', n, 'seder_tefillin.json');
    writeJson(dst, objs[n]);
    manifest.nusach[n].seder_tefillin = rel(dst);
  }
  console.log('  seder_tefillin written for all 3 nusachim');
}

// ─── 8. vatitpalel_channa (EM only) ────────────────────────────────────────
console.log('\n=== vatitpalel_channa (EM only) ===');
{
  const text = loadEntry('_em_hannas_prayer.json', 1);
  const dst = path.join(ASSETS, 'shacharit/lifnei_hatfila/nusach/edot_mizrach/vatitpalel_channa.json');
  writeJson(dst, { id: 'vatitpalel_channa', sections: [sec(text)] });
  manifest.nusach.edot_mizrach.vatitpalel_channa = rel(dst);
  console.log(`  ${rel(dst)}: ${text.length} chars`);
}

// ─── 9. Move petihat_eliyahu to shacharit/lifnei_hatfila (was mincha) ──────
console.log('\n=== move petihat_eliyahu (EM) ===');
{
  const oldRel = manifest.nusach.edot_mizrach.petihat_eliyahu;
  if (oldRel && oldRel.includes('mincha/lifnei_mincha/')) {
    const oldAbs = path.join(PROJECT, oldRel);
    const newRel = oldRel.replace(
      'mincha/lifnei_mincha/',
      'shacharit/lifnei_hatfila/',
    );
    const newAbs = path.join(PROJECT, newRel);
    fs.mkdirSync(path.dirname(newAbs), { recursive: true });
    fs.renameSync(oldAbs, newAbs);
    manifest.nusach.edot_mizrach.petihat_eliyahu = newRel;
    console.log(`  ${oldRel} → ${newRel}`);
  } else {
    console.log(`  already moved or not present`);
  }
}

// ─── 10. Rebuild shacharit templates with new ordering ─────────────────────
console.log('\n=== rebuild shacharit templates ===');

function tmplEntry(segmentId, conditionFlags = [], excludeFlags = []) {
  return {
    segment_id: segmentId,
    condition_flags: conditionFlags,
    exclude_flags: excludeFlags,
    optional: false,
    allowed_nusach: [],
  };
}
function subEntry(subTemplateId, conditionFlags = [], excludeFlags = []) {
  return {
    sub_template_id: subTemplateId,
    condition_flags: conditionFlags,
    exclude_flags: excludeFlags,
    optional: false,
    allowed_nusach: [],
  };
}

// Read existing per-nusach BHS sub-templates so we can re-use their bracha
// ordering & flags without duplicating them.
function bhsEntries(nusach) {
  const sub = readJson(path.join(PROJECT, manifest.templates[`birchot_hashachar_${nusach}`]));
  return sub.segments;
}
function bhtEntries(nusach) {
  const sub = readJson(path.join(PROJECT, manifest.templates[`birchot_hatorah_${nusach}`]));
  return sub.segments;
}

// Split BHS list into first 3 (netilat/asher_yatzar/elokai_neshama) and rest.
function splitBhs(entries) {
  const head = [];
  const rest = [];
  let inHead = true;
  for (const e of entries) {
    if (inHead && ['al_netilat_yadayim', 'asher_yatzar', 'elokai_neshama'].includes(e.segment_id)) {
      head.push(e);
    } else {
      inHead = false;
      rest.push(e);
    }
  }
  return { head, rest };
}

function buildAshSfardTemplate(nusach) {
  const { head: bhsHead, rest: bhsRest } = splitBhs(bhsEntries(nusach));
  const bht = bhtEntries(nusach);
  const segments = [
    tmplEntry('modeh_ani'),
    ...bhsHead,
    ...bht,
    // Tzitzit block
    tmplEntry('yehi_ratzon_tzitzit', ['wears_tallit_gadol']),
    tmplEntry('birkat_tzitzit_gadol', ['wears_tallit_gadol']),
    tmplEntry('mah_yakar_tallit', ['wears_tallit_gadol']),
    tmplEntry('birkat_tzitzit_katan', [], ['wears_tallit_gadol']),
    // Tefillin block
    tmplEntry('seder_tefillin', [], ['skip_tefillin']),
    tmplEntry('parshat_kadesh', [], ['skip_tefillin']),
    tmplEntry('parshat_vehaya_ki_yeviacha', [], ['skip_tefillin']),
    // After-tefillin "settle-in" pieces
    tmplEntry('ma_tovu'),
    tmplEntry('adon_olam'),
    tmplEntry('yigdal'),
    // Rest of BHS
    ...bhsRest,
  ];
  return segments;
}

function buildEmTemplate() {
  const { head: bhsHead, rest: bhsRest } = splitBhs(bhsEntries('edot_mizrach'));
  const bht = bhtEntries('edot_mizrach');
  return [
    tmplEntry('modeh_ani'),
    ...bhsHead,
    ...bht,
    // EM-specific pre-flow
    tmplEntry('petihat_eliyahu', [], []), // accordion / optional — set optional=true:
    // (We'll patch optional=true below.)
    tmplEntry('adon_olam'),
    // Tzitzit
    tmplEntry('birkat_tzitzit_gadol', ['wears_tallit_gadol']),
    tmplEntry('birkat_tzitzit_katan', [], ['wears_tallit_gadol']),
    // Tefillin
    tmplEntry('seder_tefillin', [], ['skip_tefillin']),
    tmplEntry('parshat_kadesh', [], ['skip_tefillin']),
    tmplEntry('parshat_vehaya_ki_yeviacha', [], ['skip_tefillin']),
    // Vatitpalel Channa
    tmplEntry('vatitpalel_channa'),
    // L'shem Yichud (already exists for EM)
    tmplEntry('lshem_yichud'),
    // Rest of BHS
    ...bhsRest,
  ];
}

for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const tp = path.join(PROJECT, manifest.templates[`shacharit_${nusach}`]);
  const data = readJson(tp);
  const newHead = nusach === 'edot_mizrach' ? buildEmTemplate() : buildAshSfardTemplate(nusach);

  // Patch petihat_eliyahu in EM head to be optional (accordion).
  if (nusach === 'edot_mizrach') {
    const peEntry = newHead.find((s) => s.segment_id === 'petihat_eliyahu');
    if (peEntry) peEntry.optional = true;
  }

  // Find the cut-off index in the current template: everything up to and
  // including the BHS / BHT sub-template references (and the per-nusach
  // pre-akeidah blocks already added) is replaced. We start preserving
  // from the first 'akeidah' segment onwards.
  const akeidahIdx = data.segments.findIndex(
    (s) => s.segment_id === 'akeidah',
  );
  if (akeidahIdx < 0) {
    console.log(`  ! ${nusach}: no akeidah segment found — skipping`);
    continue;
  }
  const tail = data.segments.slice(akeidahIdx);
  data.segments = [...newHead, ...tail];
  writeJson(tp, data);
  console.log(`  shacharit_${nusach}: ${newHead.length} new head entries + ${tail.length} preserved`);
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
