import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assembled_segment.dart';
import '../providers/prayer_providers.dart';

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
};

class PrayerTextWidget extends ConsumerWidget {
  const PrayerTextWidget({super.key, required this.segment});

  final AssembledSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = ref.watch(fontSizeFactorProvider);
    final label = _segmentLabels[segment.id] ?? segment.id;

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
          Text(
            segment.resolvedText,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 22 * factor,
              height: 1.9,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 32, color: Color(0xFFE0D5C5)),
        ],
      ),
    );
  }
}
