import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siddur_am_israel_chai/core/utils/hebrew_formatter.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';

/// Slim banner shown at the top of every prayer screen on first launch.
/// Dismissible via the close icon or by tapping the Settings shortcut.
class SettingsReminderBanner extends ConsumerWidget {
  const SettingsReminderBanner({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(hasSeenSettingsBannerProvider);
    if (seen) return const SizedBox.shrink();
    final nusach = ref.watch(nusachProvider);
    final nusachName = HebrewFormatter.nusachName(nusach);

    void dismiss() {
      ref.read(hasSeenSettingsBannerProvider.notifier).set(true);
    }

    return Material(
      color: AppColors.bannerBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'התפילה מוצגת בנוסח $nusachName. ניתן לשנות בהגדרות.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryDarker,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  dismiss();
                  onOpenSettings?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('פתח הגדרות',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: dismiss,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.primary,
                tooltip: 'סגור',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
