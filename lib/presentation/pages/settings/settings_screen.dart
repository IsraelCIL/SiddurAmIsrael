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
                  'בָּרוּךְ אַתָּה יְהֹוָה אֱלֹהֵינוּ מֶלֶךְ הָעוֹלָם',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 22 * fontFactor),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
