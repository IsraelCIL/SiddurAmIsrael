// Phase E.8f — Fast day Torah reading + haftarah blessings.
//
// PUBLIC FAST DAYS (minor fasts + Tisha B'Av):
//   SHACHARIT: reads וַיְחַל (Shemot 32:11-14, 34:1-10) — 3 olim.
//   MINCHA:    same Torah reading (3 olim) + haftarah (Ashk+Sfard only).
//
// TORAH READING (Siddur_Sefard,_Torah_Readings,_Fast_Day_Torah_Reading):
//   item[1] — full text with inline aliyah markers `:שני` and
//   `:שלישי-מפטיר` (the 3rd oleh doubles as the Maftir who reads
//   the haftarah). We strip the `-מפטיר` suffix and display "שלישי".
//
// HAFTARAH (Siddur_Sefard,_Torah_Readings,_Fast_Day_Mincha_Haftara):
//   item[1] — Yishayah 55:6-56:8 (דִּרְשׁוּ ה' בְּהִמָּצְאוֹ).
//   EM does NOT read haftarah at mincha on public fast days.
//
// HAFTARAH BLESSINGS (Siddur_Sefard,_Shabbat_Morning_Services,_Haftarah_Blessings):
//   item[1]  — bracha before (אשר בחר בנביאים).
//   item[3]  — bracha after 1 (צור כל העולמים / הָאֵל הַנֶּאֱמָן).
//   item[4]  — bracha after 2 (רחם על ציון / מְשַׂמֵּחַ צִיּוֹן).
//   item[5]  — bracha after 3 (שמחנו / מָגֵן דָּוִד).
//
// Run from project root:  node scripts/phase_e8f_kriah_fast_day.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const READING_DIR = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common', 'torah_reading');
// Haftarah blessings live under a common prayer directory shared between services.
const HAFTARAH_DIR = path.join(ASSETS, 'common', 'haftarah');

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

// Split text at aliyah markers (:שני, :שלישי-מפטיר, :שלישי, :רביעי, :לוי, :ישראל).
// The fast-day source uses `:שני` and `:שלישי-מפטיר`; we normalise
// `שלישי-מפטיר` to just `שלישי` in the bold label.
function splitFastDayReading(raw) {
  let s = cleanHebrew(raw);
  // Replace `:שלישי-מפטיר` first (longer match must precede `:שלישי`).
  s = s.replace(
    /:שלישי-מפטיר(?=[א-ת])/g,
    ': ‹‹MARK=שלישי›› ',
  );
  // Generic aliyah markers (שני, שלישי, רביעי, לוי, ישראל).
  s = s.replace(
    /:(שני|שלישי|רביעי|לוי|ישראל)(?=[א-ת])/g,
    (_, w) => `: ‹‹MARK=${w}›› `,
  );
  const parts = s.split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
  const out = [];
  for (const p of parts) {
    const trimmed = p.trim();
    if (!trimmed) continue;
    const m = trimmed.match(/^‹‹MARK=(.+?)›› ?\s*(.*)$/);
    if (m) {
      out.push(`<b>— ${m[1]} —</b>`);
      if (m[2].trim()) out.push(m[2].trim());
    } else {
      out.push(trimmed);
    }
  }
  return out;
}

// Clean a blessing/haftarah block: strip trope, normalise whitespace.
function cleanBlock(raw) {
  const s = cleanHebrew(raw);
  // Split into natural phrase groups at sof-pasuk / niqqud pauses for
  // readability per project JSON formatting rules (>80 chars → array).
  const chunks = s.split(/(?<=:)\s+/).filter((c) => c.trim());
  return chunks.length <= 1 ? s : chunks;
}

(async () => {
  const manifest = readJson(MANIFEST_PATH);
  if (!manifest.common) manifest.common = {};

  // ── Torah reading (same text, shacharit + mincha) ─────────────────────────
  process.stdout.write('  fetching fast day Torah reading ... ');
  const torahArr = await fetchSefaria(
    'Siddur_Sefard,_Torah_Readings,_Fast_Day_Torah_Reading',
  );
  if (!Array.isArray(torahArr)) throw new Error('expected array');
  console.log(`${torahArr.length} items`);
  const torahLines = splitFastDayReading(String(torahArr[1] ?? '').trim());
  const torahPath = path.join(READING_DIR, 'kriah_fast_day.json');
  writeJson(torahPath, {
    id: 'kriah_fast_day',
    sections: [{ text: torahLines, condition_flags: [], exclude_flags: [] }],
  });
  manifest.common['kriah_fast_day'] = rel(torahPath);
  console.log(`  kriah_fast_day: ${torahLines.length} lines`);

  // ── Haftarah text ─────────────────────────────────────────────────────────
  process.stdout.write('  fetching fast day haftarah ... ');
  const haftArr = await fetchSefaria(
    'Siddur_Sefard,_Torah_Readings,_Fast_Day_Mincha_Haftara',
  );
  if (!Array.isArray(haftArr)) throw new Error('expected array');
  console.log(`${haftArr.length} items`);
  const haftarahText = cleanBlock(String(haftArr[1] ?? '').trim());
  const haftarahPath = path.join(HAFTARAH_DIR, 'haftarah_taanit.json');
  writeJson(haftarahPath, {
    id: 'haftarah_taanit',
    sections: [{ text: haftarahText, condition_flags: [], exclude_flags: [] }],
  });
  manifest.common['haftarah_taanit'] = rel(haftarahPath);
  console.log('  haftarah_taanit: written');

  // ── Haftarah blessings ────────────────────────────────────────────────────
  process.stdout.write('  fetching haftarah blessings ... ');
  const brachArr = await fetchSefaria(
    'Siddur_Sefard,_Shabbat_Morning_Services,_Haftarah_Blessings',
  );
  if (!Array.isArray(brachArr)) throw new Error('expected array');
  console.log(`${brachArr.length} items`);

  const blessingDefs = [
    { id: 'haftarah_bracha_lifnei', idx: 1 },
    { id: 'haftarah_bracha_acharei_1', idx: 3 },
    { id: 'haftarah_bracha_acharei_2', idx: 4 },
    { id: 'haftarah_bracha_acharei_3', idx: 5 },
  ];
  for (const { id, idx } of blessingDefs) {
    const raw = String(brachArr[idx] ?? '').trim();
    if (!raw) { console.warn(`  ⚠ no text for ${id} (item ${idx})`); continue; }
    const text = cleanBlock(raw);
    const filePath = path.join(HAFTARAH_DIR, `${id}.json`);
    writeJson(filePath, {
      id,
      sections: [{ text, condition_flags: [], exclude_flags: [] }],
    });
    manifest.common[id] = rel(filePath);
    console.log(`  ${id}: written`);
  }

  // ── Update kriat_hatorah_mincha.json template ─────────────────────────────
  // Replace the old segment references and add haftarah blessings + EM gate.
  const minchaKriahTplPath = path.join(ASSETS, 'templates', 'kriat_hatorah_mincha.json');
  const minchaKriahTpl = readJson(minchaKriahTplPath);
  minchaKriahTpl.segments = [
    {
      segment_id: 'kriat_hatorah_hotzaah',
      condition_flags: ['with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    },
    {
      segment_id: 'kriah_fast_day',
      condition_flags: [],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    },
    {
      segment_id: 'hagbahah',
      condition_flags: [],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    },
    // EM does NOT read haftarah at mincha on public fast days.
    {
      segment_id: 'haftarah_bracha_lifnei',
      condition_flags: [],
      exclude_flags: [],
      optional: false,
      allowed_nusach: ['ashkenaz', 'sfard'],
    },
    {
      segment_id: 'haftarah_taanit',
      condition_flags: [],
      exclude_flags: [],
      optional: false,
      allowed_nusach: ['ashkenaz', 'sfard'],
    },
    {
      segment_id: 'haftarah_bracha_acharei_1',
      condition_flags: [],
      exclude_flags: [],
      optional: false,
      allowed_nusach: ['ashkenaz', 'sfard'],
    },
    {
      segment_id: 'haftarah_bracha_acharei_2',
      condition_flags: [],
      exclude_flags: [],
      optional: false,
      allowed_nusach: ['ashkenaz', 'sfard'],
    },
    {
      segment_id: 'haftarah_bracha_acharei_3',
      condition_flags: [],
      exclude_flags: [],
      optional: false,
      allowed_nusach: ['ashkenaz', 'sfard'],
    },
    {
      segment_id: 'kriat_hatorah_hachnasah',
      condition_flags: ['with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    },
    {
      sub_template_id: 'chatzi_kaddish',
      condition_flags: ['with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    },
  ];
  writeJson(minchaKriahTplPath, minchaKriahTpl);
  console.log(`  ${rel(minchaKriahTplPath)}: updated (10 entries)`);

  // ── Update shacharit acharei_amidah templates ─────────────────────────────
  // Add kriah_fast_day after the last kriah_* entry, gated on fast_day + with_minyan.
  // Idempotent: remove any prior kriah_fast_day entry first.
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tplPath = path.join(
      ASSETS, 'templates', 'shacharit', `acharei_amidah_${nusach}.json`,
    );
    const tpl = readJson(tplPath);
    // Remove any stale entry.
    tpl.segments = tpl.segments.filter(
      (s) => !(s.segment_id === 'kriah_fast_day'),
    );
    // Anchor: after the last kriah_* entry.
    let lastIdx = -1;
    for (let i = 0; i < tpl.segments.length; i++) {
      const id = tpl.segments[i].segment_id ?? '';
      if (id.startsWith('kriah_')) lastIdx = i;
    }
    if (lastIdx < 0) {
      console.warn(`  ⚠ ${nusach}: no kriah_* anchor found`);
      continue;
    }
    tpl.segments.splice(lastIdx + 1, 0, {
      segment_id: 'kriah_fast_day',
      condition_flags: ['fast_day', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    writeJson(tplPath, tpl);
    console.log(`  acharei_amidah_${nusach}: inserted kriah_fast_day at idx ${lastIdx + 1}`);
  }

  // ── Manifest ──────────────────────────────────────────────────────────────
  function sortKeys(o) {
    if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
    const out = {};
    for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
    return out;
  }
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

  console.log('\nDONE.');
})().catch((e) => { console.error(e); process.exit(1); });
