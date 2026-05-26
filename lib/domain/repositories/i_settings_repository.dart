import '../entities/user_context.dart';

/// Persistent user preferences. Backed by SharedPreferences in production;
/// can be mocked in tests by providing an in-memory implementation.
abstract class ISettingsRepository {
  String getNusach();
  Future<void> setNusach(String value);

  Gender getGender();
  Future<void> setGender(Gender value);

  bool getIsInIsrael();
  Future<void> setIsInIsrael(bool value);

  bool getWithMinyan();
  Future<void> setWithMinyan(bool value);

  PurimDate getPurimDate();
  Future<void> setPurimDate(PurimDate value);

  double getFontSizeFactor();
  Future<void> setFontSizeFactor(double value);

  bool getHasSeenSettingsBanner();
  Future<void> setHasSeenSettingsBanner(bool value);

  bool getShowSegmentLabels();
  Future<void> setShowSegmentLabels(bool value);
}
