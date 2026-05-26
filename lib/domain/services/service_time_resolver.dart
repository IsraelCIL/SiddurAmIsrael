import 'package:kosher_dart/kosher_dart.dart';

/// Logical service the user would naturally daven at a given moment.
enum PrayerService { shacharit, mincha, maariv }

/// Resolves the current prayer service using halachic zmanim, so the
/// app opens to the right tab year-round (wall-clock buckets drift hours
/// between summer and winter and would land users on the wrong tab).
///
/// Boundaries used:
///   • alotHaShachar = 90 minutes before sunrise (a minute-based opinion;
///     the simplest valid shita and sufficient for tab routing — not
///     intended as a halachic ruling for actually davening Shacharit).
///   • chatzot       = solar transit (mid-day).
///   • shkiyah       = sunset.
///
/// Rules:
///   • [alot, chatzot)    → Shacharit
///   • [chatzot, shkiyah) → Mincha
///   • else (after shkiyah OR before alot, including post-midnight)
///                        → Maariv
///
/// v1 ships with fixed coordinates for central Israel (32.08, 34.78).
/// A future enhancement could let the user override location.
class ServiceTimeResolver {
  const ServiceTimeResolver({
    this.latitude = _defaultLatitude,
    this.longitude = _defaultLongitude,
    this.locationName = _defaultLocationName,
  });

  static const double _defaultLatitude = 32.08;
  static const double _defaultLongitude = 34.78;
  static const String _defaultLocationName = 'Central Israel';

  /// Minutes before sunrise that count as alotHaShachar for routing.
  static const int alotMinutesBeforeSunrise = 90;

  final double latitude;
  final double longitude;
  final String locationName;

  PrayerService currentService(DateTime now) {
    final geo = GeoLocation.setLocation(
      locationName,
      latitude,
      longitude,
      now,
    );
    final cal = ComplexZmanimCalendar.intGeoLocation(geo);
    final sunrise = cal.getSunrise();
    final chatzot = cal.getChatzos();
    final sunset = cal.getSunset();
    if (sunrise == null || chatzot == null || sunset == null) {
      // Polar edge case or computation failure — fall back to Shacharit
      // rather than crash; this won't fire in Israel.
      return PrayerService.shacharit;
    }
    final alot =
        sunrise.subtract(const Duration(minutes: alotMinutesBeforeSunrise));

    // The zmanim are returned for `now`'s date. Compare them in the same
    // local clock; DateTime comparisons are absolute-time, which is what
    // we want here.
    if (now.isBefore(alot)) return PrayerService.maariv; // post-midnight
    if (now.isBefore(chatzot)) return PrayerService.shacharit;
    if (now.isBefore(sunset)) return PrayerService.mincha;
    return PrayerService.maariv;
  }
}
