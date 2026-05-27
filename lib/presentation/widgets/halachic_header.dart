import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_siddur/core/utils/hebrew_formatter.dart';
import 'package:smart_siddur/presentation/providers/prayer_providers.dart';
import 'package:smart_siddur/presentation/theme/app_colors.dart';
import 'package:smart_siddur/presentation/widgets/flag_badge.dart';

class HalachicHeader extends ConsumerWidget {
  const HalachicHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hebrewDate = ref.watch(hebrewDateProvider);
    final nusach = ref.watch(nusachProvider);
    final ctx = ref.watch(userContextProvider);

    final displayFlags = ctx.activeFlags.where(FlagBadge.isDisplayWorthy).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            HebrewFormatter.formatFullDate(hebrewDate),
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'נוסח ${HebrewFormatter.nusachName(nusach)}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: AppColors.headerSubtitle,
              fontSize: 13,
            ),
          ),
          if (displayFlags.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: displayFlags
                    .map((f) => FlagBadge(flag: f))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
