// Batch D.12f + D.12g — Musaf middle bracha for Chol HaMoed Pesach + Sukkot.
//
// Per nusach, two new segments are written:
//   • `amidah_musaf_intermediate_chm_pesach` — full bracha for CHM Pesach.
//   • `amidah_musaf_intermediate_chm_sukkot` — full bracha for CHM Sukkot,
//     with `{{daily_korban}}` placeholder for the day-of-Sukkot Torah quote
//     (filled in at assembly time from `sukkot_korbanot_mapping.json` based
//     on UserContext.sukkotDay + isInIsrael).
//
// Source quirks handled here:
//   • Each Sefaria source for "Yom Tov Musaf Amidah" contains ALL chag
//     variants inline with Hebrew labels ("לפסח", "לשבת:" etc). We extract
//     the Pesach-only / Sukkot-only sequence and strip Shabbat parts.
//   • Sfard's source uses "וכו'" to abbreviate the closing block (Elohenu
//     V'elohei Avoteinu, V'hashienu, Baruch Mekadesh). Per user instruction,
//     we substitute Ashkenaz's full closing text (textually identical for
//     this section across all standard Orthodox nusachim).
//   • EM has explicit closing entries but no explicit chatima — we append
//     the standard chatima.
//
// Also writes:
//   • `assets/prayers/maariv/sefirat_haomer/..` is unchanged. The new
//     mapping file lives at:
//        assets/prayers/musaf/sukkot/_sukkot_korbanot_mapping.json
//     with 7 days (sukkotDay 1..7), each having `pasuk_israel` and
//     `pasuk_chu_l` (the chu"l version doubles up due to s'feika d'yoma).
//
// Run from project root:  node scripts/phase_d12fg.js

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
    .replace(/&[a-z]+;/gi, ' ')
    .replace(/<[^>]+>/g, '')
    .replace(/[֑-֯]/g, '')
    .replace(/[׀]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
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

const manifest = readJson(MANIFEST_PATH);

// ─── Load sources ──────────────────────────────────────────────────────────
function load(file) {
  const d = readJson(path.join(PROJECT, file));
  return flat(d.versions[0].text).map(clean);
}
const ASH = load('_ash_musaf_chm.json');
const SEF = load('_sef_musaf_chm.json');
const EM = load('_em_musaf_chm.json');

// ─── Section helper ────────────────────────────────────────────────────────
function sec(text) {
  const arr = Array.isArray(text) ? text : splitToArray(text);
  return {
    text: arr.length === 1 ? arr[0] : arr,
    condition_flags: [],
    exclude_flags: [],
  };
}

// ─── Per-nusach extractors ────────────────────────────────────────────────
// Each extractor returns the array of section TEXTS for the chag, in order.
// Shabbat-only parts are stripped (D.12 scope = weekday CHM only).

// Chag phrases — used in "Vatiten Lanu...et yom" and in "V'et Musaf yom".
const PHRASE_PESACH_FULL  = 'חַג הַמַּצּוֹת הַזֶּה זְמַן חֵרוּתֵנוּ';
const PHRASE_SUKKOT_FULL  = 'חַג הַסֻּכּוֹת הַזֶּה זְמַן שִׂמְחָתֵנוּ';
const PHRASE_PESACH_SHORT = 'חַג הַמַּצּוֹת הַזֶּה';
const PHRASE_SUKKOT_SHORT = 'חַג הַסֻּכּוֹת הַזֶּה';
const MIKRA_KODESH        = 'בְּאַהֲבָה מִקְרָא קֹדֶשׁ זֵכֶר לִיצִיאַת מִצְרָיִם:';
const NAASEH              = 'נַעֲשֶׂה וְנַקְרִיב לְפָנֶיךָ בְּאַהֲבָה כְּמִצְוַת רְצוֹנֶךָ. כְּמוֹ שֶׁכָּתַבְתָּ עָלֵינוּ בְּתוֹרָתֶךָ. עַל יְדֵי מֹשֶׁה עַבְדֶּךָ. מִפִּי כְבוֹדֶךָ כָּאָמוּר:';

// Korban for CHM Pesach (fixed all 7 days). Numbers 28:19-25 excerpt.
// Identical text across nusachim (Torah quote). Use the Ashkenaz form
// (entry [38] of _ash_musaf_chm.json) which is the most widely printed.
const KORBAN_CHM_PESACH = ASH[38];

// Uminchatam V'niskeihem — standard formula. Take Sfard [43] (has no
// chag-conditional inline parts) and clean any Shavuot-specific addition.
const UMINCHATAM = SEF[43];

// Closing block — use Ashkenaz [66] + [67] + [68] with Shabbat parts
// stripped. These three entries form: "Elohenu V'elohei Avoteinu... rachem
// aleinu..." → "V'hashienu..." → "Baruch Ata Hashem Mekadesh Yisrael..."
function stripShabbat(s) {
  // Remove "לשבת ..." labelled inserts. The labels appear inline marking
  // Shabbat-only continuations. Strategy: remove any run that starts with
  // 'לשבת' or 'בשבת' and ends at the next major punctuation (':' or '.')
  // — these are the inline Shabbat additions in the printed source.
  return s
    .replace(/לשבת[^:.]*[:.]/g, '')
    .replace(/בשבת[^:.]*[:.]/g, '')
    .replace(/\(לשבת[^)]*\)/g, '')
    .replace(/\(בשבת[^)]*\)/g, '')
    .replace(/הַשַּׁבָּת וְ\s*/g, '')   // chatima: "הַשַּׁבָּת וְ ישראל..." → "ישראל..."
    .replace(/\s+/g, ' ')
    .trim();
}
const CLOSING_ELOHEINU = stripShabbat(ASH[66]);
const CLOSING_VHASHIENU = stripShabbat(ASH[67]);
const CHATIMA_CHM = 'בָּרוּךְ אַתָּה יְהֹוָה. מְקַדֵּשׁ יִשְׂרָאֵל וְהַזְּמַנִּים:';

// ── Ashkenaz ──────────────────────────────────────────────────────────────
// Sequence: [0] atah vechartanu + (vatiten lanu opener cleaned) + chag full
// phrase + mikra kodesh + [9] umipnei chataeinu + [10] yhi ratzon + [11]
// avinu malkenu + (v'et musaf opener cleaned) + chag short phrase +
// "nikriv lefanecha" + naaseh + korban + uminchatam + closing block.

function ashSequence(chag) {
  // Construct Vatiten Lanu cleanly: take ASH[1] which is
  //   "וַתִּתֶּן לָנוּ ה' אֱלהֵינוּ בְּאַהֲבָה לשבת: שַׁבָּתות לִמְנוּחָה וּ מועֲדִים לְשמְחָה חַגִּים וּזְמַנִּים לְששון אֶת יום:"
  // and strip the "לשבת: ... וּ" Shabbat insert.
  const vatiten = stripShabbat(ASH[1]);
  const vetMusaf = stripShabbat(ASH[12]); // "וְאֶת מוּסַף ... וְ יום:"
  const phraseFull = chag === 'pesach' ? PHRASE_PESACH_FULL : PHRASE_SUKKOT_FULL;
  const phraseShort = chag === 'pesach' ? PHRASE_PESACH_SHORT : PHRASE_SUKKOT_SHORT;
  const korban = chag === 'pesach' ? KORBAN_CHM_PESACH : '{{daily_korban}}';
  return [
    ASH[0],                  // Atah Vechartanu
    `${vatiten} ${phraseFull}`,
    MIKRA_KODESH,
    ASH[9],                  // Umipnei Chataeinu
    ASH[10],                 // Yhi Ratzon (Ashk-specific)
    ASH[11],                 // Avinu Malkenu (Ashk-specific)
    `${vetMusaf} ${phraseShort}`,
    NAASEH,
    korban,
    UMINCHATAM,
    CLOSING_ELOHEINU,
    CLOSING_VHASHIENU,
    CHATIMA_CHM,
  ];
}

// ── Sfard ─────────────────────────────────────────────────────────────────
// Sequence: [14] atah vechartanu + (vatiten cleaned) + chag full + (mikra
// kodesh cleaned) + [21] umipnei chataeinu + (v'et musaf cleaned) + chag
// short + naaseh + korban + uminchatam + (Ashk closing, since Sfard source
// abbreviates with "וכו'").
function sefSequence(chag) {
  const vatiten = stripShabbat(SEF[15]);   // "וַתִּתֶּן... (בשבת ...) מוֹעֲדִים..."
  const vetMusaf = stripShabbat(SEF[22]);  // "וְאֶת מוּסַף (בשבת ...) יוֹם"
  const mikraKodesh = stripShabbat(SEF[20]); // "(בשבת בְּאַהֲבָה) מִקְרָא קֹדֶשׁ..."
  const phraseFull = chag === 'pesach' ? PHRASE_PESACH_FULL : PHRASE_SUKKOT_FULL;
  const phraseShort = chag === 'pesach' ? PHRASE_PESACH_SHORT : PHRASE_SUKKOT_SHORT;
  const korban = chag === 'pesach' ? KORBAN_CHM_PESACH : '{{daily_korban}}';
  // The Sfard mikra_kodesh after stripping starts with just "מִקְרָא קֹדֶשׁ..."
  // — we prefix "בְּאַהֲבָה" manually to match the standard form.
  const mikraKodeshClean = mikraKodesh.startsWith('בְּאַהֲבָה')
    ? mikraKodesh
    : `בְּאַהֲבָה ${mikraKodesh}`;
  return [
    SEF[14],                 // Atah Vechartanu
    `${vatiten} ${phraseFull}`,
    mikraKodeshClean,
    SEF[21],                 // Umipnei Chataeinu
    `${vetMusaf} ${phraseShort}`,
    NAASEH,
    korban,
    UMINCHATAM,
    CLOSING_ELOHEINU,        // borrowed from Ashk (source has "וכו'")
    CLOSING_VHASHIENU,
    CHATIMA_CHM,
  ];
}

// ── EM ────────────────────────────────────────────────────────────────────
// EM has its own Yhi Ratzon ("שֶׁתַּעֲלֵנוּ בְשִׂמְחָה...") at [20]. The closing
// in EM's source is explicit ([27]+[28]) but lacks the chatima — append it.
function emSequence(chag) {
  const vatiten = stripShabbat(EM[12]);
  const vetMusaf = stripShabbat(EM[21]);
  const phraseFull = chag === 'pesach' ? PHRASE_PESACH_FULL : PHRASE_SUKKOT_FULL;
  const phraseShort = chag === 'pesach' ? PHRASE_PESACH_SHORT : PHRASE_SUKKOT_SHORT;
  const korban = chag === 'pesach' ? KORBAN_CHM_PESACH : '{{daily_korban}}';
  return [
    EM[11],                  // Atah Vechartanu
    `${vatiten} ${phraseFull}`,
    EM[18],                  // Mikra Kodesh
    EM[19],                  // Umipnei Chataeinu
    EM[20],                  // EM Yhi Ratzon (shta'aleinu b'simcha)
    `${vetMusaf} ${phraseShort}`,
    NAASEH,
    korban,
    UMINCHATAM,
    EM[27],                  // Elohenu V'elohei Avoteinu (full in EM source)
    EM[28],                  // V'hashienu (full in EM source)
    CHATIMA_CHM,
  ];
}

// ─── Build segment files ──────────────────────────────────────────────────
const builders = {
  ashkenaz: ashSequence,
  sfard: sefSequence,
  edot_mizrach: emSequence,
};

for (const chag of ['pesach', 'sukkot']) {
  console.log(`\n=== CHM ${chag} ===`);
  for (const nusach of Object.keys(builders)) {
    const parts = builders[nusach](chag).filter((p) => p && p.length > 0);
    const sections = parts.map((p) => sec(p));
    const id = `amidah_musaf_intermediate_chm_${chag}`;
    const dst = path.join(
      ASSETS, 'musaf', 'amidah', 'nusach', nusach, `${id}.json`,
    );
    writeJson(dst, { id, sections });
    manifest.nusach[nusach][id] = rel(dst);
    const total = parts.join(' ').length;
    console.log(`  ${nusach}: ${rel(dst)} (${sections.length} sections, ${total} chars)`);
  }
}

// ─── Sukkot daily korban mapping ───────────────────────────────────────────
// 7 days. Israel + chu"l (chu"l doubles up due to s'feika d'yoma on CHM
// sukkot days 3-7 — say BOTH "ובים השני" + the day's actual pasuk on day 3,
// "וביום השלישי" + the day's actual on day 4, etc.).
//
// Israel:
//   sukkotDay 1 = full Yom Tov (entry [32-33] of _ash_musaf_chm.json)
//                 — used by D.12g only if user later expands to Yom Tov scope
//   sukkotDay 2 = CHM day 1 = "וביום השני..." (ASH[42])
//   sukkotDay 3 = CHM day 2 = "וביום השלישי..." (ASH[45])
//   sukkotDay 4 = CHM day 3 = "וביום הרביעי..." (ASH[48])
//   sukkotDay 5 = CHM day 4 = "וביום החמישי..." (ASH[51])
//   sukkotDay 6 = CHM day 5 = "וביום הששי..."  (ASH[54])
//   sukkotDay 7 = Hoshana Raba = "וביום השביעי..." (ASH[57])
const SUKKOT_KORBANOT_ASH_IDX = {
  1: -1,  // Yom Tov full korban — out of D.12 scope
  2: 42, 3: 45, 4: 48, 5: 51, 6: 54, 7: 57,
};
console.log('\n=== Sukkot daily korbanot mapping ===');
const dayEntries = [];
for (let d = 1; d <= 7; d++) {
  const ashIdx = SUKKOT_KORBANOT_ASH_IDX[d];
  if (ashIdx < 0) {
    dayEntries.push({
      day: d,
      pasuk_israel: '',
      pasuk_chu_l: '',
      note: 'sukkot day 1 = full Yom Tov — content out of current D.12 scope',
    });
    continue;
  }
  const pasuk_israel = ASH[ashIdx];
  // chu"l doubles up on CHM (starting from CHM day 1 in chu"l, which is
  // sukkotDay 3 since first 2 days are Yom Tov in chu"l). For sukkotDay 3..7
  // in chu"l, the convention is to recite the PREVIOUS day's pasuk + the
  // current day's pasuk (s'feika d'yoma).
  let pasuk_chu_l;
  if (d === 2) {
    // CHM day 1 chu"l (= Yom Tov day 2 in chu"l) → still Yom Tov musaf
    pasuk_chu_l = '';
  } else {
    const prevIdx = SUKKOT_KORBANOT_ASH_IDX[d - 1];
    pasuk_chu_l = prevIdx > 0 ? `${ASH[prevIdx]} ${pasuk_israel}` : pasuk_israel;
  }
  dayEntries.push({ day: d, pasuk_israel, pasuk_chu_l });
  console.log(`  day ${d}: israel=${pasuk_israel.substring(0, 60)}...`);
}
const mappingPath = path.join(ASSETS, 'musaf', 'sukkot', '_sukkot_korbanot_mapping.json');
writeJson(mappingPath, { days: dayEntries });
console.log(`\n  ${rel(mappingPath)}: ${dayEntries.length} days`);

// ─── Write manifest ────────────────────────────────────────────────────────
function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');
console.log('\nDONE.');
