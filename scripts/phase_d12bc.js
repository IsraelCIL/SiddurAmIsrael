// Batch D.12b + D.12c — Hallel/Musaf sequencing in acharei_amidah templates.
//
// Adds, in each `shacharit_acharei_amidah_<nusach>` sub-template:
//
//   1. AFTER the Hallel block:
//        kaddish_titkabal  [if: hallel_with_musaf]
//
//      For Sfard only, also:
//        shir_shel_yom     [if: hallel_with_musaf]
//        barchi_nafshi     [if: hallel_with_musaf, rosh_chodesh]
//        kaddish_yatom     [if: hallel_with_musaf]
//
//   2. On the existing closing entry `kaddish_titkabal [if: with_minyan]`
//      (the one right after Uva LeSion): add exclude_flag `musaf_content`,
//      since on Musaf-content days that closing kaddish is recited AFTER
//      Musaf, not here.
//
//   3. AFTER that existing closing entry:
//        chatzi_kaddish              [if: musaf_content]
//        sub_template_id: musaf_<n>  [if: musaf_content]
//
// Also in `shacharit_sof_hatfila_sfard` and `shacharit_sof_hatfila_edot_mizrach`:
//   • Existing `shir_shel_yom` (+ its trailing kaddish_yatom for Sfard) gets
//     exclude_flag `hallel_with_musaf`, since SSY is moved earlier on those
//     days. Ashkenaz SSY stays in place (Ashk says it after Aleinu always).
//
// Run from project root:  node scripts/phase_d12bc.js

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

const manifest = readJson(MANIFEST_PATH);

function entry(opts) {
  return {
    ...(opts.segmentId ? { segment_id: opts.segmentId } : {}),
    ...(opts.subTemplateId ? { sub_template_id: opts.subTemplateId } : {}),
    condition_flags: opts.condition_flags || [],
    exclude_flags: opts.exclude_flags || [],
    ...(opts.optional ? { optional: true } : {}),
  };
}

// Remove any existing entries for the given segment_id or sub_template_id
// whose condition_flags match. Used for idempotency so this script can be
// re-run safely.
function removeMatching(segments, predicate) {
  return segments.filter((s) => !predicate(s));
}

// ─── acharei_amidah patches ────────────────────────────────────────────────
for (const nusach of ['ashkenaz', 'sfard', 'edot_mizrach']) {
  const key = `shacharit_acharei_amidah_${nusach}`;
  const tp = path.join(PROJECT, manifest.templates[key]);
  const data = readJson(tp);
  let segs = data.segments;

  // STEP 1 — drop any prior insertions (idempotent).
  const isPostHallelInsertion = (s) =>
    s.condition_flags && s.condition_flags.includes('hallel_with_musaf');
  const isPreMusafInsertion = (s) =>
    s.condition_flags && s.condition_flags.includes('musaf_content');
  segs = removeMatching(segs, (s) => isPostHallelInsertion(s) || isPreMusafInsertion(s));

  // STEP 2 — locate Hallel block (we'll insert AFTER hallel_half so both
  // full and half Hallel are handled by the same gate, since the gating is
  // on `hallel_with_musaf` (a derived calendar flag) rather than on which
  // Hallel was said).
  const hallelHalfIdx = segs.findIndex((s) => s.segment_id === 'hallel_half');
  if (hallelHalfIdx < 0) throw new Error(`hallel_half not found in ${key}`);

  // Kaddishim (titkabal, yatom) are sub-templates; shir_shel_yom is also a
  // sub-template; barchi_nafshi is a single segment.
  const postHallelInserts = [
    entry({ subTemplateId: 'kaddish_titkabal', condition_flags: ['hallel_with_musaf'] }),
  ];
  if (nusach === 'sfard') {
    postHallelInserts.push(
      entry({ subTemplateId: 'shir_shel_yom', condition_flags: ['hallel_with_musaf'] }),
      entry({
        segmentId: 'barchi_nafshi',
        condition_flags: ['hallel_with_musaf', 'rosh_chodesh'],
      }),
      entry({ subTemplateId: 'kaddish_yatom', condition_flags: ['hallel_with_musaf'] }),
    );
  }
  segs.splice(hallelHalfIdx + 1, 0, ...postHallelInserts);

  // STEP 3 — locate the existing closing kaddish_titkabal (the one at the
  // very end, right after uva_letzion). Mark it with exclude_flag
  // `musaf_content`, then insert chatzi_kaddish + musaf sub-template right
  // after it (also gated on musaf_content).
  const closingIdx = segs.findIndex(
    (s) =>
      (s.segment_id === 'kaddish_titkabal' ||
          s.sub_template_id === 'kaddish_titkabal') &&
      s.condition_flags && s.condition_flags.includes('with_minyan') &&
      // exclude the post-Hallel kaddish we just inserted (it doesn't have
      // 'with_minyan' as its condition).
      !s.condition_flags.includes('hallel_with_musaf'),
  );
  if (closingIdx < 0) throw new Error(`closing kaddish_titkabal not found in ${key}`);
  const closing = segs[closingIdx];
  closing.exclude_flags = closing.exclude_flags || [];
  if (!closing.exclude_flags.includes('musaf_content')) {
    closing.exclude_flags.push('musaf_content');
  }

  segs.splice(closingIdx + 1, 0,
    entry({ subTemplateId: 'chatzi_kaddish', condition_flags: ['musaf_content'] }),
    entry({ subTemplateId: `musaf_${nusach}`, condition_flags: ['musaf_content'] }),
  );

  data.segments = segs;
  writeJson(tp, data);
  console.log(`  ${rel(tp)} updated (${segs.length} segments)`);
}

// ─── sof_hatfila patches ──────────────────────────────────────────────────
console.log('\n=== sof_hatfila patches ===');
for (const nusach of ['sfard', 'edot_mizrach']) {
  const key = `shacharit_sof_hatfila_${nusach}`;
  const tp = path.join(PROJECT, manifest.templates[key]);
  const data = readJson(tp);
  let patched = 0;
  for (let i = 0; i < data.segments.length; i++) {
    const s = data.segments[i];
    if (s.sub_template_id !== 'shir_shel_yom' && s.segment_id !== 'shir_shel_yom') continue;
    s.exclude_flags = s.exclude_flags || [];
    if (!s.exclude_flags.includes('hallel_with_musaf')) {
      s.exclude_flags.push('hallel_with_musaf');
      patched++;
    }
    // Also exclude the kaddish_yatom that immediately follows SSY
    // (it's the SSY-trailing kaddish — moves earlier with SSY on RC/CHM).
    const next = data.segments[i + 1];
    if (next && (next.sub_template_id === 'kaddish_yatom' || next.segment_id === 'kaddish_yatom')
        && (!next.condition_flags || next.condition_flags.length === 0)) {
      next.exclude_flags = next.exclude_flags || [];
      if (!next.exclude_flags.includes('hallel_with_musaf')) {
        next.exclude_flags.push('hallel_with_musaf');
        patched++;
      }
    }
  }
  writeJson(tp, data);
  console.log(`  ${rel(tp)}: ${patched} entries excluded on hallel_with_musaf`);
}

console.log('\nDONE.');
