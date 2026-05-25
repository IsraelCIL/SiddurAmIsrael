// Phase E.5b — EM Hoshanot, per-nusach override from Wikisource.
//
// Source: https://he.wikisource.org/wiki/הושענות/נוסח_עדות_המזרח
// Wiki sections used: "הושענות ליום השני" .. "השישי" + "להושענא רבא".
// Day 1 (YT) and Shabbat are OOS per user (2026-05-25).
//
// Strategy: parse the page's wikitext, slice out each day's section,
// strip wiki templates ({{עם-ניקוד|…}}, {{ש}}, '''bold''', [[link]] etc.),
// keep niqqud, then split paragraphs into JSON-array lines.
//
// Writes per-nusach EM overrides for the segment_ids that E.5a created
// under common/. PrayerLocalDatasource prefers manifest.nusach over
// manifest.common, so EM users get the Wikisource text while Ashk + Sfard
// continue to use the shared Sefaria text.
//
// Run from project root:  node scripts/phase_e5b_hoshanot_em.js

const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const NUSACH_DIR = path.join(ASSETS, 'shacharit', 'acharei_amidah', 'nusach', 'edot_mizrach', 'hoshanot');
const WIKI_URL = 'https://he.wikisource.org/w/api.php?action=parse&page=%D7%94%D7%95%D7%A9%D7%A2%D7%A0%D7%95%D7%AA/%D7%A0%D7%95%D7%A1%D7%97_%D7%A2%D7%93%D7%95%D7%AA_%D7%94%D7%9E%D7%96%D7%A8%D7%97&format=json&prop=wikitext';

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      // Mirror curl --ssl-no-revoke for Windows schannel.
      rejectUnauthorized: true,
      headers: { 'User-Agent': 'smart-siddur-build/1.0' },
    }, (res) => {
      let raw = '';
      res.setEncoding('utf8');
      res.on('data', (c) => { raw += c; });
      res.on('end', () => resolve(raw));
    });
    req.on('error', reject);
    req.end();
  });
}

// Strip wiki markup, preserving Hebrew text + niqqud. Convert {{ש}} to
// a hard line-break sentinel that survives the JSON split, then convert
// it to actual newlines at the end so paragraphs split correctly.
function stripWiki(s) {
  return s
    // Strip the עם-ניקוד wrapper template — keep the inner payload.
    .replace(/\{\{עם-ניקוד\|([\s\S]*?)\}\}/g, '$1')
    // Line-break template
    .replace(/\{\{ש\}\}/g, '\n')
    // Other inline templates we just strip with their inner argument
    // (e.g. {{ממס|תהלים}}, {{הור|...}}) — keep the last pipe-segment.
    .replace(/\{\{[^{}]*?\|([^{}|]+?)\}\}/g, '$1')
    // Now strip any remaining empty/standalone templates.
    .replace(/\{\{[^{}]*?\}\}/g, '')
    // [[wikilink|display]] → display; [[wikilink]] → wikilink
    .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, '$2')
    .replace(/\[\[([^\]]+)\]\]/g, '$1')
    // ''' bold ''' → strip (we don't render Gra-style letter-highlights here)
    .replace(/'''([^']+?)'''/g, '$1')
    // '' italic '' → strip
    .replace(/''([^']+?)''/g, '$1')
    // <ref>...</ref> footnotes — strip
    .replace(/<ref[\s\S]*?<\/ref>/g, '')
    .replace(/<ref[^>]*\/>/g, '')
    // HTML comments
    .replace(/<!--[\s\S]*?-->/g, '')
    // Stray HTML tags
    .replace(/<[^>]+>/g, '');
}

function cleanHebrew(s) {
  return s.replace(/[֑-֯]/g, '').replace(/׃/g, ':');
}

// Convert a wiki section's text into sections array.
// Paragraphs are split on blank lines. Each paragraph's lines split at
// (1) {{ש}} → newline, and (2) sof-pasuk : within the line.
function sectionToBlocks(raw) {
  const cleaned = cleanHebrew(stripWiki(raw)).trim();
  if (!cleaned) return [];
  // Split on blank line(s) → paragraphs.
  const paragraphs = cleaned.split(/\n\s*\n/);
  const out = [];
  for (const para of paragraphs) {
    // Inside a paragraph: each newline (from {{ש}}) is a line. Then for
    // longer lines, also split at sof-pasuk colon.
    const lines = [];
    for (const rawLine of para.split('\n')) {
      const line = rawLine.replace(/\s+/g, ' ').trim();
      if (!line) continue;
      // Split each line further at sof-pasuk colons.
      const subs = line.split(/(?<=:)\s+/);
      for (const sub of subs) {
        const t = sub.trim();
        if (t) lines.push(t);
      }
    }
    if (lines.length === 0) continue;
    out.push({ text: lines, condition_flags: [], exclude_flags: [] });
  }
  return out;
}

// Days to process. Section headers (Hebrew) and target segment_ids.
const DAYS = [
  { day: 2, header: 'הושענות ליום השני',    segmentId: 'hoshanot_day_2' },
  { day: 3, header: 'הושענות ליום השלישי',  segmentId: 'hoshanot_day_3' },
  { day: 4, header: 'הושענות ליום הרביעי',  segmentId: 'hoshanot_day_4' },
  { day: 5, header: 'הושענות ליום החמישי',  segmentId: 'hoshanot_day_5' },
  { day: 6, header: 'הושענות ליום השישי',   segmentId: 'hoshanot_day_6' },
  { day: 7, header: 'הושענות להושענא רבא',  segmentId: 'hoshanot_hoshana_rabba' },
];

// Names of headers immediately following each one (used as section boundary).
// Order in the page: יום שני → שלישי → רביעי → חמישי → שישי → שבת → הושענא רבא → חבאן.
const HEADER_ORDER = [
  'הושענות ליום הראשון',
  'הושענות ליום השני',
  'הושענות ליום השלישי',
  'הושענות ליום הרביעי',
  'הושענות ליום החמישי',
  'הושענות ליום השישי',
  'הושענות ליום שבת',
  'הושענות להושענא רבא',
  'הושענות לפי מנהג חבאן',
];

function sliceSection(wt, header) {
  const idx = HEADER_ORDER.indexOf(header);
  if (idx < 0) throw new Error(`header ${header} not in HEADER_ORDER`);
  // Locate this header in wikitext.
  const startMatch = wt.indexOf(`==${header}==`);
  if (startMatch < 0) throw new Error(`header text not found in wikitext: ${header}`);
  // End at the next header (or end of doc).
  let end = wt.length;
  for (let j = idx + 1; j < HEADER_ORDER.length; j++) {
    const nh = wt.indexOf(`==${HEADER_ORDER[j]}==`, startMatch);
    if (nh > 0) { end = nh; break; }
  }
  // Body starts after the header line.
  const headerLineEnd = wt.indexOf('\n', startMatch);
  return wt.slice(headerLineEnd + 1, end);
}

(async () => {
  // Load wikitext (already cached if previous fetch left a file; otherwise fetch).
  let raw;
  const cachedPath = path.join(__dirname, '_tmp.json');
  if (fs.existsSync(cachedPath)) {
    raw = fs.readFileSync(cachedPath, 'utf8');
    console.log('  using cached wikitext');
  } else {
    raw = await fetchUrl(WIKI_URL);
  }
  const wikiResp = JSON.parse(raw);
  const wt = wikiResp.parse.wikitext['*'];

  const manifest = readJson(MANIFEST_PATH);
  fs.mkdirSync(NUSACH_DIR, { recursive: true });

  for (const d of DAYS) {
    const body = sliceSection(wt, d.header);
    const sections = sectionToBlocks(body);
    const filePath = path.join(NUSACH_DIR, `${d.segmentId}.json`);
    writeJson(filePath, { id: d.segmentId, sections });
    manifest.nusach.edot_mizrach[d.segmentId] = rel(filePath);
    console.log(`  ${d.segmentId}: ${sections.length} sections, ${rel(filePath)}`);
  }

  function sortKeys(o) {
    if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
    const out = {};
    for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
    return out;
  }
  fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

  if (fs.existsSync(cachedPath)) fs.unlinkSync(cachedPath);
  console.log('\nDONE.');
})().catch((e) => { console.error(e); process.exit(1); });
