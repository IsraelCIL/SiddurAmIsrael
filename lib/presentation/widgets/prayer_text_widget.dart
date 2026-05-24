import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assembled_segment.dart';
import '../../domain/entities/omer_day.dart';
import '../providers/prayer_providers.dart';
import 'rich_prayer_text.dart';

const _segmentLabels = <String, String>{
  'ashrei': 'אשרי',
  'petihat_eliyahu': 'פתיחת אליהו',
  'kriat_hatorah_mincha': 'קריאת התורה במנחה',
  'amidah': 'עמידה',
  'amidah_intro': 'פתיחת העמידה',
  'amidah_avot': 'ברכת אבות',
  'amidah_gevurot': 'ברכת גבורות',
  'amidah_kedushah_hashem': 'קדושת השם',
  'amidah_daat': 'ברכת הדעת',
  'amidah_teshuva': 'ברכת התשובה',
  'amidah_selicha': 'ברכת הסליחה',
  'amidah_geula': 'ברכת הגאולה',
  'amidah_refuah': 'ברכת הרפואה',
  'amidah_shanim': 'ברכת השנים',
  'amidah_galuyot': 'קיבוץ גלויות',
  'amidah_mishpat': 'ברכת המשפט',
  'amidah_minim': 'ברכת המינים',
  'amidah_tzaddikim': 'ברכת הצדיקים',
  'amidah_yerushalayim': 'בניין ירושלים',
  'amidah_david': 'מלכות בית דוד',
  'amidah_shema_koleinu': 'שמע קולנו',
  'amidah_retzeh': 'ברכת רצה',
  'amidah_modim': 'ברכת מודים',
  'amidah_shalom': 'ברכת שלום',
  'amidah_conclusion': 'סיום העמידה',
  'tachanun': 'תחנון',
  'aleinu': 'עלינו לשבח',
  'kaddish_yatom': 'קדיש יתום',
  'sefirat_haomer_lshem_yichud': 'לשם יחוד',
  'sefirat_haomer_lshem_yichud_long': 'לשם יחוד (נוסח ארוך)',
  'sefirat_haomer_birshut': 'ברשות מורי ורבותי',
  'sefirat_haomer_bracha': 'ברכת ספירת העומר',
  'sefirat_haomer_day_count': 'ספירת היום',
  'sefirat_haomer_harachaman': 'הרחמן',
  'sefirat_haomer_lamenatzeach': 'למנצח בנגינות',
  'sefirat_haomer_ana_bekoach': 'אנא בכח',
  'sefirat_haomer_ribono_shel_olam': 'ריבונו של עולם',
};

class PrayerTextWidget extends ConsumerWidget {
  const PrayerTextWidget({super.key, required this.segment});

  final AssembledSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = ref.watch(fontSizeFactorProvider);
    final label = _segmentLabels[segment.id] ?? segment.id;
    final bodyStyle = TextStyle(
      fontSize: 22 * factor,
      height: 1.9,
      color: Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          RichPrayerText(text: segment.resolvedText, style: bodyStyle),
          // Omer day-count gets a small summary line showing today's kabbalistic
          // sefira plus the highlighted Ana / Lamenatzeach / Yismechu cues —
          // visually reinforces the bold markings in the following segments.
          if (segment.id == 'sefirat_haomer_day_count') _OmerSummary(factor: factor),
          const Divider(height: 32, color: Color(0xFFE0D5C5)),
        ],
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
            alignment: WrapAlignment.end,
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
