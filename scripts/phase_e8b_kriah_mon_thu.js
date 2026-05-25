// Phase E.8b — Monday/Thursday Torah reading for the upcoming parashah.
//
// Source: Siddur Sefard, Torah Readings, Torah Reading for Shabbat Mincha
// & Monday, Thursday. The page is a flat array of ~110 paragraphs that
// alternates between parashah-name headers (e.g. "פרשת בראשית") and the
// reading body (kohen + levi + yisrael combined as one Hebrew text).
//
// We split the page into 54 individual parashot, slugify the parashah
// name to match kosher_dart's Parsha enum (lowercased), and write one
// segment per parashah under common/torah_reading/mon_thu/.
//
// Combined parshiot are intentionally absent here — when next Shabbat
// is e.g. Tazria-Metzora, the calendar collapses it to "tazria" and we
// look up tazria's reading. Single parshiot fully cover all Mon/Thu
// scenarios.
//
// Also writes _kriah_mon_thu_mapping.json keyed by parashah slug →
// segment_id, plus a placeholder segment `kriat_hatorah_reading_text`
// that the KriahPostProcessor swaps at runtime.
//
// Run from project root:  node scripts/phase_e8b_kriah_mon_thu.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const READING_DIR = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common', 'torah_reading', 'mon_thu');
const MAPPING_PATH = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common', 'torah_reading', '_kriah_mon_thu_mapping.json');
const PLACEHOLDER_PATH = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common', 'kriat_hatorah_reading_text.json');

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

function fetchSefaria(ref) {
  return new Promise((resolve, reject) => {
    const url = `https://www.sefaria.org/api/v3/texts/${ref}?return_format=text_only&version=hebrew`;
    https.get(url, (res) => {
      let raw = '';
      res.setEncoding('utf8');
      res.on('data', (c) => { raw += c; });
      res.on('end', () => {
        try { resolve(JSON.parse(raw).versions[0].text); }
        catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

function cleanHebrew(s) {
  return s.replace(/[֑-֯]/g, '').replace(/׃/g, ':').replace(/\s+/g, ' ').trim();
}

function splitToLines(s) {
  return cleanHebrew(s).split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
}

// Parashah name (as printed in Sefaria) → kosher_dart Parsha enum slug.
// Slug is the enum name lowercased (e.g. Parsha.BERESHIS → "bereshis").
const NAME_TO_SLUG = {
  'בראשית': 'bereshis',
  'נח': 'noach',
  'לך לך': 'lech_lecha',
  'וירא': 'vayera',
  'חיי שרה': 'chayei_sara',
  'תולדות': 'toldos',
  'ויצא': 'vayetzei',
  'וישלח': 'vayishlach',
  'וישב': 'vayeshev',
  'מקץ': 'miketz',
  'ויגש': 'vayigash',
  'ויחי': 'vayechi',
  'שמות': 'shemos',
  'וארא': 'vaera',
  'בא': 'bo',
  'בשלח': 'beshalach',
  'יתרו': 'yisro',
  'משפטים': 'mishpatim',
  'תרומה': 'terumah',
  'תצוה': 'tetzaveh',
  'כי תשא': 'ki_sisa',
  'ויקהל': 'vayakhel',
  'פקודי': 'pekudei',
  'ויקרא': 'vayikra',
  'צו': 'tzav',
  'שמיני': 'shmini',
  'תזריע': 'tazria',
  'מצורע': 'metzora',
  'אחרי מות': 'achrei_mos',
  'אחרי': 'achrei_mos',
  'קדושים': 'kedoshim',
  'אמור': 'emor',
  'בהר': 'behar',
  'בחקתי': 'bechukosai',
  'בחוקותי': 'bechukosai',
  'במדבר': 'bamidbar',
  'נשא': 'nasso',
  'בהעלתך': 'behaaloscha',
  'בהעלותך': 'behaaloscha',
  'שלח': 'shlach',
  'קרח': 'korach',
  'חקת': 'chukas',
  'חוקת': 'chukas',
  'בלק': 'balak',
  'פינחס': 'pinchas',
  'פנחס': 'pinchas',
  'מטות': 'matos',
  'מסעי': 'masei',
  'דברים': 'devarim',
  'ואתחנן': 'vaeschanan',
  'עקב': 'eikev',
  'ראה': 'reeh',
  'שופטים': 'shoftim',
  'כי תצא': 'ki_seitzei',
  'כי תבוא': 'ki_savo',
  'כי תבא': 'ki_savo',
  'נצבים': 'nitzavim',
  'וילך': 'vayeilech',
  'האזינו': 'haazinu',
  'וזאת הברכה': 'vzos_haberacha',
};

(async () => {
  process.stdout.write('  fetching Mon/Thu Torah readings page ... ');
  const text = await fetchSefaria(
    'Siddur_Sefard,_Torah_Readings,_Torah_Reading_for_Shabbat_Mincha_%26_Monday,_Thursday',
  );
  if (!Array.isArray(text)) throw new Error('expected array text');
  console.log(`${text.length} entries`);

  // Parse: alternating header / body, starting from after the page header lines.
  // Each entry that starts with "פרשת " is a parashah name; the next entry is
  // the reading body.
  const manifest = readJson(MANIFEST_PATH);
  fs.mkdirSync(READING_DIR, { recursive: true });
  const mapping = {};
  let writtenCount = 0;

  for (let i = 0; i < text.length; i++) {
    const t = String(text[i]).trim();
    if (!t.startsWith('פרשת ')) continue;
    const parashahName = t.replace(/^פרשת\s+/, '').trim();
    const slug = NAME_TO_SLUG[parashahName];
    if (!slug) {
      console.warn(`  ⚠ unknown parashah name "${parashahName}" at index ${i}`);
      continue;
    }
    const body = String(text[i + 1] ?? '').trim();
    if (!body) {
      console.warn(`  ⚠ no body for ${parashahName}`);
      continue;
    }
    const lines = splitToLines(body);
    const segmentId = `kriah_mon_thu_${slug}`;
    const filePath = path.join(READING_DIR, `${segmentId}.json`);
    writeJson(filePath, {
      id: segmentId,
      sections: [{ text: lines, condition_flags: [], exclude_flags: [] }],
    });
    manifest.common[segmentId] = rel(filePath);
    mapping[slug] = segmentId;
    writtenCount++;
  }
  console.log(`  wrote ${writtenCount} parashah segments`);

  // Mapping file
  writeJson(MAPPING_PATH, mapping);
  manifest.common['_kriah_mon_thu_mapping'] = rel(MAPPING_PATH);
  console.log(`  wrote ${rel(MAPPING_PATH)} (${Object.keys(mapping).length} entries)`);

  // Placeholder segment that the KriahPostProcessor will fill at runtime.
  writeJson(PLACEHOLDER_PATH, {
    id: 'kriat_hatorah_reading_text',
    sections: [
      { text: ['{{kriah_text}}'], condition_flags: [], exclude_flags: [] },
    ],
  });
  manifest.common['kriat_hatorah_reading_text'] = rel(PLACEHOLDER_PATH);
  console.log(`  wrote ${rel(PLACEHOLDER_PATH)} (placeholder)`);

  // ── Insert placeholder into templates (between brachot and hagbahah) ─────
  // Position rule: AFTER kriat_hatorah_shacharit (the brachot block).
  // For Ashk/Sfard the next segment is hagbahah. For EM the next is yehi_ratzon.
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tplPath = path.join(
      ASSETS, 'templates', 'shacharit', `acharei_amidah_${nusach}.json`,
    );
    const tpl = readJson(tplPath);
    if (tpl.segments.some((s) => s.segment_id === 'kriat_hatorah_reading_text')) {
      console.log(`  ${rel(tplPath)}: already patched`);
      continue;
    }
    const idx = tpl.segments.findIndex(
      (s) => s.segment_id === 'kriat_hatorah_shacharit',
    );
    if (idx < 0) {
      console.log(`  ${rel(tplPath)}: kriat_hatorah_shacharit not found`);
      continue;
    }
    tpl.segments.splice(idx + 1, 0, {
      segment_id: 'kriat_hatorah_reading_text',
      // Gate on kriat_hatorah_mon_thu for now (E.8b scope). Future E.8c-f
      // will add additional gates (kriat_hatorah_rc, etc.) for other days.
      condition_flags: ['kriat_hatorah_mon_thu', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted reading placeholder at idx ${idx + 1}`);
  }

  function sortKeys(o) {
    if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
    const out = {};
    for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
    return out;
  }
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

  console.log('\nDONE.');
})().catch((e) => { console.error(e); process.exit(1); });
