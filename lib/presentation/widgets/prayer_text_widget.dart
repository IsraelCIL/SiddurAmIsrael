import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assembled_segment.dart';
import '../../domain/entities/omer_day.dart';
import '../providers/prayer_providers.dart';
import 'rich_prayer_text.dart';

/// Returns the display label for a segment ID.
/// Empty string means "no label" (not a section header).
/// Unknown IDs fall back to the raw ID so they remain visible in dev builds.
String segmentLabel(String id) => _segmentLabels[id] ?? id;

const _segmentLabels = <String, String>{
  // ── Lifnei HaTfila — morning prep ─────────────────────────────────────────
  'modeh_ani': 'מודה אני',
  'al_netilat_yadayim': 'על נטילת ידים',
  'asher_yatzar': 'אשר יצר',
  'elokai_neshama': 'אלקי נשמה',
  'birchot_hatorah_la_asok': 'ברכות התורה',
  'vehaarev': '',
  'natan_torah': '',
  'pesukim': '',
  'birchot_hatorah_pesukim': '',
  'elu_devarim': '',
  'yehi_ratzon_tzitzit': '',
  'birkat_tzitzit_gadol': 'ברכת ציצית',
  'mah_yakar_tallit': '',
  'birkat_tzitzit_katan': 'ברכת ציצית',
  'seder_tefillin': 'סדר הנחת תפילין',
  'parshat_kadesh': 'פרשת קדש לי',
  'parshat_vehaya_ki_yeviacha': 'פרשת והיה כי יביאך',
  'ma_tovu': 'מה טובו',
  'adon_olam': 'אדון עולם',
  'yigdal': 'יגדל',
  'vatitpalel_channa': '',
  'lshem_yichud': 'לשם יחוד',
  'lshem_yichud_maariv': 'לשם יחוד',
  'lshem_yichud_mincha': 'לשם יחוד',
  'mah_yedidot': 'מה יְּדִידוֹת',
  // ── Birkot HaShachar ──────────────────────────────────────────────────────
  'birkot_hashachar_header': 'ברכות השחר',
  'hanoten_lasechvi': '',
  'shelo_asani_goy': '',
  'shelo_asani_eved': '',
  'shelo_asani_ishah': '',
  'sheasani_kirtzono': '',
  'pokeach_ivrim': '',
  'malbish_arumim': '',
  'matir_asurim': '',
  'zokef_kefufim': '',
  'rokea_haaretz': '',
  'sheasah_li_kol_tzorki': '',
  'hamechin_mitzedei_gever': '',
  'ozer_yisrael': '',
  'oter_yisrael': '',
  'hanoten_layaef_koach': '',
  'hamaavir_sheinah': '',
  'yehi_ratzon_shelo_yavo': '',
  // ── Akeidah + intro to Korbanot ───────────────────────────────────────────
  'akeidah': 'פרשת העקידה',
  'akeidah_yehi_ratzon': '',
  'leolam_yehe_adam': 'לעולם יהא אדם',
  // ── Korbanot (whole segment + future sub-segments) ────────────────────────
  'korbanot': 'קרבנות',
  'korbanot_tamid': 'פרשת התמיד',
  'korbanot_ketoret_header': 'פרשת הקטורת',
  'korbanot_ketoret': '',
  'korbanot_pitum_header': 'פטום הקטורת',
  'korbanot_pitum': '',
  'korbanot_eizehu_header': 'פרק איזהו מקומן',
  'korbanot_eizehu': '',
  'korbanot_conclusion': 'ברייתא דרבי ישמעאל',
  // ── Pesukei DeZimra ───────────────────────────────────────────────────────
  'hashem_melech': 'ה׳ מלך',
  'psalm_030': 'מזמור שיר חנוכת הבית',
  'baruch_sheamar': 'ברוך שאמר',
  'hodu': 'פסוקי דזמרה',
  'mizmor_letodah': 'מזמור לתודה',
  'yehi_kevod': 'יהי כבוד',
  'ashrei': 'אשרי',
  'psalm_067': 'תהלים סז',
  'psalm_091': 'תהלים צא',
  'psalm_121': 'תהלים קכא',
  'psalm_124': 'תהלים קכד',
  'psalm_134': 'תהלים קלד',
  'psalm_146': 'תהלים קמו',
  'psalm_147': 'תהלים קמז',
  'psalm_148': 'תהלים קמח',
  'psalm_149': 'תהלים קמט',
  'psalm_150': 'תהלים קנ',
  'vayevarech_david': 'ויברך דוד',
  'az_yashir': 'שירת הים',
  'yishtabach': 'ישתבח',
  // ── Birkot Kriat Shema ────────────────────────────────────────────────────
  'yotzer_or': 'יוצר אור',
  'ahavah_rabbah': 'אהבה רבה',
  'emet_veyatziv': 'אמת ויציב',
  // ── Other morning segments ────────────────────────────────────────────────
  'beit_yaakov': 'בית יעקב',
  'petihat_eliyahu': 'פתיחת אליהו',
  'korbanot_mincha': 'קרבנות',
  // ── Shacharit structure ────────────────────────────────────────────────────
  'barchu': 'ברכו',
  'shema': 'קריאת שמע',
  'ahavat_olam': 'אהבת עולם',
  'lamenatzeach': '',
  'ladavid': '',
  // ── Amidah ─────────────────────────────────────────────────────────────────
  'amidah': 'תפילת עמידה',
  'amidah_intro': 'תפילת עמידה',
  'amidah_avot': 'אבות',
  'amidah_gevurot': 'גבורות',
  'amidah_kedushah_hashem': 'קדושת השם',
  'amidah_daat': 'דעת',
  'amidah_teshuva': 'תשובה',
  'amidah_selicha': 'סליחה',
  'amidah_geula': 'גאולה',
  'amidah_refuah': 'רפואה',
  'amidah_shanim': 'ברכת השנים',
  'amidah_galuyot': 'קבוץ גלויות',
  'amidah_mishpat': 'משפט',
  'amidah_minim': 'ברכת המינים',
  'amidah_tzaddikim': 'על הצדיקים',
  'amidah_yerushalayim': 'בנין ירושלים',
  'amidah_david': 'משיח בן דוד',
  'amidah_shema_koleinu': 'שומע תפילה',
  'amidah_retzeh': 'עבודה',
  'amidah_modim': 'הודאה',
  'amidah_shalom': 'שים שלום',
  'amidah_conclusion': 'אלקי נצור',
  // ── Chazarat HaShatz ───────────────────────────────────────────────────────
  'chazarat_hashatz_header': 'חזרת הש״ץ',
  'kedushah': 'קדושה',
  'kedushah_ledorvador': 'לדור ודור',
  'modim_derabanan': 'מודים דרבנן',
  'birkat_kohanim': '',
  'birkat_kohanim_bracha': 'ברכת כהנים',
  'elokeinu_velohei_avoteinu': 'אלהינו ואלהי אבותינו',
  'anenu_shliach_tzibur': 'עננו',
  // ── Post-amidah ────────────────────────────────────────────────────────────
  'uva_letzion': 'ובא לציון',
  'avinu_malkeinu': 'אבינו מלכנו',
  'aleinu': 'עלינו לשבח',
  'aleinu_al_ken': '',
  // ── Kaddish ────────────────────────────────────────────────────────────────
  'chatzi_kaddish_header': 'חצי קדיש',
  'kaddish_derabanan_header': 'קדיש דרבנן',
  'kaddish_yatom_header': 'קדיש יתום',
  'kaddish_titkabal_header': 'קדיש תתקבל',
  'kaddish_body': '',
  'kaddish_closing': '',
  'kaddish_derabanan_paragraph': '',
  'kaddish_titkabal_paragraph': '',
  // ── Sof hatfila ────────────────────────────────────────────────────────────
  'barchi_nafshi': 'ברכי נפשי',
  'ein_keloheinu': 'אין כאלהינו',
  'atah_hu_shehiktiruv': '',
  'pitum_haketoreh': 'פטום הקטורת',
  'tana_devei_eliyahu': '',
  'amar_rabbi_elazar': '',
  'shir_shel_yom_sunday': 'שיר של יום',
  'shir_shel_yom_monday': 'שיר של יום',
  'shir_shel_yom_tuesday': 'שיר של יום',
  'shir_shel_yom_wednesday': 'שיר של יום',
  'shir_shel_yom_thursday': 'שיר של יום',
  'shir_shel_yom_friday': 'שיר של יום',
  'shir_shel_yom_shabbat': 'שיר של יום',
  'shir_shel_yom_gra': 'שיר של יום',
  // ── Maariv ─────────────────────────────────────────────────────────────────
  'maariv_aravim': 'מעריב ערבים',
  'maariv_ahavat_olam': 'אהבת עולם',
  'hashkivenu': 'השכיבנו',
  'emet_veemunh': 'אמת ואמונה',
  'yiru_einenu': 'יראו עינינו',
  'vehu_rachum_arvit': 'והוא רחום',
  'hashem_tzvaot_maariv': 'ה׳ צבאות עמנו',
  // ── Sefirat HaOmer ─────────────────────────────────────────────────────────
  'sefirat_haomer_header': 'ספירת העומר',
  'sefirat_haomer_lshem_yichud': 'לשם יחוד',
  'sefirat_haomer_lshem_yichud_long': 'לשם יחוד (נוסח ארוך)',
  'sefirat_haomer_birshut': '',
  'sefirat_haomer_bracha': '',
  'sefirat_haomer_day_count': '',
  'sefirat_haomer_harachaman': '',
  'sefirat_haomer_lamenatzeach': '',
  'sefirat_haomer_ana_bekoach': '',
  'sefirat_haomer_ribono_shel_olam': '',
  // ── EM mincha additions ────────────────────────────────────────────────────
  'mincha_em_lamenatzeach': 'למנצח',
  'mincha_em_hashem_malach': 'ה׳ מלך (ערב שבת)',
  'mincha_em_pesach': 'שיר — חול המועד פסח',
  'mincha_em_sukkot': 'שיר — חול המועד סוכות',
  'hallel_rc_psukim': 'ואברהם זקן',
  'psalm_042': 'למנצח משכיל לבני קרח',
  'psalm_107': 'הודו לה\'',
  // ── Kriat HaTorah ──────────────────────────────────────────────────────────
  'el_erech_apayim': 'אל ארך אפיים',
  'kriat_hatorah_shacharit': 'ברכות התורה',
  'kriat_hatorah_mincha': '',
  'kriat_hatorah_hotzaah': 'הוצאת ספר תורה',
  'kriat_hatorah_hachnasah': 'הכנסת ספר תורה',
  'hagbahah': 'הגבהה',
  'kriat_hatorah_reading_text': '',
  'kriah_rc': '',
  'kriah_chm_pesach_day_2': '',
  'kriah_chm_pesach_day_3': '',
  'kriah_chm_pesach_day_4': '',
  'kriah_chm_pesach_day_5': '',
  'kriah_chm_pesach_day_6': '',
  'kriah_chm_sukkot_day_2': '',
  'kriah_chm_sukkot_day_3': '',
  'kriah_chm_sukkot_day_4': '',
  'kriah_chm_sukkot_day_5': '',
  'kriah_chm_sukkot_day_6': '',
  'kriah_chm_sukkot_day_7': '',
  'kriah_chanukah_day_1': '',
  'kriah_chanukah_day_2': '',
  'kriah_chanukah_day_3': '',
  'kriah_chanukah_day_4': '',
  'kriah_chanukah_day_5': '',
  'kriah_chanukah_day_6': '',
  'kriah_chanukah_day_7': '',
  'kriah_chanukah_day_8': '',
  'kriah_purim': '',
  'kriah_rc_tevet': '',
  'kriah_fast_day': '',
  'haftarah_taanit': '',
  'haftarah_bracha_lifnei': 'ברכת ההפטרה',
  'haftarah_bracha_acharei_1': 'ברכות ההפטרה',
  'haftarah_bracha_acharei_2': '',
  'haftarah_bracha_acharei_3': '',
  'yehi_ratzon_mon_thu': '',
  // ── Musaf ──────────────────────────────────────────────────────────────────
  'musaf_header': 'מוסף',
  'amidah_musaf_intermediate_rc': 'ראש חודש',
  'amidah_musaf_intermediate_chm_pesach': 'חול המועד פסח',
  'amidah_musaf_intermediate_chm_sukkot': 'חול המועד סוכות',
  // ── Tachanun ───────────────────────────────────────────────────────────────
  'tachanun': 'תחנון',
  'tachanun_nfilat_apayim': 'נפילת אפים',
  'shomer_yisrael': 'שומר ישראל',
  'vidui_yud_gimel_midot': 'וידוי וי״ג מידות',
  // ── Hoshanot ───────────────────────────────────────────────────────────────
  'hoshanot_ashk_link': 'הושענות — לחץ להצגת הסבר',
  'hoshanot_day_2': 'הושענות',
  'hoshanot_day_3': 'הושענות',
  'hoshanot_day_4': 'הושענות',
  'hoshanot_day_5': 'הושענות',
  'hoshanot_day_6': 'הושענות',
  'hoshanot_hoshana_rabba': 'הושענות — הושענא רבא',
};

// Optional segments that should start EXPANDED (open accordion by default).
const _initiallyExpanded = <String>{'birkat_kohanim_bracha'};

// Segments that are part of a tight block (e.g. kaddish components): no
// trailing spacer so consecutive segments flow without visual gaps.
const _noTrailingSpace = <String>{
  'chatzi_kaddish_header',
  'kaddish_derabanan_header',
  'kaddish_yatom_header',
  'kaddish_titkabal_header',
  'kaddish_body',
  'kaddish_closing',
  'kaddish_derabanan_paragraph',
  'kaddish_titkabal_paragraph',
};

class PrayerTextWidget extends ConsumerWidget {
  const PrayerTextWidget({super.key, required this.segment});

  final AssembledSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = ref.watch(fontSizeFactorProvider);
    final showLabels = ref.watch(showSegmentLabelsProvider);
    final label = segmentLabel(segment.id);
    final bodyStyle = TextStyle(
      fontSize: 22 * factor,
      height: 1.9,
      color: Colors.black87,
    );

    if (segment.optional) {
      return _OptionalSegmentTile(
        label: label,
        factor: factor,
        bodyStyle: bodyStyle,
        segment: segment,
        initiallyExpanded: _initiallyExpanded.contains(segment.id),
      );
    }

    final tight = _noTrailingSpace.contains(segment.id);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, tight ? 0 : 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLabels && label.isNotEmpty) ...[
            Text(
              label,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14 * factor,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8B1A1A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (segment.resolvedText.isNotEmpty)
            RichPrayerText(text: segment.resolvedText, style: bodyStyle),
          if (segment.id == 'sefirat_haomer_day_count') _OmerSummary(factor: factor),
          SizedBox(height: tight ? 2 : 16),
        ],
      ),
    );
  }
}

/// Renders an [AssembledSegment] whose `optional` flag is true as a
/// collapsed accordion. The user sees a stylized header (label + chevron
/// + hint) and taps to expand. Use for community-specific or alternate
/// minhag content (e.g. Gr"a Shir Shel Yom variants, alternate L'shem
/// Yichud forms) that shouldn't be in the main reading flow by default.
class _OptionalSegmentTile extends StatefulWidget {
  const _OptionalSegmentTile({
    required this.label,
    required this.factor,
    required this.bodyStyle,
    required this.segment,
    this.initiallyExpanded = false,
  });

  final String label;
  final double factor;
  final TextStyle bodyStyle;
  final AssembledSegment segment;
  final bool initiallyExpanded;

  @override
  State<_OptionalSegmentTile> createState() => _OptionalSegmentTileState();
}

class _OptionalSegmentTileState extends State<_OptionalSegmentTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 14 * widget.factor,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF8B1A1A),
      letterSpacing: 0.5,
    );
    final hintStyle = TextStyle(
      fontSize: 12 * widget.factor,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF8B1A1A).withValues(alpha: 0.6),
      letterSpacing: 0.3,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 4, bottom: 12),
          initiallyExpanded: widget.initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20 * widget.factor,
                  color: const Color(0xFF8B1A1A),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: widget.label, style: headerStyle),
                      if (!_expanded) ...[
                        TextSpan(text: '  ', style: hintStyle),
                        TextSpan(text: '[לחץ להצגה]', style: hintStyle),
                      ],
                    ]),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
          children: [
            RichPrayerText(
              text: widget.segment.resolvedText,
              style: widget.bodyStyle,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE0D5C5)),
          ],
        ),
      ),
    );
  }
}

class _OmerSummary extends ConsumerWidget {
  const _OmerSummary({required this.factor});

  final double factor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentOmerDayProvider);
    return async.when(
      data: (day) => day == null ? const SizedBox.shrink() : _summary(day),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _summary(OmerDay day) {
    final labelStyle = TextStyle(
      fontSize: 13 * factor,
      color: const Color(0xFF6B5848),
    );
    final valueStyle = TextStyle(
      fontSize: 15 * factor,
      color: const Color(0xFF3A2E22),
      fontWeight: FontWeight.w600,
    );
    Widget pair(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label, textDirection: TextDirection.rtl, style: labelStyle),
            const SizedBox(height: 2),
            Text(value, textDirection: TextDirection.rtl, style: valueStyle),
          ],
        );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5EC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0D5C5)),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              pair('ספירה', day.sefira),
              pair('אנא בכח', day.anaWord),
              pair('למנצח', day.lamenatzeachWord),
              pair('ישמחו', day.yismechuLetter),
            ],
          ),
        ),
      ),
    );
  }
}
