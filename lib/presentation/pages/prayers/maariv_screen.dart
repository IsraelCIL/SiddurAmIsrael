import 'package:flutter/material.dart';

import '../../providers/prayer_providers.dart';
import 'prayer_screen.dart';

class MaarivScreen extends StatelessWidget {
  const MaarivScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) => PrayerScreen(
        title: 'מעריב',
        contentProvider: maarivProvider,
        onOpenSettings: onOpenSettings,
      );
}
