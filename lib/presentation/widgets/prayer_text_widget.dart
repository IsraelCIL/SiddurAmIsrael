import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/assembled_segment.dart';
import '../providers/prayer_providers.dart';

const _segmentLabels = <String, String>{
  'ashrei': 'אשרי',
  'petihat_eliyahu': 'פתיחת אליהו',
  'kriat_hatorah_mincha': 'קריאת התורה במנחה',
  'amidah_mincha': 'עמידה',
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
