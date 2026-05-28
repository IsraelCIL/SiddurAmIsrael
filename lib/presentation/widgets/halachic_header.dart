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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    Text(
                      'נוסח ${HebrewFormatter.nusachName(nusach)}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: AppColors.headerSubtitle,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (displayFlags.isNotEmpty) ...[
                  const SizedBox(height: 6),
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
          ),
        ],
      ),
    );
  }
}
