import 'package:flutter/material.dart';
import 'package:siddur_am_israel_chai/presentation/pages/prayers/prayer_screen.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';

class MinchaScreen extends StatelessWidget {
  const MinchaScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) => PrayerScreen(
        title: 'מנחה',
        contentProvider: minchaProvider,
        onOpenSettings: onOpenSettings,
      );
}
