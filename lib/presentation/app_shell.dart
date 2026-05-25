import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/services/service_time_resolver.dart';
import 'pages/prayers/maariv_screen.dart';
import 'pages/prayers/mincha_screen.dart';
import 'pages/prayers/shacharit_screen.dart';
import 'pages/settings/settings_screen.dart';
import 'providers/prayer_providers.dart';

/// Top-level shell with 4 bottom tabs:
///   0 → Shacharit  (visually rightmost in RTL)
///   1 → Mincha
///   2 → Maariv
///   3 → Settings   (visually leftmost in RTL)
///
/// Initial tab is picked from [currentServiceProvider] (halachic zmanim).
/// Tab state is preserved via [IndexedStack] so scroll positions and
/// transient UI state survive tab switches.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _currentIndex;

  static const int _shacharitIdx = 0;
  static const int _minchaIdx = 1;
  static const int _maarivIdx = 2;
  static const int _settingsIdx = 3;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(currentServiceProvider);
    _currentIndex = switch (initial) {
      PrayerService.shacharit => _shacharitIdx,
      PrayerService.mincha => _minchaIdx,
      PrayerService.maariv => _maarivIdx,
    };
  }

  void _openSettings() => setState(() => _currentIndex = _settingsIdx);

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ShacharitScreen(onOpenSettings: _openSettings),
      MinchaScreen(onOpenSettings: _openSettings),
      MaarivScreen(onOpenSettings: _openSettings),
      const SettingsScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF8B1A1A),
          unselectedItemColor: Colors.grey,
          backgroundColor: const Color(0xFFFDF8F0),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined),
              activeIcon: Icon(Icons.wb_sunny),
              label: 'שחרית',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.brightness_6_outlined),
              activeIcon: Icon(Icons.brightness_6),
              label: 'מנחה',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.brightness_4_outlined),
              activeIcon: Icon(Icons.brightness_4),
              label: 'מעריב',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'הגדרות',
            ),
          ],
        ),
      ),
    );
  }
}
