import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siddur_am_israel_chai/presentation/i18n/app_strings.dart';
import 'package:siddur_am_israel_chai/presentation/pages/prayers/prayer_screen.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';

/// Landing screen for the "ברכות" tab — a menu of standalone blessings.
/// Birkat HaMazon, Me'ein Shalosh and Tefilat HaDerech are live; Kiddush
/// Levana is a placeholder awaiting its content.
class BerachotScreen extends ConsumerWidget {
  const BerachotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.t('tab_berachot'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _BerachaTile(
            title: s.t('birkat_hamazon'),
            subtitle: s.t('birkat_hamazon_sub'),
            icon: Icons.bakery_dining_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: PrayerScreen(
                    title: s.t('birkat_hamazon'),
                    contentProvider: birkatHamazonProvider,
                  ),
                ),
              ),
            ),
          ),
          _BerachaTile(
            title: s.t('meein_shalosh'),
            subtitle: s.t('meein_shalosh_sub'),
            icon: Icons.local_cafe_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: PrayerScreen(
                    title: s.t('meein_shalosh'),
                    contentProvider: meeinShaloshProvider,
                  ),
                ),
              ),
            ),
          ),
          _BerachaTile(
            title: s.t('tefilat_haderech'),
            subtitle: s.t('tefilat_haderech_sub'),
            icon: Icons.directions_walk_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: PrayerScreen(
                    title: s.t('tefilat_haderech'),
                    contentProvider: tefilatHaderechProvider,
                  ),
                ),
              ),
            ),
          ),
          _BerachaTile(
            title: s.t('kiddush_levana'),
            subtitle: s.t('coming_soon'),
            icon: Icons.nightlight_outlined,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _BerachaTile extends StatelessWidget {
  const _BerachaTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: enabled ? Colors.white : AppColors.surface,
      elevation: enabled ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon,
            color: enabled ? AppColors.primary : AppColors.textSecondary),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary)),
        trailing: enabled
            ? const Icon(Icons.chevron_left, color: AppColors.textSecondary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
