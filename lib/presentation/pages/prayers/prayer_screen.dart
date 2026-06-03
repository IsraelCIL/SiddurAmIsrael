import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/font_size_fab.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/halachic_header.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/prayer_text_widget.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/settings_reminder_banner.dart';

// ── Group accordion config ────────────────────────────────────────────────────

const _groupTitles = <String, String>{
  'chazarat_hashatz': 'חזרת הש״ץ',
  'ketoret_group': 'פרשת הקטורת',
  'pitum_group': 'פטום הקטורת',
  'eizehu_group': 'איזהו מקומן',
};

// ── Nav anchors ───────────────────────────────────────────────────────────────
// Defines WHICH segments appear as nav list items and with what label.
// Only entries matching (segmentId + occurrence index) produce a nav item.
// Segments appear in the nav list in the order they occur in the assembled
// prayer — this list only determines which ones are included and their labels.

class _NavSpec {
  const _NavSpec(this.segmentId, this.label, {this.occurrence = 0, this.group = ''});
  final String segmentId;
  final String label;
  final int occurrence; // 0 = first occurrence, 1 = second, …
  // When non-empty, only the FIRST matching spec in this group creates a nav
  // entry. Use to handle mutually-exclusive anchors (e.g. psalm_030 vs hodu
  // both map to "פסוקי דזמרה" but only whichever appears first fires).
  final String group;
}

const _navSpecs = <_NavSpec>[
  // ── Lifnei HaTfila ──────────────────────────────────────────────────────
  _NavSpec('modeh_ani',             'השכמת הבוקר'),
  _NavSpec('birkat_tzitzit_gadol',  'סדר לבישת ציצית'),
  _NavSpec('seder_tefillin',        'סדר הנחת תפילין'),
  _NavSpec('birkot_hashachar_header', 'ברכות השחר'),
  _NavSpec('akeidah',               'פרשת העקידה'),
  _NavSpec('korbanot_eizehu_header','איזהו מקומן'),
  _NavSpec('korbanot_conclusion',   'רבי ישמעאל'),
  _NavSpec('kaddish_derabanan_header', 'קדיש דרבנן'),
  // ── Pesukei DeZimra ─────────────────────────────────────────────────────
  // Ashkenaz starts with psalm_030; Sfard/EM starts with hodu.
  // group:'pezimra_start' ensures only the first one found fires.
  _NavSpec('psalm_030',             'פסוקי דזמרה', group: 'pezimra_start'),
  _NavSpec('hodu',                  'פסוקי דזמרה', group: 'pezimra_start'),
  _NavSpec('baruch_sheamar',        'ברוך שאמר'),
  _NavSpec('ashrei',                'אשרי יושבי ביתך'),   // 1st = pesukei dezimra
  _NavSpec('yishtabach',            'ישתבח'),
  // ── Birkot Kriat Shema ──────────────────────────────────────────────────
  _NavSpec('yotzer_or',             'יוצר אור'),
  _NavSpec('shema',                 'קריאת שמע'),
  // ── Amidah (one entry for entire amidah) ────────────────────────────────
  _NavSpec('amidah_intro',          'עמידה'),
  // ── Chazarat HaShatz (inside accordion) ─────────────────────────────────
  _NavSpec('kedushah',              'קדושה'),
  _NavSpec('modim_derabanan',       'מודים דרבנן'),
  _NavSpec('birkat_kohanim',        'ברכת כהנים'),
  // ── Post-amidah ─────────────────────────────────────────────────────────
  _NavSpec('tachanun',              'תחנון'),
  _NavSpec('kriat_hatorah_hotzaah', 'קריאת התורה'),
  _NavSpec('ashrei',                'אשרי',    occurrence: 1), // 2nd = after musaf
  // שיר של יום — exactly one day-variant fires per service.
  _NavSpec('shir_shel_yom_sunday',    'שיר של יום'),
  _NavSpec('shir_shel_yom_monday',    'שיר של יום'),
  _NavSpec('shir_shel_yom_tuesday',   'שיר של יום'),
  _NavSpec('shir_shel_yom_wednesday', 'שיר של יום'),
  _NavSpec('shir_shel_yom_thursday',  'שיר של יום'),
  _NavSpec('shir_shel_yom_friday',    'שיר של יום'),
  _NavSpec('shir_shel_yom_shabbat',   'שיר של יום'),
  // ── Sof HaTfila ─────────────────────────────────────────────────────────
  _NavSpec('musaf_header',          'מוסף'),
  _NavSpec('ein_keloheinu',         'אין כאלקינו'),
  _NavSpec('aleinu',                'עלינו לשבח'),
  _NavSpec('ladavid',               'לדוד ה׳'),
];

/// Finds the matching nav spec for [id] at [occurrence], respecting group
/// exclusivity via [satisfiedGroups] (mutates it when a group fires).
_NavSpec? _findNavSpec(String id, int occurrence, Set<String> satisfiedGroups) {
  for (final spec in _navSpecs) {
    if (spec.segmentId != id || spec.occurrence != occurrence) continue;
    if (spec.group.isNotEmpty && satisfiedGroups.contains(spec.group)) {
      return null; // another spec in this group already fired
    }
    if (spec.group.isNotEmpty) satisfiedGroups.add(spec.group);
    return spec;
  }
  return null;
}

// ── PrayerScreen ─────────────────────────────────────────────────────────────

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({
    super.key,
    required this.title,
    required this.contentProvider,
    this.onOpenSettings,
  });

  final String title;
  final FutureProvider<List<AssembledSegment>> contentProvider;
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  final ScrollController _scrollController = ScrollController();

  List<_ListItem>? _cachedItems;
  List<_NavEntry>? _cachedNavEntries;
  List<AssembledSegment>? _lastSegments;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCache(List<AssembledSegment> segments) {
    if (identical(segments, _lastSegments)) return;
    // Save scroll offset before the list rebuilds (e.g. after inline toggle).
    final savedOffset = _scrollController.hasClients &&
            _scrollController.position.hasContentDimensions
        ? _scrollController.offset
        : 0.0;
    _lastSegments = segments;
    _cachedItems = _buildListItems(segments);
    _cachedNavEntries = _buildNavEntries(_cachedItems!);
    // Restore scroll position after layout so inline toggles don't jump.
    if (savedOffset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients &&
            _scrollController.position.hasContentDimensions) {
          _scrollController.jumpTo(
            savedOffset.clamp(
                0.0, _scrollController.position.maxScrollExtent),
          );
        }
      });
    }
  }

  void _showNavSheet() {
    final entries = _cachedNavEntries;
    if (entries == null || entries.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NavSheet(
        entries: entries,
        scrollController: _scrollController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayerAsync = ref.watch(widget.contentProvider);
    final bannerSeen = ref.watch(hasSeenSettingsBannerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
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
                      backgroundColor: AppColors.primary,
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
                      // Keep showing previous content while inline toggles
                      // trigger a provider refresh — prevents scroll jumping.
                      skipLoadingOnRefresh: true,
                      loading: () => const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
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
                      data: (segments) {
                        _updateCache(segments);
                        final items = _cachedItems!;
                        // Eager (non-lazy) list so every GlobalKey is always
                        // in the widget tree — required for reliable nav scroll.
                        return SliverList(
                          delegate: SliverChildListDelegate(
                            [for (final item in items) item.build(context)],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          FontSizeFab(scrollController: _scrollController),
          if (prayerAsync.hasValue &&
              (_cachedNavEntries?.isNotEmpty ?? false))
            Positioned(
              // Below the collapsed toolbar + clear of the title text.
              // Add extra offset when the settings banner is still visible
              // (~44 dp) so the button doesn't land on the banner row.
              top: bannerSeen ? kToolbarHeight + 4 : kToolbarHeight + 48,
              right: 12,
              child: _NavFab(onTap: _showNavSheet),
            ),
        ],
      ),
      ),
    );
  }
}

// ── List item helpers ─────────────────────────────────────────────────────────

/// Walks the assembled segments and builds the list of UI items:
/// - Consecutive segments with the same non-empty groupId → one [_GroupItem].
/// - Everything else → individual [_SegmentItem].
///
/// [occurrenceCounts] is shared across all items so grouped children count
/// toward the global occurrence index.
List<_ListItem> _buildListItems(List<AssembledSegment> segments) {
  final items = <_ListItem>[];
  final counts = <String, int>{};
  final satisfiedGroups = <String>{};

  int i = 0;
  while (i < segments.length) {
    final seg = segments[i];
    final gid = seg.groupId;

    if (gid.isNotEmpty) {
      final grouped = <AssembledSegment>[];
      final groupStartIdx = items.length;
      while (i < segments.length && segments[i].groupId == gid) {
        grouped.add(segments[i]);
        i++;
      }
      final title = _groupTitles[gid] ?? gid;
      items.add(_GroupItem(
        title: title,
        segments: grouped,
        counts: counts,
        satisfiedGroups: satisfiedGroups,
        itemIndex: groupStartIdx,
        // totalItems placeholder — filled after full list is built
      ));
    } else {
      final occ = counts[seg.id] ?? 0;
      counts[seg.id] = occ + 1;
      final spec = _findNavSpec(seg.id, occ, satisfiedGroups);
      final key = spec != null ? GlobalKey() : null;
      items.add(_SegmentItem(
        segment: seg,
        navKey: key,
        navLabel: spec?.label,
        itemIndex: items.length,
      ));
      i++;
    }
  }

  // Back-fill totalItems now that we know the full count.
  final total = items.length;
  for (final item in items) {
    if (item is _SegmentItem) item._totalItems = total;
    if (item is _GroupItem) item._totalItems = total;
  }
  return items;
}

List<_NavEntry> _buildNavEntries(List<_ListItem> items) {
  final entries = <_NavEntry>[];
  for (final item in items) {
    if (item is _SegmentItem) {
      final e = item.navEntry;
      if (e != null) entries.add(e);
    } else if (item is _GroupItem) {
      // Group item itself is NOT a nav entry; only its nav-anchor children are.
      entries.addAll(item.childNavEntries);
    }
  }
  return entries;
}

// ── Abstract list item ────────────────────────────────────────────────────────

abstract class _ListItem {
  const _ListItem();
  Widget build(BuildContext context);
}

// ── Segment item ──────────────────────────────────────────────────────────────

class _SegmentItem extends _ListItem {
  _SegmentItem({
    required this.segment,
    required this.navKey,
    required this.navLabel,
    required this.itemIndex,
  });

  final AssembledSegment segment;
  final GlobalKey? navKey;
  final String? navLabel;
  final int itemIndex;
  // Set after the full list is built.
  int _totalItems = 1;

  _NavEntry? get navEntry {
    final k = navKey;
    final l = navLabel;
    if (k == null || l == null) return null;
    return _NavEntry(
      label: l,
      key: k,
      itemIndex: itemIndex,
      totalItems: _totalItems,
    );
  }

  @override
  Widget build(BuildContext context) =>
      PrayerTextWidget(key: navKey, segment: segment);
}

// ── Group item (accordion) ────────────────────────────────────────────────────

class _GroupItem extends _ListItem {
  _GroupItem({
    required this.title,
    required this.segments,
    required Map<String, int> counts,
    required Set<String> satisfiedGroups,
    required this.itemIndex,
  }) : _key = GlobalKey(),
       _controller = ExpansibleController() {
    // Scan children for nav anchors; update the shared occurrence counter.
    final childKeys = <int, GlobalKey>{};
    final entries = <_NavEntry>[];

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final occ = counts[seg.id] ?? 0;
      counts[seg.id] = occ + 1;

      final spec = _findNavSpec(seg.id, occ, satisfiedGroups);
      if (spec != null) {
        final key = GlobalKey();
        childKeys[i] = key;
        entries.add(_NavEntry(
          label: spec.label,
          key: key,
          onBeforeScroll: _controller.expand,
          itemIndex: itemIndex, // group's position in the full list
          totalItems: _totalItems,
        ));
      }
    }

    _childKeys = childKeys;
    _childNavEntries = entries;
  }

  final String title;
  final List<AssembledSegment> segments;
  final int itemIndex;
  final GlobalKey _key;
  final ExpansibleController _controller;
  late final Map<int, GlobalKey> _childKeys;
  late final List<_NavEntry> _childNavEntries;
  // Set after the full list is built.
  int _totalItems = 1;

  List<_NavEntry> get childNavEntries => _childNavEntries;

  @override
  Widget build(BuildContext context) => _GroupAccordion(
        key: _key,
        title: title,
        segments: segments,
        controller: _controller,
        childKeys: _childKeys,
      );
}

// ── Group accordion widget ────────────────────────────────────────────────────

class _GroupAccordion extends StatefulWidget {
  const _GroupAccordion({
    super.key,
    required this.title,
    required this.segments,
    required this.controller,
    required this.childKeys,
  });

  final String title;
  final List<AssembledSegment> segments;
  final ExpansibleController controller;
  final Map<int, GlobalKey> childKeys;

  @override
  State<_GroupAccordion> createState() => _GroupAccordionState();
}

class _GroupAccordionState extends State<_GroupAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: widget.controller,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: false,
            shape: const Border(),
            collapsedShape: const Border(),
            onExpansionChanged: (v) => setState(() => _expanded = v),
            title: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (!_expanded) ...[
                    const SizedBox(width: 8),
                    Text(
                      '[לחץ להצגה]',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            children: [
              for (var i = 0; i < widget.segments.length; i++)
                PrayerTextWidget(
                  key: widget.childKeys[i],
                  segment: widget.segments[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav FAB ───────────────────────────────────────────────────────────────────

class _NavFab extends StatelessWidget {
  const _NavFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.primary,
          size: 26,
        ),
      ),
    );
  }
}

// ── Navigation entry ──────────────────────────────────────────────────────────

class _NavEntry {
  const _NavEntry({
    required this.label,
    required this.key,
    this.onBeforeScroll,
    this.itemIndex = 0,
    this.totalItems = 1,
  });

  final String label;
  final GlobalKey key;
  /// Called before scrolling (e.g., to expand an accordion). The nav sheet
  /// waits 350 ms after the call to allow the animation to complete.
  final VoidCallback? onBeforeScroll;
  /// Position of this item in the full assembled list — used for fallback
  /// scroll estimation when the widget is off-screen.
  final int itemIndex;
  final int totalItems;
}

// ── Navigation sheet ──────────────────────────────────────────────────────────

class _NavSheet extends StatelessWidget {
  const _NavSheet({
    required this.entries,
    required this.scrollController,
  });

  final List<_NavEntry> entries;
  final ScrollController scrollController;

  Future<void> _jumpTo(BuildContext context, _NavEntry entry) async {
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));

    final beforeScroll = entry.onBeforeScroll;
    if (beforeScroll != null) {
      beforeScroll();
      await Future.delayed(const Duration(milliseconds: 350));
    }

    final ctx = entry.key.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
      return;
    }

    // Item off-screen — use item-list fraction for a better position estimate.
    final maxExtent = scrollController.position.maxScrollExtent;
    final fraction = entry.totalItems > 1
        ? entry.itemIndex / entry.totalItems
        : entries.indexOf(entry) / entries.length.clamp(1, 9999);
    await scrollController.animateTo(
      maxExtent * fraction,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    await Future.delayed(const Duration(milliseconds: 150));
    final ctx2 = entry.key.currentContext;
    if (ctx2 != null && ctx2.mounted) {
      Scrollable.ensureVisible(
        ctx2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, sheetScroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.format_list_bulleted,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'קפיצה לקטע',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.black54,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            Expanded(
              child: ListView.separated(
                controller: sheetScroll,
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (ctx, i) {
                  final entry = entries[i];
                  return InkWell(
                    onTap: () => _jumpTo(context, entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_left,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.label,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
