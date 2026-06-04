import 'package:flutter/material.dart';
import 'package:siddur_am_israel_chai/presentation/pages/prayers/prayer_screen.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';

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
