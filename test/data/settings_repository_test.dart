import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/settings_local_datasource.dart';
import 'package:siddur_am_israel_chai/data/repositories/settings_repository_impl.dart';
import 'package:siddur_am_israel_chai/domain/entities/user_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsRepositoryImpl> makeRepo({Map<String, Object>? seed}) async {
    SharedPreferences.setMockInitialValues(seed ?? {});
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepositoryImpl(SettingsLocalDatasource(prefs));
  }

  group('SettingsRepository — defaults', () {
    test('nusach defaults to edot_mizrach', () async {
      final r = await makeRepo();
      expect(r.getNusach(), 'edot_mizrach');
    });

    test('gender defaults to male', () async {
      final r = await makeRepo();
      expect(r.getGender(), Gender.male);
    });

    test('isInIsrael defaults to true', () async {
      final r = await makeRepo();
      expect(r.getIsInIsrael(), isTrue);
    });

    test('withMinyan defaults to true', () async {
      final r = await makeRepo();
      expect(r.getWithMinyan(), isTrue);
    });

    test('purimDate defaults to fourteenth', () async {
      final r = await makeRepo();
      expect(r.getPurimDate(), PurimDate.fourteenth);
    });

    test('fontSizeFactor defaults to 1.0', () async {
      final r = await makeRepo();
      expect(r.getFontSizeFactor(), 1.0);
    });

    test('hasSeenSettingsBanner defaults to false', () async {
      final r = await makeRepo();
      expect(r.getHasSeenSettingsBanner(), isFalse);
    });
  });

  group('SettingsRepository — round-trip', () {
    test('nusach', () async {
      final r = await makeRepo();
      await r.setNusach('edot_mizrach');
      expect(r.getNusach(), 'edot_mizrach');
    });

    test('gender', () async {
      final r = await makeRepo();
      await r.setGender(Gender.female);
      expect(r.getGender(), Gender.female);
    });

    test('isInIsrael', () async {
      final r = await makeRepo();
      await r.setIsInIsrael(false);
      expect(r.getIsInIsrael(), isFalse);
    });

    test('withMinyan', () async {
      final r = await makeRepo();
      await r.setWithMinyan(false);
      expect(r.getWithMinyan(), isFalse);
    });

    test('purimDate', () async {
      final r = await makeRepo();
      await r.setPurimDate(PurimDate.fifteenth);
      expect(r.getPurimDate(), PurimDate.fifteenth);
    });

    test('fontSizeFactor (clamped to 0.6..1.6)', () async {
      final r = await makeRepo();
      await r.setFontSizeFactor(2.5);
      expect(r.getFontSizeFactor(), 1.6);
      await r.setFontSizeFactor(0.1);
      expect(r.getFontSizeFactor(), 0.6);
      await r.setFontSizeFactor(1.1);
      expect(r.getFontSizeFactor(), closeTo(1.1, 0.001));
    });

    test('hasSeenSettingsBanner', () async {
      final r = await makeRepo();
      await r.setHasSeenSettingsBanner(true);
      expect(r.getHasSeenSettingsBanner(), isTrue);
    });
  });

  group('SettingsRepository — corrupt stored value falls back to default', () {
    test('unknown nusach string falls back to ashkenaz default? no — kept raw',
        () async {
      // nusach is a free-form String so an arbitrary value is preserved as-is;
      // the assembler layer surfaces the error if the template doesn't exist.
      final r = await makeRepo(seed: {'v1.settings.nusach': 'garbage'});
      expect(r.getNusach(), 'garbage');
    });

    test('unknown gender string falls back to male', () async {
      final r = await makeRepo(seed: {'v1.settings.gender': 'banana'});
      expect(r.getGender(), Gender.male);
    });

    test('unknown purimDate falls back to fourteenth', () async {
      final r = await makeRepo(seed: {'v1.settings.purim_date': 'sixteenth'});
      expect(r.getPurimDate(), PurimDate.fourteenth);
    });
  });
}
