import 'package:flutter/widgets.dart';

/// A supported interface language. Affects only the framework UI (tab labels,
/// screen titles, settings) — never the prayer texts, which are always Hebrew.
///
/// [nativeName] is intentionally written in the language itself (the universal
/// convention for language pickers, so any user can recognise their language).
enum AppLanguage {
  hebrew('he', 'עברית', TextDirection.rtl),
  english('en', 'English', TextDirection.ltr),
  russian('ru', 'Русский', TextDirection.ltr),
  french('fr', 'Français', TextDirection.ltr);

  const AppLanguage(this.code, this.nativeName, this.direction);

  /// ISO 639-1 language code, also the SharedPreferences-persisted value.
  final String code;

  /// The language's own endonym, shown in the language picker.
  final String nativeName;

  /// Reading direction for the framework chrome in this language.
  final TextDirection direction;

  Locale get locale => Locale(code);

  /// Resolves a stored code back to an [AppLanguage]; falls back to Hebrew.
  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.hebrew,
      );

  /// Locales advertised to [MaterialApp.supportedLocales].
  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((l) => l.locale).toList(growable: false);
}
