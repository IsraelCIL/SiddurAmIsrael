import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper over [SharedPreferences]. All keys are versioned
/// (`v1.*`) so future schema changes can migrate without trampling.
class SettingsLocalDatasource {
  SettingsLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _kNusach = 'v1.settings.nusach';
  static const _kGender = 'v1.settings.gender';
  static const _kIsInIsrael = 'v1.settings.is_in_israel';
  static const _kWithMinyan = 'v1.settings.with_minyan';
  static const _kPurimDate = 'v1.settings.purim_date';
  static const _kFontSize = 'v1.settings.font_size_factor';
  static const _kSeenBanner = 'v1.settings.seen_banner';
  static const _kShowLabels = 'v1.settings.show_labels';

  String? readNusach() => _prefs.getString(_kNusach);
  Future<void> writeNusach(String v) => _prefs.setString(_kNusach, v);

  String? readGender() => _prefs.getString(_kGender);
  Future<void> writeGender(String v) => _prefs.setString(_kGender, v);

  bool? readIsInIsrael() => _prefs.getBool(_kIsInIsrael);
  Future<void> writeIsInIsrael(bool v) => _prefs.setBool(_kIsInIsrael, v);

  bool? readWithMinyan() => _prefs.getBool(_kWithMinyan);
  Future<void> writeWithMinyan(bool v) => _prefs.setBool(_kWithMinyan, v);

  String? readPurimDate() => _prefs.getString(_kPurimDate);
  Future<void> writePurimDate(String v) => _prefs.setString(_kPurimDate, v);

  double? readFontSize() => _prefs.getDouble(_kFontSize);
  Future<void> writeFontSize(double v) => _prefs.setDouble(_kFontSize, v);

  bool? readSeenBanner() => _prefs.getBool(_kSeenBanner);
  Future<void> writeSeenBanner(bool v) => _prefs.setBool(_kSeenBanner, v);

  bool? readShowLabels() => _prefs.getBool(_kShowLabels);
  Future<void> writeShowLabels(bool v) => _prefs.setBool(_kShowLabels, v);
}
