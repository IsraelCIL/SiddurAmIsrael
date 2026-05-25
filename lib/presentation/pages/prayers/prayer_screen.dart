import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/assembled_segment.dart';
import '../../widgets/font_size_fab.dart';
import '../../widgets/halachic_header.dart';
import '../../widgets/prayer_text_widget.dart';
import '../../widgets/settings_reminder_banner.dart';

/// Generic prayer screen reused by Shacharit / Mincha / Maariv. The
/// specific service is selected by the [contentProvider] (a FutureProvider
/// of assembled segments). Layout:
///
///   ┌──────────────────────────────┐
///   │ SettingsReminderBanner (top) │  ← dismissible
///   ├──────────────────────────────┤
///   │ SliverAppBar w/ HalachicHeader│
///   │ … prayer segments …          │
///   │                              │
///   │              ┌──┐            │
///   │              │A+│ ← FAB overlay
///   │              │A-│
///   └──────────────┴──┘────────────
///
/// No top-right font buttons — those are now thumb-reachable
/// semi-transparent FABs in the bottom-left corner.
class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({
    super.key,
    required this.title,
    required this.contentProvider,
    this.onOpenSettings,
  });

  final String title;
  final FutureProvider<List<AssembledSegment>> contentProvider;

  /// Forwarded to [SettingsReminderBanner] so the AppShell can switch tabs.
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerAsync = ref.watch(widget.contentProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: Stack(
        children: [
          Column(
            children: [
              SettingsReminderBanner(onOpenSettings: widget.onOpenSettings),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 140,
                      pinned: true,
                      backgroundColor: const Color(0xFF8B1A1A),
                      foregroundColor: Colors.white,
                      title: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      centerTitle: true,
                      flexibleSpace: const FlexibleSpaceBar(
                        background: HalachicHeader(),
                        collapseMode: CollapseMode.pin,
                      ),
                    ),
                    prayerAsync.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF8B1A1A)),
                        ),
                      ),
                      error: (err, _) => SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'שגיאה בטעינת התפילה\n$err',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      data: (segments) => _PrayerList(segments: segments),
                    ),
                  ],
                ),
              ),
            ],
          ),
          FontSizeFab(scrollController: _scrollController),
        ],
      ),
    );
  }
}

class _PrayerList extends StatelessWidget {
  const _PrayerList({required this.segments});

  final List<AssembledSegment> segments;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => PrayerTextWidget(segment: segments[index]),
        childCount: segments.length,
      ),
    );
  }
}
