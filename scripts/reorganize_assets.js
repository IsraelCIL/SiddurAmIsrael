// Phase A reorganization:
//   • Move every per-nusach and common segment file into a prayer-first
//     hierarchy under assets/prayers/{shacharit|mincha|maariv|shared_global}/...
//   • Generate assets/prayers/_manifest.json mapping every (nusach, segment_id)
//     pair (and template_id) to its physical asset path.
//   • Phase A is content-preserving: NO text changes; only file moves.
//
// Run from project root:  node scripts/reorganize_assets.js

const fs = require('fs');
const path = require('path');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');

// ─── Category mapping ───────────────────────────────────────────────────────
// Every segment_id known to live under common/ or nusach/<n>/ must map to a
// destination folder relative to assets/prayers/.
//
// Files multi-referenced across prayer templates (shacharit AND mincha,
// shacharit AND maariv, etc.) go to shared_global/* to avoid forcing a single
// prayer "home".

const CATEGORY = {
  // ── shacharit/lifnei_hatfila ───────────────────────────────────────────
  'al_netilat_yadayim':              'shacharit/lifnei_hatfila',
  'asher_yatzar':                    'shacharit/lifnei_hatfila',
  'elokai_neshama':                  'shacharit/lifnei_hatfila',
  'hanoten_lasechvi':                'shacharit/lifnei_hatfila',
  'shelo_asani_goy':                 'shacharit/lifnei_hatfila',
  'shelo_asani_eved':                'shacharit/lifnei_hatfila',
  'shelo_asani_ishah':               'shacharit/lifnei_hatfila',
  'sheasani_kirtzono':               'shacharit/lifnei_hatfila',
  'pokeach_ivrim':                   'shacharit/lifnei_hatfila',
  'malbish_arumim':                  'shacharit/lifnei_hatfila',
  'matir_asurim':                    'shacharit/lifnei_hatfila',
  'zokef_kefufim':                   'shacharit/lifnei_hatfila',
  'rokea_haaretz':                   'shacharit/lifnei_hatfila',
  'sheasah_li_kol_tzorki':           'shacharit/lifnei_hatfila',
  'hamechin_mitzedei_gever':         'shacharit/lifnei_hatfila',
  'ozer_yisrael':                    'shacharit/lifnei_hatfila',
  'oter_yisrael':                    'shacharit/lifnei_hatfila',
  'hanoten_layaef_koach':            'shacharit/lifnei_hatfila',
  'hamaavir_sheinah':                'shacharit/lifnei_hatfila',
  'yehi_ratzon_shelo_yavo':          'shacharit/lifnei_hatfila',
  'birchot_hatorah_asher_bachar':    'shacharit/lifnei_hatfila',
  'birchot_hatorah_vehaarev':        'shacharit/lifnei_hatfila',
  'birchot_hatorah_natan_torah':     'shacharit/lifnei_hatfila',
  'birchot_hatorah_pesukim':         'shacharit/lifnei_hatfila',
  'elu_devarim':                     'shacharit/lifnei_hatfila',
  'akeidah':                         'shacharit/lifnei_hatfila',
  'akeidah_yehi_ratzon':             'shacharit/lifnei_hatfila',
  'leolam_yehe_adam':                'shacharit/lifnei_hatfila',
  'korbanot':                        'shacharit/lifnei_hatfila',
  'lshem_yichud':                    'shacharit/lifnei_hatfila',
  'birchot_hashachar':               'shacharit/lifnei_hatfila',   // legacy orphan common file — moved for archival; delete in Phase B
  'petihat_eliyahu':                 'mincha/lifnei_mincha',

  // ── shacharit/pesukei_dezimra ──────────────────────────────────────────
  'hodu':                            'shacharit/pesukei_dezimra',
  'psalm_030':                       'shacharit/pesukei_dezimra',
  'hashem_melech':                   'shacharit/pesukei_dezimra',
  'psalm_067':                       'shacharit/pesukei_dezimra',
  'baruch_sheamar':                  'shacharit/pesukei_dezimra',
  'mizmor_letodah':                  'shacharit/pesukei_dezimra',
  'yehi_kevod':                      'shacharit/pesukei_dezimra',
  'yehi_chasdecha':                  'shacharit/pesukei_dezimra',
  'psalm_146':                       'shacharit/pesukei_dezimra',
  'psalm_147':                       'shacharit/pesukei_dezimra',
  'psalm_148':                       'shacharit/pesukei_dezimra',
  'psalm_149':                       'shacharit/pesukei_dezimra',
  'psalm_150':                       'shacharit/pesukei_dezimra',
  'az_yashir':                       'shacharit/pesukei_dezimra',
  'vayevarech_david':                'shacharit/pesukei_dezimra',
  'yishtabach':                      'shacharit/pesukei_dezimra',

  // ── shacharit/birkot_kriat_shema ───────────────────────────────────────
  'yotzer_or':                       'shacharit/birkot_kriat_shema',
  'ahavah_rabbah':                   'shacharit/birkot_kriat_shema',
  'emet_veyatziv':                   'shacharit/birkot_kriat_shema',
  // ahavat_olam → shared_global (also used in Maariv)
  // shema → shared_global

  // ── shacharit/acharei_amidah ───────────────────────────────────────────
  'hallel':                          'shacharit/acharei_amidah',
  'hallel_half':                     'shacharit/acharei_amidah',
  'kriat_hatorah_hotzaah':           'shacharit/acharei_amidah',
  'kriat_hatorah_shacharit':         'shacharit/acharei_amidah',
  'kriat_hatorah_hachnasah':         'shacharit/acharei_amidah',
  'hagbahah':                        'shacharit/acharei_amidah',
  'yehi_ratzon':                     'shacharit/acharei_amidah',
  'beit_yaakov':                     'shacharit/acharei_amidah',
  'tefila_ledavid_ps86':             'shacharit/acharei_amidah',
  'shir_hamaalot_lulei':             'shacharit/acharei_amidah',
  'yehi_shem':                       'shacharit/acharei_amidah',
  'uva_letzion':                     'shacharit/acharei_amidah',

  // ── shacharit/sof_hatfila ──────────────────────────────────────────────
  'ein_keloheinu':                   'shacharit/sof_hatfila',
  'pitum_haketoreh':                 'shacharit/sof_hatfila',
  'shir_shel_yom_sunday':            'shacharit/sof_hatfila',
  'shir_shel_yom_monday':            'shacharit/sof_hatfila',
  'shir_shel_yom_tuesday':           'shacharit/sof_hatfila',
  'shir_shel_yom_wednesday':         'shacharit/sof_hatfila',
  'shir_shel_yom_thursday':          'shacharit/sof_hatfila',
  'shir_shel_yom_friday':            'shacharit/sof_hatfila',
  'shir_shel_yom_shabbat':           'shacharit/sof_hatfila',
  'shofar_elul':                     'shacharit/sof_hatfila',

  // ── mincha/acharei_amidah ──────────────────────────────────────────────
  'kriat_hatorah_mincha':            'mincha/acharei_amidah',

  // ── maariv/lifnei_maariv ───────────────────────────────────────────────
  'vehu_rachum_arvit':               'maariv/lifnei_maariv',
  'hashem_tzvaot_maariv':            'maariv/lifnei_maariv',

  // ── maariv/birkot_kriat_shema ──────────────────────────────────────────
  'maariv_aravim':                   'maariv/birkot_kriat_shema',
  'emet_veemunh':                    'maariv/birkot_kriat_shema',
  'hashkivenu':                      'maariv/birkot_kriat_shema',
  'yiru_einenu':                     'maariv/birkot_kriat_shema',

  // ── shared_global (multi-prayer or shared text) ───────────────────────
  'ashrei':                          'shared_global',
  'aleinu':                          'shared_global',
  'ladavid':                         'shared_global',
  'shema':                           'shared_global',
  'barchu':                          'shared_global',
  'ahavat_olam':                     'shared_global',          // Shacharit Sfard/EM + Maariv all
  'avinu_malkeinu':                  'shared_global',          // Shacharit + Mincha
  'lamenatzeach':                    'shared_global',          // Shacharit + Mincha EM
  'selichot':                        'shared_global',          // Shacharit + Mincha
  'psalm_091':                       'shared_global',          // Maariv Motzaei Shabbat
  'psalm_121':                       'shared_global',
  'psalm_124':                       'shared_global',
  'psalm_134':                       'shared_global',

  // amidah sub-parts (shared across Shacharit / Mincha / Maariv)
  'amidah_intro':                    'shared_global/amidah',
  'amidah_avot':                     'shared_global/amidah',
  'amidah_gevurot':                  'shared_global/amidah',
  'amidah_kedushah_hashem':          'shared_global/amidah',
  'amidah_daat':                     'shared_global/amidah',
  'amidah_teshuva':                  'shared_global/amidah',
  'amidah_selicha':                  'shared_global/amidah',
  'amidah_geula':                    'shared_global/amidah',
  'amidah_refuah':                   'shared_global/amidah',
  'amidah_shanim':                   'shared_global/amidah',
  'amidah_galuyot':                  'shared_global/amidah',
  'amidah_mishpat':                  'shared_global/amidah',
  'amidah_minim':                    'shared_global/amidah',
  'amidah_tzaddikim':                'shared_global/amidah',
  'amidah_yerushalayim':             'shared_global/amidah',
  'amidah_david':                    'shared_global/amidah',
  'amidah_shema_koleinu':            'shared_global/amidah',
  'amidah_retzeh':                   'shared_global/amidah',
  'amidah_modim':                    'shared_global/amidah',
  'amidah_shalom':                   'shared_global/amidah',
  'amidah_conclusion':               'shared_global/amidah',
  'birkat_kohanim':                  'shared_global/amidah',
  'modim_derabanan':                 'shared_global/amidah',
  'kedushah':                        'shared_global/amidah',
  'kedushah_ledorvador':             'shared_global/amidah',
  'anenu_shliach_tzibur':            'shared_global/amidah',
  'shomer_yisrael':                  'shared_global/amidah',
  'elokeinu_velohei_avoteinu':       'shared_global/amidah',

  // kaddish sub-parts (shared across all kaddish templates)
  'kaddish_body':                    'shared_global/kaddish',
  'kaddish_closing':                 'shared_global/kaddish',
  'kaddish_derabanan_paragraph':     'shared_global/kaddish',
  'kaddish_titkabal_paragraph':      'shared_global/kaddish',

  // tachanun sub-parts (shared across Shacharit + Mincha tachanun sub-templates)
  'tachanun':                              'shared_global/tachanun',
  'tachanun_nfilat_apayim':                'shared_global/tachanun',
  'tachanun_monday_thursday_addition':     'shared_global/tachanun',
  'tachanun_em_selichot_monday_thursday':  'shared_global/tachanun',
  'vehu_rachum':                           'shared_global/tachanun',
  'vidui_yud_gimel_midot':                 'shared_global/tachanun',
};

// ─── Helpers ────────────────────────────────────────────────────────────────

function move(src, dst) {
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  fs.renameSync(src, dst);
}

function relAsset(absPath) {
  // Always emit with forward slashes so Flutter asset keys stay portable.
  return path
    .relative(PROJECT, absPath)
    .replace(/\\/g, '/');
}

function categoryFor(segId) {
  const cat = CATEGORY[segId];
  if (!cat) {
    throw new Error(`UNCATEGORIZED segment_id: ${segId}`);
  }
  return cat;
}

function targetPath(category, scope, segId) {
  // scope === 'common' or 'nusach/<n>'
  return path.join(ASSETS, category, scope, `${segId}.json`);
}

// ─── Build manifest ─────────────────────────────────────────────────────────

const manifest = {
  templates: {},
  nusach: { ashkenaz: {}, sfard: {}, edot_mizrach: {} },
  common: {},
};

// Templates stay in place.
for (const f of fs.readdirSync(path.join(ASSETS, 'templates'))) {
  if (!f.endsWith('.json')) continue;
  const id = f.replace(/\.json$/, '');
  manifest.templates[id] = `assets/prayers/templates/${f}`;
}

// Move per-nusach files.
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const dir = path.join(ASSETS, 'nusach', nusach);
  if (!fs.existsSync(dir)) continue;
  for (const f of fs.readdirSync(dir)) {
    if (!f.endsWith('.json')) continue;
    const segId = f.replace(/\.json$/, '');
    const category = categoryFor(segId);
    const dst = targetPath(category, `nusach/${nusach}`, segId);
    move(path.join(dir, f), dst);
    manifest.nusach[nusach][segId] = relAsset(dst);
  }
}

// Move common files.
const commonDir = path.join(ASSETS, 'common');
if (fs.existsSync(commonDir)) {
  for (const f of fs.readdirSync(commonDir)) {
    if (!f.endsWith('.json')) continue;
    const segId = f.replace(/\.json$/, '');
    const category = categoryFor(segId);
    const dst = targetPath(category, 'common', segId);
    move(path.join(commonDir, f), dst);
    manifest.common[segId] = relAsset(dst);
  }
}

// Sort manifest keys for stable diffs.
function sortKeys(obj) {
  const out = {};
  for (const k of Object.keys(obj).sort()) {
    const v = obj[k];
    out[k] = (v && typeof v === 'object' && !Array.isArray(v)) ? sortKeys(v) : v;
  }
  return out;
}
const sorted = {
  templates: sortKeys(manifest.templates),
  nusach: {
    ashkenaz: sortKeys(manifest.nusach.ashkenaz),
    sfard: sortKeys(manifest.nusach.sfard),
    edot_mizrach: sortKeys(manifest.nusach.edot_mizrach),
  },
  common: sortKeys(manifest.common),
};

fs.writeFileSync(
  path.join(ASSETS, '_manifest.json'),
  JSON.stringify(sorted, null, 2) + '\n',
  'utf8',
);

// Cleanup: remove now-empty old folders.
function rmEmpty(dir) {
  if (!fs.existsSync(dir)) return;
  if (fs.statSync(dir).isDirectory() && fs.readdirSync(dir).length === 0) {
    fs.rmdirSync(dir);
  }
}
rmEmpty(path.join(ASSETS, 'nusach', 'ashkenaz'));
rmEmpty(path.join(ASSETS, 'nusach', 'sfard'));
rmEmpty(path.join(ASSETS, 'nusach', 'edot_mizrach'));
rmEmpty(path.join(ASSETS, 'nusach'));
rmEmpty(path.join(ASSETS, 'common'));

const counts = {
  templates: Object.keys(sorted.templates).length,
  ashkenaz: Object.keys(sorted.nusach.ashkenaz).length,
  sfard: Object.keys(sorted.nusach.sfard).length,
  edot_mizrach: Object.keys(sorted.nusach.edot_mizrach).length,
  common: Object.keys(sorted.common).length,
};
console.log('Manifest entries:', counts);
console.log('DONE.');
