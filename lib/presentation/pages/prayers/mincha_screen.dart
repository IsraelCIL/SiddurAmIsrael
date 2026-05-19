import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/assembled_segment.dart';
import '../../providers/prayer_providers.dart';
import '../../widgets/halachic_header.dart';
import '../../widgets/prayer_text_widget.dart';

class MinchaScreen extends ConsumerWidget {
  const MinchaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAsync = ref.watch(minchaProvider);
    final factor = ref.watch(fontSizeFactorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF8B1A1A),
            foregroundColor: Colors.white,
            title: const Text(
              'מנחה',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.text_increase, color: Colors.white),
                tooltip: 'הגדל גופן',
                onPressed: factor < 1.6
                    ? () => ref.read(fontSizeFactorProvider.notifier).state =
                        (factor + 0.1).clamp(0.6, 1.6)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.text_decrease, color: Colors.white),
                tooltip: 'הקטן גופן',
                onPressed: factor > 0.6
                    ? () => ref.read(fontSizeFactorProvider.notifier).state =
                        (factor - 0.1).clamp(0.6, 1.6)
                    : null,
              ),
            ],
            flexibleSpace: const FlexibleSpaceBar(
              background: HalachicHeader(),
              collapseMode: CollapseMode.pin,
            ),
          ),
          prayerAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B1A1A)),
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
