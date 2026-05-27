import 'package:flutter/material.dart';
import 'package:smart_siddur/presentation/pages/prayers/prayer_screen.dart';
import 'package:smart_siddur/presentation/providers/prayer_providers.dart';

class ShacharitScreen extends StatelessWidget {
  const ShacharitScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) => PrayerScreen(
        title: 'שחרית',
        contentProvider: shacharitProvider,
        onOpenSettings: onOpenSettings,
      );
}
