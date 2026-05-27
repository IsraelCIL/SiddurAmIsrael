import 'package:flutter/material.dart';
import 'package:smart_siddur/presentation/pages/prayers/prayer_screen.dart';
import 'package:smart_siddur/presentation/providers/prayer_providers.dart';

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
