import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosher_dart/kosher_dart.dart';

import 'package:smart_siddur/presentation/providers/prayer_providers.dart';
import 'package:smart_siddur/presentation/theme/app_colors.dart';

/// Wraps any widget tree with a floating dev button (debug builds only).
/// In release builds this returns [child] unchanged with zero overhead.
///
/// Tap the 🛠 button to open the date/time control panel with quick presets
/// for every testable scenario in the siddur.
class DevOverlay extends StatelessWidget {
  const DevOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return Stack(
      children: [
        child,
        const _DevFab(),
      ],
    );
  }
}

class _DevFab extends ConsumerWidget {
  const _DevFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(devDateTimeOverrideProvider);
    final isActive = override != null;

    return Positioned(
      // Bottom-right: clear of the settings-banner × button (top-left in RTL),
      // the nav-sheet arrow (top-right), and the font-size FABs (bottom-left).
      right: 12,
      bottom: kBottomNavigationBarHeight + 12,
      child: GestureDetector(
        onTap: () => _showPanel(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.92)
                : Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🛠', style: TextStyle(fontSize: 14)),
              if (isActive) ...[
                const SizedBox(width: 4),
                Text(
                  _fmt(override),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final d = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  void _showPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DevPanel(),
    );
  }
}

// ── Dev panel ─────────────────────────────────────────────────────────────────

class _DevPanel extends ConsumerStatefulWidget {
  const _DevPanel();

  @override
  ConsumerState<_DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends ConsumerState<_DevPanel> {
  @override
  Widget build(BuildContext context) {
    final override = ref.watch(devDateTimeOverrideProvider);
    final effective = override ?? DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.bug_report, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'כלי פיתוח — תאריך ושעה',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (override != null)
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'איפוס לזמן אמיתי',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.black54,
                ),
              ],
            ),

            // ── Current value ────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: override != null
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: override != null
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                override == null
                    ? 'זמן אמיתי (ללא דריסה)'
                    : 'דריסה פעילה: ${_longFmt(override)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      override != null ? AppColors.primary : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),

            // ── Manual pickers ───────────────────────────────────────────────
            const _SectionLabel('בחירה ידנית'),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.calendar_today,
                    label: _dateStr(effective),
                    onTap: () => _pickDate(effective),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.access_time,
                    label: _timeStr(effective),
                    onTap: () => _pickTime(effective),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Prayer-time presets ──────────────────────────────────────────
            const _SectionLabel('זמני תפילה (היום)'),
            _PresetGrid(children: [
              _Preset('שחרית\n08:00', () => _applyTime(8, 0)),
              _Preset('מנחה\n15:00', () => _applyTime(15, 0)),
              _Preset('מעריב\n20:00', () => _applyTime(20, 0)),
              _Preset('חצות לילה\n00:05', () => _applyTime(0, 5)),
            ]),

            const SizedBox(height: 12),

            // ── Calendar presets ─────────────────────────────────────────────
            // All dates are computed dynamically from "today" using
            // kosher_dart's JewishCalendar — so they always point to the
            // correct upcoming halachic day, regardless of when the app
            // is opened. See [_findNext] below.
            const _SectionLabel('מועדים לבדיקה'),
            _PresetGrid(children: [
              _Preset('ראש חודש\nרגיל', () => _applyDateExact(_findNextRoshChodeshRegular())),
              _Preset('ראש חודש\nטבת', () => _applyDateExact(_findNextRcTevet())),
              _Preset('חנוכה\nיום 1', () => _applyDateExact(_findNextChanukahDay(1))),
              _Preset('חנוכה\nיום 8', () => _applyDateExact(_findNextChanukahDay(8))),
              _Preset('ספירת\nהעומר', () => _applyDateExact(_findNextOmerDay(20))),
              _Preset('חוה"מ\nפסח', () => _applyDateExact(_findNextCholHamoedPesach())),
              _Preset('חוה"מ\nסוכות', () => _applyDateExact(_findNextCholHamoedSukkot())),
              _Preset('פורים\nיד אדר', () => _applyDateExact(_findNextPurim())),
              _Preset('תענית\nציבור', () => _applyDateExact(_findNextPublicFast())),
              _Preset('תשעה\nבאב', () => _applyDateExact(_findNextTishaBav())),
              _Preset('ראש\nהשנה', () => _applyDateExact(_findNextRoshHashanah())),
              _Preset('יום\nכיפור', () => _applyDateExact(_findNextYomKippur())),
            ]),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _reset() {
    ref.read(devDateTimeOverrideProvider.notifier).state = null;
  }

  void _applyTime(int hour, int minute) {
    final current = ref.read(devDateTimeOverrideProvider) ?? DateTime.now();
    ref.read(devDateTimeOverrideProvider.notifier).state =
        DateTime(current.year, current.month, current.day, hour, minute);
  }

  void _applyDateExact(DateTime d) {
    final current = ref.read(devDateTimeOverrideProvider) ?? DateTime.now();
    ref.read(devDateTimeOverrideProvider.notifier).state =
        DateTime(d.year, d.month, d.day, current.hour, current.minute);
  }

  Future<void> _pickDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('he'),
    );
    if (picked == null) return;
    ref.read(devDateTimeOverrideProvider.notifier).state = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current.hour,
      current.minute,
    );
  }

  Future<void> _pickTime(DateTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    ref.read(devDateTimeOverrideProvider.notifier).state = DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );
  }

  String _dateStr(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _longFmt(DateTime dt) => '${_dateStr(dt)}  ${_timeStr(dt)}';
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: onTap,
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PresetGrid extends StatelessWidget {
  const _PresetGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

// ── Dynamic preset-date helpers ──────────────────────────────────────────────
//
// Walks forward day-by-day from today until the predicate matches. Caps at
// 400 days so a buggy predicate can't hang the app. The cap also covers the
// worst-case window (RH 5786 → RH 5787 ≈ 384 days in a leap year).

DateTime _findNext(bool Function(JewishCalendar cal, DateTime d) predicate) {
  var d = DateTime.now();
  for (int i = 0; i < 400; i++) {
    final cal = JewishCalendar.fromDateTime(d);
    if (predicate(cal, d)) return d;
    d = d.add(const Duration(days: 1));
  }
  return DateTime.now();
}

DateTime _findNextRoshChodeshRegular() => _findNext((cal, _) {
      // Regular RC = any RC that isn't RC Tevet (which falls during Chanukah
      // and has composite reading). RC Sivan also "no tachanun" window —
      // pick something more generic to exercise standard RC flow.
      if (!cal.isRoshChodesh()) return false;
      if (cal.isChanukah()) return false;
      final m = cal.getJewishMonth();
      if (m == JewishDate.SIVAN) return false;
      return true;
    });

DateTime _findNextRcTevet() => _findNext((cal, _) {
      // RC Tevet — always during Chanukah, composite Kriah.
      if (!cal.isRoshChodesh()) return false;
      return cal.getJewishMonth() == JewishDate.TEVES;
    });

DateTime _findNextChanukahDay(int day) => _findNext((cal, _) {
      return cal.getDayOfChanukah() == day;
    });

DateTime _findNextOmerDay(int day) => _findNext((cal, _) {
      return cal.getDayOfOmer() == day;
    });

DateTime _findNextCholHamoedPesach() => _findNext((cal, _) {
      return cal.isCholHamoedPesach();
    });

DateTime _findNextCholHamoedSukkot() => _findNext((cal, _) {
      // kosher_dart yom-tov index for chol hamoed sukkot.
      return cal.getYomTovIndex() == JewishCalendar.CHOL_HAMOED_SUCCOS;
    });

DateTime _findNextPurim() => _findNext((cal, _) {
      return cal.getYomTovIndex() == JewishCalendar.PURIM;
    });

DateTime _findNextPublicFast() => _findNext((cal, _) {
      // Any of the four minor fasts (10 Tevet, Tzom Gedalia, Taanit Esther,
      // 17 Tammuz). Excludes Tisha B'Av (separate preset) and Yom Kippur.
      final yt = cal.getYomTovIndex();
      return yt == JewishCalendar.TENTH_OF_TEVES ||
          yt == JewishCalendar.FAST_OF_GEDALYAH ||
          yt == JewishCalendar.FAST_OF_ESTHER ||
          yt == JewishCalendar.SEVENTEEN_OF_TAMMUZ;
    });

DateTime _findNextTishaBav() => _findNext((cal, _) {
      return cal.getYomTovIndex() == JewishCalendar.TISHA_BEAV;
    });

DateTime _findNextRoshHashanah() => _findNext((cal, _) {
      return cal.getYomTovIndex() == JewishCalendar.ROSH_HASHANA;
    });

DateTime _findNextYomKippur() => _findNext((cal, _) {
      return cal.getYomTovIndex() == JewishCalendar.YOM_KIPPUR;
    });
