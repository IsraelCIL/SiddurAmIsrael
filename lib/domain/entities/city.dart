/// A location used for zmanim calculation.
///
/// Immutable value object. The canonical offline list lives in
/// `lib/core/data/cities.dart` ([kCities]); the user picks one in Settings.
class City {
  const City({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.candleLightingMinutes,
    required this.inIsrael,
  });

  /// Stable key persisted in settings, e.g. `'jerusalem'`.
  final String id;

  /// Hebrew display name, e.g. `'ירושלים'`.
  final String name;

  final double latitude;
  final double longitude;

  /// Metres above sea level (affects sunrise/sunset slightly).
  final double elevation;

  /// Minutes before sunset for candle lighting.
  /// Halachic decision for this app: 40 in Jerusalem, 20 everywhere else.
  final int candleLightingMinutes;

  /// Whether the city is in Eretz Yisrael — drives one-day vs two-day Yom Tov
  /// and Chol HaMoed length in the calendar.
  final bool inIsrael;
}
