import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/omer_day.dart';
import 'package:siddur_am_israel_chai/presentation/constants/segment_labels.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/rich_prayer_text.dart';

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
  // אין כאלהינו flows directly into אתה הוא שהקטירו (no visual gap)
  'ein_keloheinu',
};

/// Compact inline toggle row rendered inside the prayer scroll view.
class _PrayerInlineToggle extends ConsumerWidget {
  const _PrayerInlineToggle({required this.segmentId});
  final String segmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, value, onChanged) = _resolve(ref);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryDarker,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, bool, void Function(bool)) _resolve(WidgetRef ref) {
    switch (segmentId) {
      case 'inline_toggle_tallit_gadol':
        return (
          'מתעטף בטלית גדול',
          ref.watch(wearsTallitGadolProvider),
          (v) => ref.read(wearsTallitGadolProvider.notifier).set(v),
        );
      case 'inline_toggle_shaliach_tzibbur':
        return (
          'אני שליח ציבור',
          ref.watch(isShaliachTzibburProvider),
          (v) => ref.read(isShaliachTzibburProvider.notifier).set(v),
        );
      case 'inline_toggle_kohanim':
        return (
          'יש כהנים',
          !ref.watch(einKohanumProvider),
          (v) => ref.read(einKohanumProvider.notifier).set(!v),
        );
      default:
        return ('', false, (_) {});
    }
  }
}

const _inlineToggleIds = {
  'inline_toggle_tallit_gadol',
  'inline_toggle_shaliach_tzibbur',
  'inline_toggle_kohanim',
};

class PrayerTextWidget extends ConsumerWidget {
  const PrayerTextWidget({super.key, required this.segment});

  final AssembledSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inline toggle markers render as compact toggle rows, not prayer text.
    if (_inlineToggleIds.contains(segment.id)) {
      return _PrayerInlineToggle(segmentId: segment.id);
    }

    final factor = ref.watch(fontSizeFactorProvider);
    final showLabels = ref.watch(showSegmentLabelsProvider);
    final label = segmentLabel(segment.id);
    final bodyStyle = GoogleFonts.notoSerifHebrew(
      fontSize: 22 * factor,
      height: 1.5,
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
                color: AppColors.primary,
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
class _OptionalSegmentTile extends ConsumerStatefulWidget {
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
  ConsumerState<_OptionalSegmentTile> createState() =>
      _OptionalSegmentTileState();
}

class _OptionalSegmentTileState extends ConsumerState<_OptionalSegmentTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // Start expanded if the hardcoded default OR the user previously opened it.
    final saved = ref.read(expandedSegmentsProvider);
    _expanded = widget.initiallyExpanded || saved.contains(widget.segment.id);
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 14 * widget.factor,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      letterSpacing: 0.5,
    );
    final hintStyle = TextStyle(
      fontSize: 12 * widget.factor,
      fontWeight: FontWeight.w400,
      color: AppColors.primary.withValues(alpha: 0.6),
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
          onExpansionChanged: (v) {
            setState(() => _expanded = v);
            ref.read(expandedSegmentsProvider.notifier).toggle(widget.segment.id);
          },
          title: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20 * widget.factor,
                  color: AppColors.primary,
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
            const Divider(height: 1, color: AppColors.borderLight),
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
      color: AppColors.textSecondary,
    );
    final valueStyle = TextStyle(
      fontSize: 15 * factor,
      color: AppColors.textPrimary,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
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
