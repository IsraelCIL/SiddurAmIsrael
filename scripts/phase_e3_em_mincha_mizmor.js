// Phase E.3 — EM Mincha mizmor after Kaddish Titkabal.
//
// In Edot HaMizrach Mincha, after Kaddish Titkabal a Tehillim mizmor is
// recited, defaulting to Lamenatzeach BiNginot (Ps 67). On Erev Shabbat,
// Chol HaMoed Pesach, and Chol HaMoed Sukkot, the default is replaced
// by a different mizmor (per Siddur EM, Weekday Mincha, Vidui §16–§19).
//
// IMPORTANT FIX: mincha.json currently uses the generic `lamenatzeach`
// segment for EM after Kaddish Titkabal — but that file holds Tehillim 20
// (Ya'ancha), which is the pre-UvaLeTzion mizmor in Shacharit, NOT the
// post-Mincha EM mizmor. This phase swaps the wrong reference for four
// new EM-specific segments, each gated by a calendar flag.
//
// Sources (Sefaria, Siddur Edot HaMizrach):
//   • Default (Tehillim 67):       Weekday_Mincha, Vidui §17
//   • Erev Shabbat (Tehillim 93):  Weekday_Mincha, Vidui §19
//   • CHM Pesach (Tehillim 107):   Prayers_for_Three_Festivals,
//                                  Song_for_Passover §2
//   • CHM Sukkot (Tehillim 42):    Prayers_for_Three_Festivals,
//                                  Song_for_Sukkot §2
//
// Gating logic:
//   • mincha_em_hashem_malach: condition `erev_shabbat` (EM only)
//   • mincha_em_pesach:        condition `chol_hamoed_pesach`,
//                              exclude   `erev_shabbat`
//   • mincha_em_sukkot:        condition `chol_hamoed_sukkot`,
//                              exclude   `erev_shabbat`
//   • mincha_em_lamenatzeach (default):
//                              exclude   `erev_shabbat`,
//                                        `chol_hamoed_pesach`,
//                                        `chol_hamoed_sukkot`,
//                                        `skip_lamenatzeach`
//   All four restricted via allowed_nusach to ['edot_mizrach'].
//
// Run from project root:  node scripts/phase_e3_em_mincha_mizmor.js

const fs = require('fs');
const path = require('path');

const PROJECT = path.resolve(__dirname, '..');
const ASSETS = path.join(PROJECT, 'assets', 'prayers');
const COMMON_DIR = path.join(ASSETS, 'shared_global', 'common');
const MANIFEST_PATH = path.join(ASSETS, '_manifest.json');
const MINCHA_TPL = path.join(ASSETS, 'templates', 'mincha.json');

function rel(p) { return path.relative(PROJECT, p).replace(/\\/g, '/'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function writeJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

// Strip Hebrew trope marks (U+0591–U+05AF), normalize sof-pasuk → colon,
// collapse any whitespace runs. Keep niqqud (U+05B0+) intact.
function cleanHebrew(raw) {
  return raw
    .replace(/[֑-֯]/g, '')
    .replace(/׃/g, ':')
    .replace(/\s+/g, ' ')
    .trim();
}

// Split a long line into a JSON-friendly array at sof-pasuk boundaries
// (the ":" inside the text), targeting ≤80 chars per line. Pasuk-end colons
// are kept on the line they terminate.
function splitToArray(text) {
  const cleaned = cleanHebrew(text);
  const parts = cleaned.split(/(?<=:)\s+/).filter(Boolean);
  return parts;
}

// ── Source texts (already fetched from Sefaria) ─────────────────────────────

// Tehillim 67 — Default (Sefaria: Vidui §17). Strip the "(תהלים סז)" preamble.
const TEHILLIM_67 = '(תהלים סז) לַמְנַצֵּ֥חַ בִּנְגִינֹ֗ת מִזְמ֥וֹר שִֽׁיר׃ אֱֽלֹהִ֗ים יְחׇנֵּ֥נוּ וִיבָרְכֵ֑נוּ יָ֤אֵֽר פָּנָ֖יו אִתָּ֣נוּ סֶֽלָה׃ לָדַ֣עַת בָּאָ֣רֶץ דַּרְכֶּ֑ךָ בְּכׇל־גּ֝וֹיִ֗ם יְשׁוּעָתֶֽךָ׃ יוֹד֖וּךָ עַמִּ֥ים ׀ אֱלֹהִ֑ים י֝וֹד֗וּךָ עַמִּ֥ים כֻּלָּֽם׃ יִ֥שְׂמְח֥וּ וִירַנְּנ֗וּ לְאֻ֫מִּ֥ים כִּֽי־תִשְׁפֹּ֣ט עַמִּ֣ים מִישֹׁ֑ר וּלְאֻמִּ֓ים ׀ בָּאָ֖רֶץ תַּנְחֵ֣ם סֶֽלָה׃ יוֹד֖וּךָ עַמִּ֥ים ׀ אֱלֹהִ֑ים י֝וֹד֗וּךָ עַמִּ֥ים כֻּלָּֽם׃ אֶ֭רֶץ נָתְנָ֣ה יְבוּלָ֑הּ יְ֝בָרְכֵ֗נוּ אֱלֹהִ֥ים אֱלֹהֵֽינוּ׃ יְבָרְכֵ֥נוּ אֱלֹהִ֑ים וְיִֽירְא֥וּ א֝וֹת֗וֹ כׇּל־אַפְסֵי־אָֽרֶץ׃';

// Tehillim 93 — Erev Shabbat (Sefaria: Vidui §19).
const TEHILLIM_93 = '(תהלים צג) יְהֹוָ֣ה מָלָךְ֮ גֵּא֢וּת לָ֫בֵ֥שׁ לָבֵ֣שׁ יְ֭הֹוָה עֹ֣ז הִתְאַזָּ֑ר אַף־תִּכּ֥וֹן תֵּ֝בֵ֗ל בַּל־תִּמּֽוֹט׃ נָכ֣וֹן כִּסְאֲךָ֣ מֵאָ֑ז מֵעוֹלָ֣ם אָֽתָּה׃ נָשְׂא֤וּ נְהָר֨וֹת ׀ יְֽהֹוָ֗ה נָשְׂא֣וּ נְהָר֣וֹת קוֹלָ֑ם יִשְׂא֖וּ נְהָר֣וֹת דׇּכְיָֽם׃ מִקֹּל֨וֹת ׀ מַ֤יִם רַבִּ֗ים אַדִּירִ֣ים מִשְׁבְּרֵי־יָ֑ם אַדִּ֖יר בַּמָּר֣וֹם יְהֹוָֽה׃ עֵֽדֹתֶ֨יךָ ׀ נֶאֶמְנ֬וּ מְאֹ֗ד לְבֵיתְךָ֥ נַאֲוָה־קֹ֑דֶשׁ יְ֝הֹוָ֗ה לְאֹ֣רֶךְ יָמִֽים׃';

// Tehillim 107 — CHM Pesach (Sefaria: Song_for_Passover §2).
const TEHILLIM_107 = 'הֹד֣וּ (תהלים קז) לַיהֹוָ֣ה כִּי־ט֑וֹב כִּ֖י לְעוֹלָ֣ם חַסְדּֽוֹ׃ יֹ֭אמְרוּ גְּאוּלֵ֣י יְהֹוָ֑ה אֲשֶׁ֥ר גְּ֝אָלָ֗ם מִיַּד־צָֽר׃ וּֽמֵאֲרָצ֗וֹת קִ֫בְּצָ֥ם מִמִּזְרָ֥ח וּמִֽמַּעֲרָ֑ב מִצָּפ֥וֹן וּמִיָּֽם׃ תָּע֣וּ בַ֭מִּדְבָּר בִּישִׁימ֣וֹן דָּ֑רֶךְ עִ֥יר מ֝וֹשָׁ֗ב לֹ֣א מָצָֽאוּ׃ רְעֵבִ֥ים גַּם־צְמֵאִ֑ים נַ֝פְשָׁ֗ם בָּהֶ֥ם תִּתְעַטָּֽף׃ וַיִּצְעֲק֣וּ אֶל־יְ֭הֹוָה בַּצַּ֣ר לָהֶ֑ם מִ֝מְּצ֥וּקוֹתֵיהֶ֗ם יַצִּילֵֽם׃ וַֽ֭יַּדְרִיכֵם בְּדֶ֣רֶךְ יְשָׁרָ֑ה לָ֝לֶ֗כֶת אֶל־עִ֥יר מוֹשָֽׁב׃ יוֹד֣וּ לַיהֹוָ֣ה חַסְדּ֑וֹ וְ֝נִפְלְאוֹתָ֗יו לִבְנֵ֥י אָדָֽם׃ כִּֽי־הִ֭שְׂבִּיעַ נֶ֣פֶשׁ שֹׁקֵקָ֑ה וְנֶ֥פֶשׁ רְ֝עֵבָ֗ה מִלֵּא־טֽוֹב׃ יֹ֭שְׁבֵי חֹ֣שֶׁךְ וְצַלְמָ֑וֶת אֲסִירֵ֖י עֳנִ֣י וּבַרְזֶֽל׃ כִּֽי־הִמְר֥וּ אִמְרֵי־אֵ֑ל וַעֲצַ֖ת עֶלְי֣וֹן נָאָֽצוּ׃ וַיַּכְנַ֣ע בֶּעָמָ֣ל לִבָּ֑ם כָּ֝שְׁל֗וּ וְאֵ֣ין עֹזֵֽר׃ וַיִּזְעֲק֣וּ אֶל־יְ֭הֹוָה בַּצַּ֣ר לָהֶ֑ם מִ֝מְּצֻ֥קוֹתֵיהֶ֗ם יוֹשִׁיעֵֽם׃ י֭וֹצִיאֵם מֵחֹ֣שֶׁךְ וְצַלְמָ֑וֶת וּמוֹסְר֖וֹתֵיהֶ֣ם יְנַתֵּֽק׃ יוֹד֣וּ לַיהֹוָ֣ה חַסְדּ֑וֹ וְ֝נִפְלְאוֹתָ֗יו לִבְנֵ֥י אָדָֽם׃ כִּֽי־שִׁ֭בַּר דַּלְת֣וֹת נְחֹ֑שֶׁת וּבְרִיחֵ֖י בַרְזֶ֣ל גִּדֵּֽעַ׃ אֱ֭וִלִים מִדֶּ֣רֶךְ פִּשְׁעָ֑ם וּֽ֝מֵעֲוֺ֥נֹתֵיהֶ֗ם יִתְעַנּֽוּ׃ כׇּל־אֹ֭כֶל תְּתַעֵ֣ב נַפְשָׁ֑ם וַ֝יַּגִּ֗יעוּ עַד־שַׁ֥עֲרֵי מָֽוֶת׃ וַיִּזְעֲק֣וּ אֶל־יְ֭הֹוָה בַּצַּ֣ר לָהֶ֑ם מִ֝מְּצֻ֥קוֹתֵיהֶ֗ם יוֹשִׁיעֵֽם׃ יִשְׁלַ֣ח דְּ֭בָרוֹ וְיִרְפָּאֵ֑ם וִ֝ימַלֵּ֗ט מִשְּׁחִֽיתוֹתָֽם׃ יוֹד֣וּ לַיהֹוָ֣ה חַסְדּ֑וֹ וְ֝נִפְלְאוֹתָ֗יו לִבְנֵ֥י אָדָֽם׃ וְ֭יִזְבְּחוּ זִבְחֵ֣י תוֹדָ֑ה וִיסַפְּר֖וּ מַעֲשָׂ֣יו בְּרִנָּֽה׃ יוֹרְדֵ֣י הַ֭יָּם בׇּאֳנִיּ֑וֹת עֹשֵׂ֥י מְ֝לָאכָ֗ה בְּמַ֣יִם רַבִּֽים׃ הֵ֣מָּה רָ֭אוּ מַעֲשֵׂ֣י יְהֹוָ֑ה וְ֝נִפְלְאוֹתָ֗יו בִּמְצוּלָֽה׃ וַיֹּ֗אמֶר וַֽ֭יַּעֲמֵד ר֣וּחַ סְעָרָ֑ה וַתְּרוֹמֵ֥ם גַּלָּֽיו׃ יַעֲל֣וּ שָׁ֭מַיִם יֵרְד֣וּ תְהוֹמ֑וֹת נַ֝פְשָׁ֗ם בְּרָעָ֥ה תִתְמוֹגָֽג׃ יָח֣וֹגּוּ וְ֭יָנוּעוּ כַּשִּׁכּ֑וֹר וְכׇל־חׇ֝כְמָתָ֗ם תִּתְבַּלָּֽע׃ וַיִּצְעֲק֣וּ אֶל־יְ֭הֹוָה בַּצַּ֣ר לָהֶ֑ם וּֽ֝מִמְּצ֥וּקֹתֵיהֶ֗ם יוֹצִיאֵֽם׃ יָקֵ֣ם סְ֭עָרָה לִדְמָמָ֑ה וַ֝יֶּחֱשׁ֗וּ גַּלֵּיהֶֽם׃ וַיִּשְׂמְח֥וּ כִֽי־יִשְׁתֹּ֑קוּ וַ֝יַּנְחֵ֗ם אֶל־מְח֥וֹז חֶפְצָֽם׃ יוֹד֣וּ לַיהֹוָ֣ה חַסְדּ֑וֹ וְ֝נִפְלְאוֹתָ֗יו לִבְנֵ֥י אָדָֽם׃ וִֽ֭ירוֹמְמוּהוּ בִּקְהַל־עָ֑ם וּבְמוֹשַׁ֖ב זְקֵנִ֣ים יְהַלְלֽוּהוּ׃ יָשֵׂ֣ם נְהָר֣וֹת לְמִדְבָּ֑ר וּמֹצָ֥אֵי מַ֗֝יִם לְצִמָּאֽוֹן׃ אֶ֣רֶץ פְּ֭רִי לִמְלֵחָ֑ה מֵ֝רָעַ֗ת י֣וֹשְׁבֵי בָֽהּ׃ יָשֵׂ֣ם מִ֭דְבָּר לַאֲגַם־מַ֑יִם וְאֶ֥רֶץ צִ֝יָּ֗ה לְמֹצָ֥אֵי מָֽיִם׃ וַיּ֣וֹשֶׁב שָׁ֣ם רְעֵבִ֑ים וַ֝יְכוֹנְנ֗וּ עִ֣יר מוֹשָֽׁב׃ וַיִּזְרְע֣וּ שָׂ֭דוֹת וַיִּטְּע֣וּ כְרָמִ֑ים וַ֝יַּעֲשׂ֗וּ פְּרִ֣י תְבוּאָֽה׃ וַיְבָרְכֵ֣ם וַיִּרְבּ֣וּ מְאֹ֑ד וּ֝בְהֶמְתָּ֗ם לֹ֣א יַמְעִֽיט׃ וַיִּמְעֲט֥וּ וַיָּשֹׁ֑חוּ מֵעֹ֖צֶר רָעָ֣ה וְיָגֽוֹן׃ שֹׁפֵ֣ךְ בּ֭וּז עַל־נְדִיבִ֑ים וַ֝יַּתְעֵ֗ם בְּתֹ֣הוּ לֹא־דָֽרֶךְ׃ וַיְשַׂגֵּ֣ב אֶבְי֣וֹן מֵע֑וֹנִי וַיָּ֥שֶׂם כַּ֝צֹּ֗אן מִשְׁפָּחֽוֹת׃ יִרְא֣וּ יְשָׁרִ֣ים וְיִשְׂמָ֑חוּ וְכׇל־עַ֝וְלָ֗ה קָ֣פְצָה פִּֽיהָ׃ מִי־חָכָ֥ם וְיִשְׁמׇר־אֵ֑לֶּה וְ֝יִתְבּוֹנְנ֗וּ חַֽסְדֵ֥י יְהֹוָֽה׃';

// Tehillim 42 — CHM Sukkot (Sefaria: Song_for_Sukkot §2).
const TEHILLIM_42 = 'לַמְנַצֵּ֗חַ מַשְׂכִּ֥יל לִבְנֵי־קֹֽרַח׃ כְּאַיָּ֗ל תַּעֲרֹ֥ג עַל־אֲפִֽיקֵי־מָ֑יִם כֵּ֤ן נַפְשִׁ֨י תַעֲרֹ֖ג אֵלֶ֣יךָ אֱלֹהִֽים׃ צָמְאָ֬ה נַפְשִׁ֨י ׀ לֵאלֹהִים֮ לְאֵ֢ל חָ֥י מָתַ֥י אָב֑וֹא וְ֝אֵרָאֶ֗ה פְּנֵ֣י אֱלֹהִֽים׃ הָיְתָה־לִּ֬י דִמְעָתִ֣י לֶ֭חֶם יוֹמָ֣ם וָלָ֑יְלָה בֶּאֱמֹ֥ר אֵלַ֥י כׇּל־הַ֝יּ֗וֹם אַיֵּ֥ה אֱלֹהֶֽיךָ׃ אֵ֤לֶּה אֶזְכְּרָ֨ה ׀ וְאֶשְׁפְּכָ֬ה עָלַ֨י ׀ נַפְשִׁ֗י כִּ֤י אֶעֱבֹ֨ר ׀ בַּסָּךְ֮ אֶדַּדֵּ֗ם עַד־בֵּ֥ית אֱלֹ֫הִ֥ים בְּקוֹל־רִנָּ֥ה וְתוֹדָ֗ה הָמ֥וֹן חוֹגֵֽג׃ מַה־תִּשְׁתּ֬וֹחֲחִ֨י ׀ נַפְשִׁי֮ וַתֶּהֱמִ֢י עָ֫לָ֥י הוֹחִ֣לִי לֵ֭אלֹהִים כִּי־ע֥וֹד אוֹדֶ֗נּוּ יְשׁוּע֥וֹת פָּנָֽיו׃ אֱלֹהַ֗י עָלַי֮ נַפְשִׁ֢י תִשְׁתּ֫וֹחָ֥ח עַל־כֵּ֗ן אֶ֭זְכׇּרְךָ מֵאֶ֣רֶץ יַרְדֵּ֑ן וְ֝חֶרְמוֹנִ֗ים מֵהַ֥ר מִצְעָֽר׃ תְּהוֹם־אֶל־תְּה֣וֹם ק֭וֹרֵא לְק֣וֹל צִנּוֹרֶ֑יךָ כׇּֽל־מִשְׁבָּרֶ֥יךָ וְ֝גַלֶּ֗יךָ עָלַ֥י עָבָֽרוּ׃ יוֹמָ֤ם ׀ יְצַוֶּ֬ה יְהֹוָ֨ה ׀ חַסְדּ֗וֹ וּ֭בַלַּיְלָה שִׁירֹ֣ה עִמִּ֑י תְּ֝פִלָּ֗ה לְאֵ֣ל חַיָּֽי׃ אוֹמְרָ֤ה ׀ לְאֵ֥ל סַלְעִי֮ לָמָ֢ה שְׁכַ֫חְתָּ֥נִי לָֽמָּה־קֹדֵ֥ר אֵלֵ֗ךְ בְּלַ֣חַץ אוֹיֵֽב׃ בְּרֶ֤צַח ׀ בְּֽעַצְמוֹתַ֗י חֵרְפ֥וּנִי צוֹרְרָ֑י בְּאׇמְרָ֥ם אֵלַ֥י כׇּל־הַ֝יּ֗וֹם אַיֵּ֥ה אֱלֹהֶֽיךָ׃ מַה־תִּשְׁתּ֬וֹחֲחִ֨י ׀ נַפְשִׁי֮ וּֽמַה־תֶּהֱמִ֢י עָ֫לָ֥י הוֹחִ֣ילִי לֵ֭אלֹהִים כִּי־ע֣וֹד אוֹדֶ֑נּוּ יְשׁוּעֹ֥ת פָּ֝נַ֗י וֵאלֹהָֽי׃';

// Strip the parenthetical "(תהלים XX)" book reference that Sefaria embeds
// in the middle of the first verse — not part of the recited text.
function stripBookRef(s) {
  return s.replace(/\s*\(תהלים\s+[א-ת"׳״]+\)\s*/g, ' ');
}

// ── Write segment files ──────────────────────────────────────────────────────

const segments = [
  { id: 'mincha_em_lamenatzeach',  raw: TEHILLIM_67 },
  { id: 'mincha_em_hashem_malach', raw: TEHILLIM_93 },
  { id: 'mincha_em_pesach',        raw: TEHILLIM_107 },
  { id: 'mincha_em_sukkot',        raw: TEHILLIM_42 },
];

const manifest = readJson(MANIFEST_PATH);

for (const seg of segments) {
  const text = splitToArray(stripBookRef(seg.raw));
  const filePath = path.join(COMMON_DIR, `${seg.id}.json`);
  writeJson(filePath, {
    id: seg.id,
    sections: [
      { text, condition_flags: [], exclude_flags: [] },
    ],
  });
  manifest.common[seg.id] = rel(filePath);
  console.log(`  wrote ${rel(filePath)} (${text.length} lines)`);
}

// ── Patch mincha.json: replace the existing EM `lamenatzeach` entry ──────────

const mincha = readJson(MINCHA_TPL);
const idx = mincha.segments.findIndex(
  (s) =>
    s.segment_id === 'lamenatzeach' &&
    Array.isArray(s.allowed_nusach) &&
    s.allowed_nusach.includes('edot_mizrach'),
);
if (idx < 0) {
  console.warn('  NOTE: existing EM lamenatzeach segment not found — skipping replacement');
} else {
  const newEntries = [
    {
      segment_id: 'mincha_em_lamenatzeach',
      condition_flags: [],
      exclude_flags: [
        'erev_shabbat',
        'chol_hamoed_pesach',
        'chol_hamoed_sukkot',
        'skip_lamenatzeach',
      ],
      optional: false,
      allowed_nusach: ['edot_mizrach'],
    },
    {
      segment_id: 'mincha_em_hashem_malach',
      condition_flags: ['erev_shabbat'],
      exclude_flags: ['skip_lamenatzeach'],
      optional: false,
      allowed_nusach: ['edot_mizrach'],
    },
    {
      segment_id: 'mincha_em_pesach',
      condition_flags: ['chol_hamoed_pesach'],
      exclude_flags: ['erev_shabbat', 'skip_lamenatzeach'],
      optional: false,
      allowed_nusach: ['edot_mizrach'],
    },
    {
      segment_id: 'mincha_em_sukkot',
      condition_flags: ['chol_hamoed_sukkot'],
      exclude_flags: ['erev_shabbat', 'skip_lamenatzeach'],
      optional: false,
      allowed_nusach: ['edot_mizrach'],
    },
  ];
  mincha.segments.splice(idx, 1, ...newEntries);
  writeJson(MINCHA_TPL, mincha);
  console.log(`  patched ${rel(MINCHA_TPL)}: replaced lamenatzeach (Tehillim 20 — wrong) with 4 EM Mincha mizmor variants`);
}

// ── Persist manifest ────────────────────────────────────────────────────────

function sortKeys(o) {
  if (o === null || typeof o !== 'object' || Array.isArray(o)) return o;
  const out = {};
  for (const k of Object.keys(o).sort()) out[k] = sortKeys(o[k]);
  return out;
}
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(sortKeys(manifest), null, 2) + '\n', 'utf8');

console.log('\nDONE.');
