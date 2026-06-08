import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosher_dart/kosher_dart.dart';

import 'package:siddur_am_israel_chai/core/calendar/hebrew_date.dart';
import 'package:siddur_am_israel_chai/core/utils/hebrew_formatter.dart';
import 'package:siddur_am_israel_chai/domain/entities/calendar_day.dart';
import 'package:siddur_am_israel_chai/presentation/providers/calendar_providers.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';

const _shabbatTint = Color(0xFFEEF6F3);
const _holidayColor = Color(0xFFB23A48);
const _gregMonthNames = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

/// The "לוח" tab: a Hebrew-month grid (today highlighted) with the selected
/// day's full info — holidays, Shabbat/Yom Tov candle-lighting + havdalah, and
/// all zmanim — shown below.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(effectiveCityProvider);
    final anchor = ref.watch(calendarAnchorProvider);
    final selected = ref.watch(calendarSelectedDayProvider);
    final today = calendarToday();

    // ── Displayed Hebrew month derived from the anchor date ──
    final anchorJc = JewishCalendar.fromDateTime(anchor)..inIsrael = city.inIsrael;
    final hebMonth = anchorJc.getJewishMonth();
    final hebYear = anchorJc.getJewishYear();
    final dayOfMonth = anchorJc.getJewishDayOfMonth();
    final daysInMonth = HebrewDate.daysInMonth(hebMonth, hebYear);
    final firstGreg = DateTime(anchor.year, anchor.month, anchor.day, 12)
        .subtract(Duration(days: dayOfMonth - 1));
    final lead = firstGreg.weekday % 7; // Sun(7)->0 … Sat(6)->6

    final monthLabel =
        '${HebrewFormatter.monthName(hebMonth)} ${HebrewFormatter.formatHebrewYear(hebYear)}';

    final cells = <Widget>[
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _buildDayCell(ref, firstGreg.add(Duration(days: d - 1)), d, city.inIsrael,
            today, selected),
    ];

    final info = ref.watch(calendarDayProvider(selected));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('לוח', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('זמני ${city.name}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFBDD7F0))),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _monthNav(context, ref, monthLabel, firstGreg, daysInMonth, anchor),
            const SizedBox(height: 8),
            _weekdayHeader(),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              children: cells,
            ),
            const SizedBox(height: 10),
            _legend(),
            const Divider(height: 28, color: AppColors.border),
            _dayInfo(info),
          ],
        ),
      ),
    );
  }

  // ── Month navigation row ──────────────────────────────────────────────────
  Widget _monthNav(BuildContext context, WidgetRef ref, String label,
      DateTime firstGreg, int daysInMonth, DateTime anchor) {
    void go(DateTime to) => ref.read(calendarAnchorProvider.notifier).state = to;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
          onPressed: () => go(firstGreg.subtract(const Duration(days: 1))),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pickMonthYear(context, ref, anchor),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '$label  ▾',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          onPressed: () => go(firstGreg.add(Duration(days: daysInMonth))),
        ),
      ],
    );
  }

  Future<void> _pickMonthYear(
      BuildContext context, WidgetRef ref, DateTime current) async {
    var month = current.month;
    var year = current.year;
    final nowYear = DateTime.now().year;
    final years = [for (var y = nowYear - 10; y <= nowYear + 10; y++) y];

    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('מעבר לחודש', textAlign: TextAlign.center),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: DropdownButton<int>(
                  value: month,
                  isExpanded: true,
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(value: m, child: Text(_gregMonthNames[m - 1])),
                  ],
                  onChanged: (v) => setLocal(() => month = v ?? month),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: year,
                  isExpanded: true,
                  items: [
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setLocal(() => year = v ?? year),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('ביטול')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, DateTime(year, month, 15, 12)),
              child: const Text('אישור'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      ref.read(calendarAnchorProvider.notifier).state = result;
    }
  }

  Widget _weekdayHeader() {
    const labels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
    return Row(
      children: [
        for (final l in labels)
          Expanded(
            child: Center(
              child: Text(l,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell(WidgetRef ref, DateTime greg, int hebDay, bool inIsrael,
      DateTime today, DateTime selected) {
    final jc = JewishCalendar.fromDateTime(greg)..inIsrael = inIsrael;
    final isShabbat = greg.weekday == DateTime.saturday;
    final isSpecial = jc.isYomTov() ||
        jc.isCholHamoed() ||
        jc.isChanukah() ||
        jc.isRoshChodesh();
    final isToday = _sameDay(greg, today);
    final isSelected = _sameDay(greg, selected);

    final bg = isToday
        ? AppColors.primary
        : (isShabbat ? _shabbatTint : Colors.white);
    final fg = isToday ? Colors.white : AppColors.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ref.read(calendarSelectedDayProvider.notifier).state =
          DateTime(greg.year, greg.month, greg.day, 12),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isSelected && !isToday)
                ? AppColors.primary
                : AppColors.borderLight,
            width: (isSelected && !isToday) ? 1.6 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 2,
              left: 4,
              child: Text('${greg.day}',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: isToday ? 0.7 : 0.32))),
            ),
            Center(
              child: Text(HebrewFormatter.toHebrewNumeral(hebDay),
                  style: TextStyle(
                      fontSize: 14,
                      color: fg,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal)),
            ),
            if (isSpecial)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.white : _holidayColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    Widget item(Color c, String t, {bool border = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: border ? Border.all(color: const Color(0xFF1A6E5A)) : null,
              ),
            ),
            const SizedBox(width: 4),
            Text(t,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      children: [
        item(AppColors.primary, 'היום'),
        item(_shabbatTint, 'שבת', border: true),
        item(_holidayColor, 'חג / מועד'),
      ],
    );
  }

  // ── Selected-day info ───────────────────────────────────────────────────────
  Widget _dayInfo(CalendarDay info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6DE),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info.dayOfWeekLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(info.hebrewDateLabel,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              Text(info.gregorianLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              if (info.parsha != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(info.parsha!,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6E5A))),
                ),
              if (info.tags.isNotEmpty || info.shabbatNotes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in info.tags)
                        _chip(t, const Color(0xFFFBE9EB), _holidayColor),
                      for (final s in info.shabbatNotes)
                        _chip(s, const Color(0xFFECE4F7), const Color(0xFF5B3A86)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (info.shabbatZmanim.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionHeader('🕯️ שבת / חג', const Color(0xFF1A6E5A)),
          _zmanCard(info.shabbatZmanim, tint: const Color(0xFFF4FAF8)),
        ],
        const SizedBox(height: 10),
        _sectionHeader('🕒 זמני היום', AppColors.primary),
        _zmanCard(info.zmanim),
        if (info.extraInfo.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionHeader('📖 מידע נוסף ליום', AppColors.primary),
          _infoCard(info.extraInfo),
        ],
        if (info.upcoming.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionHeader('📅 מועדים קרובים', AppColors.primary),
          _upcomingCard(info.upcoming),
        ],
      ],
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.bold, color: fg)),
      );

  Widget _sectionHeader(String text, Color color) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: color)),
      );

  Widget _zmanCard(List<ZmanEntry> rows, {Color? tint}) {
    return Container(
      decoration: BoxDecoration(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFEEE5D5))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                        children: [
                          TextSpan(text: rows[i].label),
                          if (rows[i].note != null)
                            TextSpan(
                                text: '  (${rows[i].note})',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  Text(_fmtTime(rows[i].time),
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(List<InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFEEE5D5))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(rows[i].label,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.textPrimary)),
                  ),
                  Text(rows[i].value,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _upcomingCard(List<UpcomingEvent> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFEEE5D5))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        children: [
                          TextSpan(text: rows[i].name),
                          TextSpan(
                              text: '  · ${rows[i].hebrewDate}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_daysLabel(rows[i].daysUntil),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _daysLabel(int n) =>
      n == 1 ? 'מחר' : (n == 2 ? 'מחרתיים' : 'עוד $n ימים');

  static String _fmtTime(DateTime? t) => t == null
      ? '—'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
