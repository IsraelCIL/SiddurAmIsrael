// Korbanot restructure (per user's request):
//
// Goal: every Korbanot block belongs to a specific nusach. The "common"
// directory should hold only universal pesukim. Build per-nusach korbanot
// files covering the full liturgical order:
//
//   leolam_yehe_adam        — Sovereignty of Heaven block (per-nusach)
//   parshat_hatamid         — Numbers 28 verses with surrounding yehi ratzon
//   yehi_ratzon_kahakravnu  — only Sfard (after Tamid: "כאילו הקרבנו תמיד...")
//   ata_hu_ketoret_intro    — "אתה הוא ה' אלקינו שהקטירו אבותינו..."
//   parshat_haketoret       — Exodus verses (30:34-36, 30:7-8)
//   pitum_haketoret         — "תנו רבנן פטום הקטורת..."
//   tanya_rabbi_natan       — Tanya R. Natan baraita
//   tanya_bar_kappara       — Ash/Sfard "תניא בר קפרא"; EM "תני בר קפרא"
//   pesukim_hatzvaot        — "ה' צבאות עמנו..." 3x (Ash/Sfard add "אתה סתר")
//   abayei_hava_mesader     — Abayei's order of korbanot
//   ana_bekoach             — "אנא בכח" (42-letter Name)
//   ribbon_haolamim         — "ריבון העולמים אתה ציויתנו..." (per-nusach)
//   eizehu_mekoman          — Mishna Zevachim 5 (Eizehu Mekoman)
//   r_yishmael              — Baraita of R. Yishmael (13 hermeneutic rules)
//   closing_yehi_ratzon     — Ash/Sfard: "יהי רצון... שיבנה ביהמ"ק";
//                             EM: yehuda_ben_teima + different yehi ratzon
//
// All consolidated into a single per-nusach `korbanot.json` segment with
// ordered sections. with_minyan-only items (like "המקדש שמו ברבים") use
// section-level condition_flags.

const fs = require('fs');
const path = require('path');

const PROJECT = 'c:/Users/refae/Projects/smart-siddur';

function stripHtml(t) { return (t || '').replace(/<[^>]+>/g, ''); }
function stripTrope(t) { return t.replace(/[֑-֯]/g, ''); }
function normSpaces(t) { return t.replace(/\s+/g, ' ').trim(); }
function clean(t) { return normSpaces(stripTrope(stripHtml(t))); }
function flatten(x) { return Array.isArray(x) ? x.flatMap(flatten) : [x]; }
function loadSefaria(key) {
  const d = JSON.parse(fs.readFileSync(path.join(PROJECT, `_${key}.json`), 'utf8'));
  return flatten(d.versions[0].text).map(clean);
}
function matchable(s) {
  return s.replace(/[־]/g, ' ').replace(/[֑-ֿׁ-ׇ]/g, '').replace(/[,.׃:;()״"'׳״\-]/g, ' ').replace(/\s+/g, ' ').trim();
}
function splitToArray(text, maxLen = 75) {
  const t = normSpaces(text);
  if (t.length <= maxLen) return [t];
  const parts = [];
  let buf = '';
  for (let i = 0; i < t.length; i++) {
    buf += t[i];
    const ch = t[i], next = t[i+1];
    if ((ch===':'||ch==='.'||ch===','||ch==='׃') && (next===' '||next===undefined)) {
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
function sec(text, condFlags = [], excludeFlags = []) {
  const arr = Array.isArray(text) ? text.flatMap(t => splitToArray(t)) : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: condFlags,
    exclude_flags: excludeFlags,
  };
}
function writeSeg(nusach, segId, sections) {
  const obj = { id: segId, sections };
  const rel = `assets/prayers/nusach/${nusach}/${segId}.json`;
  const full = path.join(PROJECT, rel);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, JSON.stringify(obj, null, 2) + '\n', 'utf8');
  console.log(`  ${rel} — sections=${sections.length}`);
}

// ─── load all sources ────────────────────────────────────────────────────────
const s1 = JSON.parse(fs.readFileSync(path.join(PROJECT, 's1.json'), 'utf8'));
const s1Flat = flatten(s1.he || s1.versions?.[0]?.text || []).map(clean);  // Le'olam (Ashkenaz)

const SEF_K     = loadSefaria('sef_korbanot');         // 41 entries
const SEF_MP    = loadSefaria('sef_morningprayer');    // 14 entries (Sefard intro + Sovereignty)
const EM_MP     = loadSefaria('em_morningprayer');     // 19 entries (EM full)
const EM_K      = loadSefaria('em_ketoret');           // 35 entries (EM ketoret + zevachim + r yishmael)

const ASH_TAMID = loadSefaria('ash_korbanot_Korban_HaTamid');
const ASH_KET   = loadSefaria('ash_korbanot_Ketoret');
const ASH_OTS   = loadSefaria('ash_korbanot_Order_of_the_Temple_Service');
const ASH_LOS   = loadSefaria('ash_korbanot_Laws_of_Sacrifices');
const ASH_RYY   = loadSefaria('ash_korbanot_Baraita_of_Rabbi_Yishmael');

// Pre-filter: drop entries that are pure rubrics (< 25 chars, no closing
// punctuation), but keep useful short pieces (handled case-by-case below).
function isRubric(t) {
  const m = matchable(t);
  return m.length < 50 && !/׃$|:$|\./.test(t.trim());
}

// ─── (1) leolam_yehe_adam per nusach ────────────────────────────────────────
// Ashkenaz: s1.he has 10 entries; skip P5 rubric "ויאמר בלחש:" and combine P8
// (with_minyan: Mekadesh Shemo BaRabim) into its own section.
// Sfard: sef_morningprayer entries 4..13 cover the same block in Sfard's order.
// EM: em_morningprayer entries 10..16 cover the EM block.

console.log('\n=== leolam_yehe_adam ===');

// Helper: build sections for a single nusach's "leolam" block from a slice of
// entries. The Mekadesh-Shemo line (ends "מקדש את שמו ברבים") needs
// with_minyan. The Shema (just "שמע ישראל...") and BaruchShem are part of
// the block.
function buildLeolamSections(entries) {
  const sections = [];
  // We collect entries into 3 logical groups by scanning:
  //   intro group   — everything before the with_minyan bracha
  //   minyan group  — the single line ending in "מקדש את שמו ברבים"
  //   closing group — everything after that line
  let mode = 'intro';
  let buf = [];
  const minyanLines = [];
  const closingLines = [];
  for (const e of entries) {
    const m = matchable(e);
    if (m.length < 15) continue;          // skip pure rubric "ויאמר בלחש"
    if (mode === 'intro') {
      // Match any of the "Mekadesh ... barabim" closing — text varies:
      //   Ashkenaz: "מקדש את שמך ברבים"
      //   Sfard:    "מקדש את שמך ברבים" (similar)
      //   EM:       "מקדש שמו ברבים"
      if (m.includes('מקדש') && m.includes('ברבים')) {
        minyanLines.push(e);
        mode = 'closing';
      } else {
        buf.push(e);
      }
    } else if (mode === 'closing') {
      closingLines.push(e);
    }
  }
  if (buf.length) sections.push(sec(buf));
  if (minyanLines.length) sections.push(sec(minyanLines, ['with_minyan']));
  if (closingLines.length) sections.push(sec(closingLines));
  return sections;
}

// Ashkenaz: s1.he is the Sovereignty of Heaven section. Entries 0..9 inclusive
// minus index 5 (rubric "ויאמר בלחש").
const ashLeolamRaw = s1Flat.filter((_, i) => i !== 5);
writeSeg('ashkenaz', 'leolam_yehe_adam', buildLeolamSections(ashLeolamRaw));

// Sfard: sef_morningprayer entries 4..13 are the Sfard Sovereignty block.
const sefLeolamRaw = SEF_MP.slice(4, 14);
writeSeg('sfard', 'leolam_yehe_adam', buildLeolamSections(sefLeolamRaw));

// EM: em_morningprayer entries 10..16 cover Le'olam through Atah Hu.
const emLeolamRaw = EM_MP.slice(10, 17);
writeSeg('edot_mizrach', 'leolam_yehe_adam', buildLeolamSections(emLeolamRaw));

// ─── (2) korbanot.json per nusach — all blocks after leolam ─────────────────
// Each nusach gets its own komatposed korbanot.json.

console.log('\n=== korbanot (full per nusach) ===');

function findIdx(entries, ...kws) {
  for (let i = 0; i < entries.length; i++) {
    const m = matchable(entries[i]);
    if (kws.every(k => m.includes(k))) return i;
  }
  return -1;
}

// Ashkenaz korbanot blocks (drawn from _ash_korbanot_* files):
//   ash_tamid[0]: rubric (Shabbat/YT note) — drop
//   ash_tamid[1]: yehi_ratzon kahakravnu (440 chars) — Ashkenaz also has it
//   ash_tamid[2]: parshat_hatamid (785 chars)
//   ash_tamid[3]: Vshachat (139 chars) — continuation of parshat hatamid
//   ash_tamid[4]: short yehi ratzon (219 chars)
//   ash_ket[0]: ata_hu_ketoret_intro
//   ash_ket[1]: parshat_haketoret
//   ash_ket[2]: vehiktir (Exod 30:7-8)
//   ash_ket[3]: pitum_haketoret (Tanu Rabbanan)
//   ash_ket[4]: Rabban Shimon b. Gamliel (continuation)
//   ash_ket[5]: tanya_rabbi_natan
//   ash_ket[6]: tanya_bar_kappara
//   ash_ket[7]: pesukim_hatzvaot ("ה' צבאות... 3x")
//   ash_ket[8]: "אתה סתר לי" + "וערבה"
//   ash_ots[0]: abayei
//   ash_ots[1]: ana_bekoach
//   ash_ots[2]: ribbon_haolamim
//   ash_ots[3]+[4]: Rosh Chodesh addition (skip — separate flow)
//   ash_los[0]: rubric — drop
//   ash_los[1..8]: eizehu_mekoman (8 mishnayot)
//   ash_ryy[0..12]: r_yishmael (13 middot)
//   ash_ryy[13]: closing yehi_ratzon "יבנה ביהמ"ק וכשנים קדמוניות"

function buildAshkenazKorbanot() {
  const sections = [];

  // (a) parshat_hatamid block: yehi ratzon kahakravnu + parashat ha-tamid + yehi ratzon kreviy (small one)
  // user marks the parshat_hatamid as starting with "את קרבני לחמי"
  sections.push(sec(ASH_TAMID[1], [], ['shabbat', 'yom_tov']));  // yehi ratzon kahakravnu
  sections.push(sec([ASH_TAMID[2], ASH_TAMID[3]]));               // parshat ha-tamid
  sections.push(sec(ASH_TAMID[4]));                               // small yehi ratzon

  // (b) Ketoret
  sections.push(sec(ASH_KET[0]));                                 // ata hu ketoret intro
  sections.push(sec([ASH_KET[1], ASH_KET[2]]));                   // parshat ha-ketoret (Exod 30:34-36 + 30:7-8)
  sections.push(sec(ASH_KET[3]));                                 // pitum ha-ketoret (TanuRabbanan)
  sections.push(sec(ASH_KET[4]));                                 // Rabban Shimon b. Gamliel
  sections.push(sec(ASH_KET[5]));                                 // tanya rabbi natan
  sections.push(sec(ASH_KET[6]));                                 // tanya bar kappara
  sections.push(sec([ASH_KET[7], ASH_KET[8]]));                   // pesukim hatzvaot + ata seter + ve'arva

  // (c) Order of the Temple Service
  sections.push(sec(ASH_OTS[0]));                                 // abayei
  sections.push(sec(ASH_OTS[1]));                                 // ana bekoach
  sections.push(sec(ASH_OTS[2]));                                 // ribbon haolamim

  // (d) Eizehu Mekoman — laws of sacrifices, 8 mishnayot
  sections.push(sec(ASH_LOS.slice(1, 9).join(' ')));              // skip [0] which is rubric

  // (e) Baraita of Rabbi Yishmael
  sections.push(sec(ASH_RYY.slice(0, 13).join(' ')));             // 13 hermeneutic rules
  sections.push(sec(ASH_RYY[13]));                                // closing yehi ratzon

  return sections;
}

writeSeg('ashkenaz', 'korbanot', buildAshkenazKorbanot());

// ─── Sefard korbanot ────────────────────────────────────────────────────────
// SEF_K has 41 entries with the full Sefard order. We extract by index.

function buildSfardKorbanot() {
  const sections = [];

  // [0..5] are pre-tamid intros (chachamim quote, terumat hadeshen, etc.) — skip
  // [6] is yehi ratzon kahakravnu (440 chars)
  // [7] parshat ha-tamid (785 chars) + [8] vshachat (139 chars)
  // [9] yehi ratzon after tamid (225 chars)
  // [10] ata hu ketoret intro
  // [11..12] parshat ha-ketoret
  // [13] pitum ha-ketoret (Tanu Rabbanan)
  // [14] Rabban Shimon b. Gamliel
  // [15] tanya R. Natan
  // [16] tanya bar kappara
  // [17] rubric "אומר ג' פעמים" — drop
  // [18] pesukim hatzvaot (3x verses)
  // [19] ata seter + ve'arva
  // [20] abayei
  // [21] rubric (drop)
  // [22] ana bekoach
  // [23] ribbon haolamim
  // [24] rubric "ראש חודש" — drop
  // [25] Rosh chodesh addition (excluded normally)
  // [26..27] rubric/comment — drop
  // [28..30] eizehu mekoman (mishnayot 1-3)
  // [31] yehi ratzon kraktanu (chatat)
  // [32] mishna 4
  // [33] yehi ratzon (olah)
  // [34] mishna 5
  // [35] yehi ratzon (asham)
  // [36] mishna 6
  // [37] yehi ratzon (toda)
  // [38] mishna 7
  // [39] yehi ratzon (shelamim)
  // [40] mishna 8

  sections.push(sec(SEF_K[6], [], ['shabbat', 'yom_tov']));        // yehi ratzon kahakravnu
  sections.push(sec([SEF_K[7], SEF_K[8]]));                       // parshat ha-tamid
  sections.push(sec(SEF_K[9]));                                    // short yehi ratzon
  sections.push(sec(SEF_K[10]));                                   // ata hu ketoret intro
  sections.push(sec([SEF_K[11], SEF_K[12]]));                      // parshat ha-ketoret
  sections.push(sec(SEF_K[13]));                                   // pitum ha-ketoret
  sections.push(sec(SEF_K[14]));                                   // Rabban Shimon b. Gamliel
  sections.push(sec(SEF_K[15]));                                   // tanya rabbi natan
  sections.push(sec(SEF_K[16]));                                   // tanya bar kappara
  sections.push(sec([SEF_K[18], SEF_K[19]]));                      // pesukim hatzvaot + ata seter
  sections.push(sec(SEF_K[20]));                                   // abayei
  sections.push(sec(SEF_K[22]));                                   // ana bekoach
  sections.push(sec(SEF_K[23]));                                   // ribbon haolamim
  // Eizehu Mekoman — Sfard mixes mishnayot with yehi ratzon between each
  sections.push(sec([SEF_K[28], SEF_K[29], SEF_K[30], SEF_K[31], SEF_K[32], SEF_K[33], SEF_K[34], SEF_K[35], SEF_K[36], SEF_K[37], SEF_K[38], SEF_K[39], SEF_K[40]]));

  // R. Yishmael + closing yehi ratzon (use Ashkenaz baraita — same text)
  sections.push(sec(ASH_RYY.slice(0, 13).join(' ')));
  sections.push(sec(ASH_RYY[13]));

  return sections;
}

writeSeg('sfard', 'korbanot', buildSfardKorbanot());

// ─── EM korbanot ────────────────────────────────────────────────────────────
// EM Sefaria splits across em_morningprayer (Parshat HaTamid etc.) and
// em_ketoret (full Pitum HaKetoret + Eizehu Mekoman + R. Yishmael + Yehuda b. Teima).

function buildEmKorbanot() {
  const sections = [];

  // em_morningprayer[18]: parshat ha-tamid (780 chars) - "וידבר ה' אל משה...את קרבני"
  sections.push(sec(EM_MP[18]));                                   // parshat ha-tamid

  // em_ketoret[1]: ata hu ketoret intro
  sections.push(sec(EM_K[1]));
  // em_ketoret[2]: parshat ha-ketoret (Vayomer)
  sections.push(sec(EM_K[2]));
  // em_ketoret[3]+[4]: pitum ha-ketoret (Tanu Rabbanan + ingredient list)
  sections.push(sec([EM_K[3], EM_K[4]]));
  // em_ketoret[5]: Rabban Shimon
  sections.push(sec(EM_K[5]));
  // em_ketoret[6]: tanya R. Natan
  sections.push(sec(EM_K[6]));
  // em_ketoret[7]: TANI bar kappara (EM uses "תני" not "תניא")
  sections.push(sec(EM_K[7]));
  // em_ketoret[8]: abayei
  sections.push(sec(EM_K[8]));
  // em_ketoret[9..15]: ana bekoach (EM has it as 7-line piyut)
  sections.push(sec([EM_K[9], EM_K[10], EM_K[11], EM_K[12], EM_K[13], EM_K[14], EM_K[15], EM_K[17]]));
  // em_ketoret[18]: ribbon haolamim
  sections.push(sec(EM_K[18]));
  // em_ketoret[19]: lachen yehi ratzon (EM-specific) — keep as separate small section
  sections.push(sec(EM_K[19]));
  // em_ketoret[20..27]: eizehu mekoman (8 mishnayot)
  sections.push(sec([EM_K[20], EM_K[21], EM_K[22], EM_K[23], EM_K[24], EM_K[25], EM_K[26], EM_K[27]]));
  // em_ketoret[28]: r yishmael
  sections.push(sec(EM_K[28]));
  // em_ketoret[29]: yehuda ben teima (EM-only)
  sections.push(sec(EM_K[29]));
  // em_ketoret[30]: closing yehi ratzon (EM-specific)
  sections.push(sec(EM_K[30]));

  return sections;
}

writeSeg('edot_mizrach', 'korbanot', buildEmKorbanot());

// ─── delete common/korbanot.json (now fully per-nusach) ─────────────────────
const oldKorbanot = path.join(PROJECT, 'assets/prayers/common/korbanot.json');
if (fs.existsSync(oldKorbanot)) {
  fs.unlinkSync(oldKorbanot);
  console.log('\n  deleted common/korbanot.json');
}

console.log('\nDONE.');
