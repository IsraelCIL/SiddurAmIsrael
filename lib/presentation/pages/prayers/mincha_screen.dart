import 'package:flutter/material.dart';

import '../../providers/prayer_providers.dart';
import 'prayer_screen.dart';

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
