// Phase E.8d — Chol HaMoed Pesach + Chol HaMoed Sukkot Torah readings.
//
// CHM PESACH (EY: 5 CHM days, 16–20 Nisan / pesachDay 2..6):
//   Each day has a 4-oleh reading split across TWO scrolls:
//     • Olim 1–3: that day's main reading (Vayikra Emor on day 2,
//       Shemos Kadesh on day 3, etc.)
//     • Oleh 4:   the same Bamidbar Pinchas "וְהִקְרַבְתֶּם" reading
//       (about korban Pesach) every day, from a second scroll.
//   Source: Siddur Sefard, Torah Readings, Torah Reading for Chol Hamoed
//   Pesach — items grouped 6-per-day (header / setup-note / book-ref /
//   main body / revi'i instruction / 4th-oleh body).
//
// CHM SUKKOT (EY: 6 CHM days including Hoshana Raba, sukkotDay 2..7):
//   Each day reads its specific korban from Bamidbar 29. Simpler
//   structure — one short passage per day, all 4 olim within. No inline
//   aliyah markers in the Sefaria source.
//   Source: Siddur Sefard, Torah Readings, Torah Reading for Chol Hamoed
//   Sukkot — items 2..7 map to sukkotDay 2..7.
//
// Run from project root:  node scripts/phase_e8d_kriah_chm.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const READING_DIR = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'common', 'torah_reading');

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

// Sefaria's CHM Pesach source uses explicit role labels (לוי / ישראל)
// instead of ordinals — so we accept both conventions.
const ALIYAH_WORDS = ['שני', 'שלישי', 'רביעי', 'לוי', 'ישראל'];
const ALIYAH_RE = new RegExp(
  `:(${ALIYAH_WORDS.join('|')})(?=[\\u05D0-\\u05EA])`,
  'g',
);

function splitWithMarkers(raw) {
  let s = cleanHebrew(raw);
  s = s.replace(ALIYAH_RE, (_, w) => `: ‹‹MARK=${w}››`);
  const parts = s.split(/(?<=:)\s+/).filter((p) => p.trim().length > 0);
  const out = [];
  for (const p of parts) {
    const m = p.match(/^‹‹MARK=(.+?)››\s*(.*)$/);
    if (m) {
      out.push(`<b>— ${m[1]} —</b>`);
      if (m[2].trim()) out.push(m[2].trim());
    } else {
      out.push(p);
    }
  }
  return out;
}

(async () => {
  const manifest = readJson(MANIFEST_PATH);

  // ── CHM PESACH ─────────────────────────────────────────────────────────────
  process.stdout.write('  fetching CHM Pesach page ... ');
  const pesachText = await fetchSefaria(
    'Siddur_Sefard,_Torah_Readings,_Torah_Reading_for_Chol_Hamoed_Pesach',
  );
  if (!Array.isArray(pesachText)) throw new Error('expected array');
  console.log(`${pesachText.length} entries`);

  // The page has a 1-item page header, then 5 day-blocks of 6 items each.
  // Within each block: [header, setup-note, book-ref, main-body,
  // revi'i-instruction, 4th-oleh-body]. We emit a segment whose text
  // combines: main body (with aliyah markers preserved) + bold revi'i
  // marker + 4th-oleh body.
  for (let i = 0; i < 5; i++) {
    const dayIdx = 1 + i * 6;
    const dayLabel = String(pesachText[dayIdx]).trim();
    const mainBody = String(pesachText[dayIdx + 3]).trim();
    const fourthOleh = String(pesachText[dayIdx + 5]).trim();
    const pesachDay = i + 2; // pesachDay 2..6 = CHM days 16..20 Nisan in EY.

    const mainLines = splitWithMarkers(mainBody);
    const fourthLines = cleanHebrew(fourthOleh)
      .split(/(?<=:)\s+/)
      .filter((p) => p.trim().length > 0);

    const text = [
      ...mainLines,
      '<b>— רביעי (ספר תורה שני) —</b>',
      ...fourthLines,
    ];

    const segmentId = `kriah_chm_pesach_day_${pesachDay}`;
    const filePath = path.join(READING_DIR, `${segmentId}.json`);
    writeJson(filePath, {
      id: segmentId,
      sections: [{ text, condition_flags: [], exclude_flags: [] }],
    });
    manifest.common[segmentId] = rel(filePath);
    console.log(`  ${segmentId} (${dayLabel}): ${text.length} lines`);
  }

  // ── CHM SUKKOT ─────────────────────────────────────────────────────────────
  process.stdout.write('  fetching CHM Sukkot page ... ');
  const sukkotText = await fetchSefaria(
    'Siddur_Sefard,_Torah_Readings,_Torah_Reading_for_Chol_Hamoed_Sukkot',
  );
  if (!Array.isArray(sukkotText)) throw new Error('expected array');
  console.log(`${sukkotText.length} entries`);

  // Items 2..7 = days 2..7 of Sukkot (matching sukkotDay flag exactly).
  // Each item is the daily korban passage for that day. We treat each as
  // a single segment with no inline aliyah markers (Sefaria source has
  // none — the 4 olim share the short text by community minhag).
  for (let day = 2; day <= 7; day++) {
    const body = String(sukkotText[day]).trim();
    const lines = cleanHebrew(body)
      .split(/(?<=:)\s+/)
      .filter((p) => p.trim().length > 0);
    const segmentId = `kriah_chm_sukkot_day_${day}`;
    const filePath = path.join(READING_DIR, `${segmentId}.json`);
    writeJson(filePath, {
      id: segmentId,
      sections: [{ text: lines, condition_flags: [], exclude_flags: [] }],
    });
    manifest.common[segmentId] = rel(filePath);
    console.log(`  ${segmentId}: ${lines.length} lines`);
  }

  // ── Patch templates ──────────────────────────────────────────────────────
  // For each nusach, insert 5 CHM Pesach entries + 6 CHM Sukkot entries
  // after the kriat_hatorah_reading_text placeholder (and after the
  // existing kriah_rc, if present). Each gated on its day flag + the
  // chol_hamoed flag + kriat_hatorah + with_minyan.
  for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
    const tplPath = path.join(
      ASSETS, 'templates', 'shacharit', `acharei_amidah_${nusach}.json`,
    );
    const tpl = readJson(tplPath);
    // Idempotent: first remove ALL prior kriah_chm_* entries (any
    // earlier run of this script), then re-insert in the up-to-date
    // form. This lets the script absorb shifts in our gating logic.
    tpl.segments = tpl.segments.filter(
      (s) => !(s.segment_id && s.segment_id.startsWith('kriah_chm_')),
    );
    // Anchor: after the last kriah_* entry in the existing template, or
    // after kriat_hatorah_reading_text if no kriah_rc.
    let lastIdx = -1;
    for (let i = 0; i < tpl.segments.length; i++) {
      const id = tpl.segments[i].segment_id;
      if (id === 'kriat_hatorah_reading_text' || id === 'kriah_rc') lastIdx = i;
    }
    if (lastIdx < 0) {
      console.log(`  ${rel(tplPath)}: no kriah anchor found`);
      continue;
    }

    const newEntries = [];
    // CHM Pesach entries — regular case + Thursday-YT1 shift.
    // Regular case: pesach_day_N reads kriah_chm_pesach_day_N.
    //   Day 4 + 5 excluded when pesach_yt1_thursday is set (shifted).
    // Thursday shift:
    //   pesach_day_4 (Sun, post-Shabbat) reads kriah_chm_pesach_day_3
    //     (would normally be day 3 = Shabbat in this scenario).
    //   pesach_day_5 (Mon) reads kriah_chm_pesach_day_4.
    //   Day 5 ("Psal Lecha", normally pesach_day_5) is consumed by
    //     Shabbat CHM (OOS) → no Mon/Tue reading for it.
    //   pesach_day_6 (Tue) unchanged.
    newEntries.push({
      segment_id: 'kriah_chm_pesach_day_2',
      condition_flags: ['pesach_day_2', 'chol_hamoed_pesach', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    newEntries.push({
      segment_id: 'kriah_chm_pesach_day_3',
      condition_flags: ['pesach_day_3', 'chol_hamoed_pesach', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    // Thursday-shift: pesach_day_4 reads day_3 content.
    newEntries.push({
      segment_id: 'kriah_chm_pesach_day_3',
      condition_flags: [
        'pesach_day_4',
        'chol_hamoed_pesach',
        'with_minyan',
        'pesach_yt1_thursday',
      ],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    // Regular day 4 — only when NOT in Thursday shift.
    newEntries.push({
      segment_id: 'kriah_chm_pesach_day_4',
      condition_flags: ['pesach_day_4', 'chol_hamoed_pesach', 'with_minyan'],
      exclude_flags: ['pesach_yt1_thursday'],
      optional: false,
      allowed_nusach: [],
    });
    // Thursday-shift: pesach_day_5 reads day_4 content.
    newEntries.push({
      segment_id: 'kriah_chm_pesach_day_4',
      condition_flags: [
        'pesach_day_5',
        'chol_hamoed_pesach',
        'with_minyan',
        'pesach_yt1_thursday',
      ],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    // Regular day 5 — only when NOT in Thursday shift.
    newEntries.push({
      segment_id: 'kriah_chm_pesach_day_5',
      condition_flags: ['pesach_day_5', 'chol_hamoed_pesach', 'with_minyan'],
      exclude_flags: ['pesach_yt1_thursday'],
      optional: false,
      allowed_nusach: [],
    });
    newEntries.push({
      segment_id: 'kriah_chm_pesach_day_6',
      condition_flags: ['pesach_day_6', 'chol_hamoed_pesach', 'with_minyan'],
      exclude_flags: [],
      optional: false,
      allowed_nusach: [],
    });
    for (let d = 2; d <= 7; d++) {
      newEntries.push({
        segment_id: `kriah_chm_sukkot_day_${d}`,
        condition_flags: [
          `sukkot_day_${d}`,
          'chol_hamoed_sukkot',
          'with_minyan',
        ],
        exclude_flags: [],
        optional: false,
        allowed_nusach: [],
      });
    }
    tpl.segments.splice(lastIdx + 1, 0, ...newEntries);

    // Chatzi Kaddish AFTER the last kriah_* entry — appears on any
    // kriat_hatorah day, between the reading block and yehi_ratzon
    // (Mon/Thu) or hagbahah (Ashk/Sfard) / yehi_ratzon (EM).
    // Idempotent: only insert if no chatzi_kaddish-after-kriah already
    // present at this position.
    const afterReadingIdx = lastIdx + 1 + newEntries.length;
    const alreadyHasKaddish =
      tpl.segments[afterReadingIdx] &&
      tpl.segments[afterReadingIdx].sub_template_id === 'chatzi_kaddish' &&
      Array.isArray(tpl.segments[afterReadingIdx].condition_flags) &&
      tpl.segments[afterReadingIdx].condition_flags.includes('kriat_hatorah');
    if (!alreadyHasKaddish) {
      tpl.segments.splice(afterReadingIdx, 0, {
        sub_template_id: 'chatzi_kaddish',
        condition_flags: ['kriat_hatorah', 'with_minyan'],
        exclude_flags: [],
      });
    }

    writeJson(tplPath, tpl);
    console.log(`  ${rel(tplPath)}: inserted ${newEntries.length} CHM entries + chatzi_kaddish at idx ${lastIdx + 1}`);
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
