import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siddur_am_israel_chai/domain/services/service_time_resolver.dart';
import 'package:siddur_am_israel_chai/presentation/pages/berachot/berachot_screen.dart';
import 'package:siddur_am_israel_chai/presentation/pages/prayers/prayer_menu_screen.dart';
import 'package:siddur_am_israel_chai/presentation/pages/settings/settings_screen.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';

/// Top-level shell with 3 bottom tabs:
///   0 → Prayers   (Shacharit / Mincha / Maariv — opens on the current service)
///   1 → Berachot  (Birkat HaMazon, Me'ein Shalosh, …)
///   2 → Settings
///
/// The Prayers tab is a nested [Navigator] whose initial stack is
/// [menu, current-service], so the app opens directly onto the prayer that
/// matches the current time while a back-tap (or re-tapping the tab) reveals
/// the list. Tab state is preserved via [IndexedStack].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  static const int _prayersIdx = 0;
  static const int _settingsIdx = 2;

  final _prayersNavKey = GlobalKey<NavigatorState>();

  void _openSettings() => setState(() => _currentIndex = _settingsIdx);

  void _onTapTab(int i) {
    // Re-tapping the active Prayers tab returns to its list (pops the reader).
    if (i == _currentIndex && i == _prayersIdx) {
      _prayersNavKey.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _PrayersTab(navKey: _prayersNavKey, onOpenSettings: _openSettings),
      const BerachotScreen(),
      const SettingsScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTapTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          backgroundColor: AppColors.background,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories),
              label: 'תפילות',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'ברכות',
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

/// The Prayers tab: a nested navigator whose root is the prayer menu, with the
/// current-time service pushed on top so the app opens straight into it.
class _PrayersTab extends ConsumerWidget {
  const _PrayersTab({required this.navKey, required this.onOpenSettings});

  final GlobalKey<NavigatorState> navKey;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.read(currentServiceProvider);
    final currentTitle = switch (current) {
      PrayerService.shacharit => 'שחרית',
      PrayerService.mincha => 'מנחה',
      PrayerService.maariv => 'מעריב',
    };

    return Navigator(
      key: navKey,
      onGenerateInitialRoutes: (navigator, initialRoute) => [
        MaterialPageRoute<void>(
          builder: (_) => PrayerMenuScreen(onOpenSettings: onOpenSettings),
        ),
        MaterialPageRoute<void>(
          builder: (_) => buildPrayerReader(
            current,
            currentTitle,
            onOpenSettings: onOpenSettings,
          ),
        ),
      ],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => PrayerMenuScreen(onOpenSettings: onOpenSettings),
      ),
    );
  }
}
