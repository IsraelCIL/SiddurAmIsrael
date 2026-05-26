import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_context.dart';
import '../../providers/prayer_providers.dart';

/// User preferences screen. Every change writes through to
/// SharedPreferences immediately via the persistent providers.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nusach = ref.watch(nusachProvider);
    final gender = ref.watch(userGenderProvider);
    final inIsrael = ref.watch(isInIsraelProvider);
    final withMinyan = ref.watch(withMinyanProvider);
    final purimDate = ref.watch(purimDateProvider);
    final fontFactor = ref.watch(fontSizeFactorProvider);
    final showLabels = ref.watch(showSegmentLabelsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF8F0),
        appBar: AppBar(
          title: const Text('הגדרות',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFF8B1A1A),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: ListView(
          children: [
            _SectionHeader(title: 'נוסח התפילה'),
            RadioListTile<String>(
              value: 'ashkenaz',
              groupValue: nusach,
              title: const Text('אשכנז'),
              onChanged: (v) =>
                  ref.read(nusachProvider.notifier).set(v ?? 'ashkenaz'),
            ),
            RadioListTile<String>(
              value: 'sfard',
              groupValue: nusach,
              title: const Text('ספרד'),
              onChanged: (v) =>
                  ref.read(nusachProvider.notifier).set(v ?? 'sfard'),
            ),
            RadioListTile<String>(
              value: 'edot_mizrach',
              groupValue: nusach,
              title: const Text('עדות המזרח'),
              onChanged: (v) => ref
                  .read(nusachProvider.notifier)
                  .set(v ?? 'edot_mizrach'),
            ),

            _SectionHeader(title: 'מתפלל/ת'),
            RadioListTile<Gender>(
              value: Gender.male,
              groupValue: gender,
              title: const Text('זכר'),
              onChanged: (v) => ref
                  .read(userGenderProvider.notifier)
                  .set(v ?? Gender.male),
            ),
            RadioListTile<Gender>(
              value: Gender.female,
              groupValue: gender,
              title: const Text('נקבה'),
              onChanged: (v) => ref
                  .read(userGenderProvider.notifier)
                  .set(v ?? Gender.female),
            ),

            _SectionHeader(title: 'מיקום'),
            SwitchListTile(
              title: const Text('אני בארץ ישראל'),
              subtitle: const Text(
                'משפיע על מספר ימי החגים, אמירת מוסף ועוד',
                style: TextStyle(fontSize: 12),
              ),
              value: inIsrael,
              onChanged: (v) =>
                  ref.read(isInIsraelProvider.notifier).set(v),
            ),

            _SectionHeader(title: 'תפילה'),
            SwitchListTile(
              title: const Text('מתפלל במניין'),
              subtitle: const Text(
                'מציג קדיש, חזרת הש״ץ, קריאת התורה, ברכו ויג מידות',
                style: TextStyle(fontSize: 12),
              ),
              value: withMinyan,
              onChanged: (v) =>
                  ref.read(withMinyanProvider.notifier).set(v),
            ),

            _SectionHeader(title: 'פורים'),
            RadioListTile<PurimDate>(
              value: PurimDate.fourteenth,
              groupValue: purimDate,
              title: const Text('י״ד אדר (פרזים)'),
              onChanged: (v) => ref
                  .read(purimDateProvider.notifier)
                  .set(v ?? PurimDate.fourteenth),
            ),
            RadioListTile<PurimDate>(
              value: PurimDate.fifteenth,
              groupValue: purimDate,
              title: const Text('ט״ו אדר (מוקפין — ירושלים)'),
              onChanged: (v) => ref
                  .read(purimDateProvider.notifier)
                  .set(v ?? PurimDate.fifteenth),
            ),
            RadioListTile<PurimDate>(
              value: PurimDate.both,
              groupValue: purimDate,
              title: const Text('שני הימים (מסופק)'),
              onChanged: (v) => ref
                  .read(purimDateProvider.notifier)
                  .set(v ?? PurimDate.both),
            ),

            _SectionHeader(title: 'תצוגה'),
            SwitchListTile(
              title: const Text('הצג כותרות קטעים'),
              subtitle: const Text(
                'מציג כותרת לכל קטע תפילה (אבות, גבורות וכד׳)',
                style: TextStyle(fontSize: 12),
              ),
              value: showLabels,
              onChanged: (v) =>
                  ref.read(showSegmentLabelsProvider.notifier).set(v),
            ),

            _SectionHeader(title: 'גודל גופן'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('א', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: fontFactor,
                      min: 0.6,
                      max: 1.6,
                      divisions: 10,
                      label: '${(fontFactor * 100).round()}%',
                      activeColor: const Color(0xFF8B1A1A),
                      onChanged: (v) => ref
                          .read(fontSizeFactorProvider.notifier)
                          .set(v),
                    ),
                  ),
                  const Text('א', style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0D5C5)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Text(
                  'מוֹדֶה אֲנִי לְפָנֶיךָ מֶלֶךְ חַי וְקַיָּם שֶׁהֶחֱזַרְתָּ בִּי נִשְׁמָתִי בְּחֶמְלָה רַבָּה אֱמוּנָתֶךָ:',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 22 * fontFactor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (kDebugMode) _DevDateTimePanel(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DevDateTimePanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(devDateTimeOverrideProvider);
    final displayDt = override ?? DateTime.now();

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: displayDt,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        locale: const Locale('he'),
      );
      if (picked == null) return;
      ref.read(devDateTimeOverrideProvider.notifier).state = DateTime(
        picked.year, picked.month, picked.day,
        displayDt.hour, displayDt.minute,
      );
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: displayDt.hour, minute: displayDt.minute),
      );
      if (picked == null) return;
      ref.read(devDateTimeOverrideProvider.notifier).state = DateTime(
        displayDt.year, displayDt.month, displayDt.day,
        picked.hour, picked.minute,
      );
    }

    final dateStr = '${displayDt.day.toString().padLeft(2, '0')}/'
        '${displayDt.month.toString().padLeft(2, '0')}/'
        '${displayDt.year}';
    final timeStr = '${displayDt.hour.toString().padLeft(2, '0')}:'
        '${displayDt.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFE0D5C5)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(
            children: const [
              Icon(Icons.bug_report, size: 16, color: Color(0xFF8B1A1A)),
              SizedBox(width: 6),
              Text(
                'כלי פיתוח — תאריך ושעה',
                style: TextStyle(
                  color: Color(0xFF8B1A1A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            override == null ? 'זמן אמיתי (ללא דריסה)' : 'דריסה פעילה',
            style: TextStyle(
              fontSize: 12,
              color: override == null
                  ? Colors.grey
                  : const Color(0xFF8B1A1A),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dateStr),
                onPressed: pickDate,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(timeStr),
                onPressed: pickTime,
              ),
              if (override != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('איפוס'),
                  onPressed: () =>
                      ref.read(devDateTimeOverrideProvider.notifier).state = null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8B1A1A),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
