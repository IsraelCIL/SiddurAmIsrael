import 'package:flutter/material.dart';

import '../../providers/prayer_providers.dart';
import 'prayer_screen.dart';

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
