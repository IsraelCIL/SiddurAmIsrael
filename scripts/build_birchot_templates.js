// Build per-nusach Birchot HaShachar and Birchot HaTorah templates.
//
// Each template lists segment_id entries in the right liturgical order for
// that nusach. The main shacharit templates (shacharit_ashkenaz, _sfard,
// _edot_mizrach) reference these via sub_template_id.
//
// Per-nusach text differences are handled by the segment files themselves
// (the assembler resolves nusach/{nusach}/{id}.json before falling back to
// common/{id}.json).

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';

function entry(segId, opts = {}) {
  return {
    segment_id: segId,
    condition_flags: opts.cond || [],
    exclude_flags: opts.excl || [],
    optional: !!opts.optional,
    allowed_nusach: opts.allowedNusach || [],
  };
}

function writeTemplate(filename, id, name, segments) {
  const obj = { id, name, segments };
  fs.writeFileSync(
    path.join(PROJECT, 'assets/prayers/templates/' + filename),
    JSON.stringify(obj, null, 2) + '\n',
    'utf8',
  );
  console.log('  wrote', filename, '(' + segments.length + ' entries)');
}

// ─── Birchot HaTorah templates ───────────────────────────────────────────────
// All three nusachim say the same 3 brachot in the same order, but each with
// per-nusach text. After the 3 brachot: Birkat Kohanim verses + Eilu Devarim.

const birchotHatorahCommon = [
  entry('birchot_hatorah_asher_bachar'),
  entry('birchot_hatorah_vehaarev'),
  entry('birchot_hatorah_natan_torah'),
  entry('birchot_hatorah_pesukim'),
  entry('elu_devarim'),
];

writeTemplate('birchot_hatorah_ashkenaz.json', 'birchot_hatorah_ashkenaz', 'ברכות התורה', birchotHatorahCommon);
writeTemplate('birchot_hatorah_sfard.json', 'birchot_hatorah_sfard', 'ברכות התורה', birchotHatorahCommon);
writeTemplate('birchot_hatorah_edot_mizrach.json', 'birchot_hatorah_edot_mizrach', 'ברכות התורה', birchotHatorahCommon);

// ─── Birchot HaShachar templates ─────────────────────────────────────────────

// Ashkenaz order (per Sefaria Siddur Ashkenaz, Shacharit, Preparatory Prayers,
// Morning Blessings). The Ashkenaz custom recites Asher Yatzar / Elokai
// Neshama at washing time but most modern siddurim include them in the BHS
// recital. We list everything in liturgical order; the main shacharit
// template can reorder if needed.
writeTemplate('birchot_hashachar_ashkenaz.json', 'birchot_hashachar_ashkenaz', 'ברכות השחר', [
  entry('al_netilat_yadayim'),
  entry('asher_yatzar'),
  entry('elokai_neshama'),
  entry('hanoten_lasechvi'),
  entry('shelo_asani_goy'),
  entry('shelo_asani_eved'),
  entry('shelo_asani_ishah', { cond: ['gender_male'] }),
  entry('sheasani_kirtzono'),  // section is already gated by gender_female
  entry('pokeach_ivrim'),
  entry('malbish_arumim'),
  entry('matir_asurim'),
  entry('zokef_kefufim'),
  entry('rokea_haaretz'),
  entry('sheasah_li_kol_tzorki'),  // section already excludes tisha_beav & yom_kippur
  entry('hamechin_mitzedei_gever'),
  entry('ozer_yisrael'),
  entry('oter_yisrael'),
  entry('hanoten_layaef_koach'),
  entry('hamaavir_sheinah'),
  entry('yehi_ratzon_shelo_yavo'),
]);

// Sefard order — closely follows Ashkenaz but with shared positioning.
// (The Sefaria Sefard source splits Asher Yatzar + Elokai Neshama into a
// separate "Morning Blessings" section then puts the rest in "Blessings on
// Torah"; we collapse that back into a single ordered list here.)
writeTemplate('birchot_hashachar_sfard.json', 'birchot_hashachar_sfard', 'ברכות השחר', [
  entry('al_netilat_yadayim'),
  entry('asher_yatzar'),
  entry('elokai_neshama'),
  entry('hanoten_lasechvi'),
  entry('shelo_asani_goy'),
  entry('shelo_asani_eved'),
  entry('shelo_asani_ishah', { cond: ['gender_male'] }),
  entry('sheasani_kirtzono'),
  entry('pokeach_ivrim'),
  entry('malbish_arumim'),
  entry('matir_asurim'),
  entry('zokef_kefufim'),
  entry('rokea_haaretz'),
  entry('hamechin_mitzedei_gever'),
  entry('sheasah_li_kol_tzorki'),
  entry('ozer_yisrael'),
  entry('oter_yisrael'),
  entry('hanoten_layaef_koach'),
  entry('hamaavir_sheinah'),
  entry('yehi_ratzon_shelo_yavo'),
]);

// Edot HaMizrach order (per Sefaria Siddur Edot HaMizrach, Preparatory Prayers,
// Morning Blessings). Notable EM differences:
//   - hanoten_layaef_koach comes BEFORE rokea_haaretz
//   - the shelo_asani / sheasani_kirtzono block comes AFTER all the others
//   - sheasani_kirtzono is the short form (no shem v'malchut) — handled by
//     nusach/edot_mizrach/sheasani_kirtzono.json override
writeTemplate('birchot_hashachar_edot_mizrach.json', 'birchot_hashachar_edot_mizrach', 'ברכות השחר', [
  entry('al_netilat_yadayim'),
  entry('asher_yatzar'),
  entry('elokai_neshama'),
  entry('hanoten_lasechvi'),
  entry('pokeach_ivrim'),
  entry('matir_asurim'),
  entry('zokef_kefufim'),
  entry('malbish_arumim'),
  entry('hanoten_layaef_koach'),
  entry('rokea_haaretz'),
  entry('hamechin_mitzedei_gever'),
  entry('sheasah_li_kol_tzorki'),
  entry('ozer_yisrael'),
  entry('oter_yisrael'),
  entry('shelo_asani_goy'),
  entry('shelo_asani_eved'),
  entry('shelo_asani_ishah', { cond: ['gender_male'] }),
  entry('sheasani_kirtzono'),
  entry('hamaavir_sheinah'),
  entry('yehi_ratzon_shelo_yavo'),
]);

console.log('\nDONE.');
