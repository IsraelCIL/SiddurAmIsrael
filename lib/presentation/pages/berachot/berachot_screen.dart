import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/presentation/pages/prayers/prayer_screen.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';

/// Landing screen for the "ברכות" tab — a menu of standalone blessings.
/// Birkat HaMazon, Me'ein Shalosh and Tefilat HaDerech are live; Kiddush
/// Levana is a placeholder awaiting its content.
class BerachotScreen extends StatelessWidget {
  const BerachotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ברכות',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _BerachaTile(
            title: 'ברכת המזון',
            subtitle: 'לאחר סעודת לחם',
            icon: Icons.bakery_dining_outlined,
            onTap: () => _open(context, 'ברכת המזון', birkatHamazonProvider),
          ),
          _BerachaTile(
            title: 'ברכה מעין שלוש',
            subtitle: 'לאחר מזונות, יין ופירות',
            icon: Icons.local_cafe_outlined,
            onTap: () => _open(context, 'ברכה מעין שלוש', meeinShaloshProvider),
          ),
          _BerachaTile(
            title: 'תפילת הדרך',
            subtitle: 'לפני יציאה לדרך',
            icon: Icons.directions_walk_outlined,
            onTap: () => _open(context, 'תפילת הדרך', tefilatHaderechProvider),
          ),
          const _BerachaTile(
            title: 'קידוש לבנה',
            subtitle: 'בקרוב',
            icon: Icons.nightlight_outlined,
            onTap: null,
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, String title,
      FutureProvider<List<AssembledSegment>> provider) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: PrayerScreen(title: title, contentProvider: provider),
        ),
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
