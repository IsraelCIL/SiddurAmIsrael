import 'package:geolocator/geolocator.dart';

import 'package:siddur_am_israel_chai/domain/entities/city.dart';

/// Resolves the device's current GPS location into a [City] for zmanim.
///
/// Location is used **on-device only** (never stored or transmitted). Returns
/// `null` when location services are off or permission is denied, so callers
/// can fall back to the user's fixed city.
class LocationDatasource {
  const LocationDatasource();

  Future<City?> currentCity() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null) return null;

    final elev = pos.altitude.isFinite ? pos.altitude : 0.0;
    return _cityFrom(pos.latitude, pos.longitude, elev);
  }

  /// Builds a [City] from raw coordinates. Candle-lighting is 40 minutes only
  /// near Jerusalem, 20 elsewhere (per the project Halachic decision).
  City _cityFrom(double lat, double lng, double elevation) {
    final inIsrael =
        lat >= 29.4 && lat <= 33.4 && lng >= 34.2 && lng <= 35.95;
    final nearJerusalem =
        (lat - 31.778).abs() < 0.12 && (lng - 35.2137).abs() < 0.15;
    return City(
      id: 'gps',
      name: 'מיקום נוכחי',
      latitude: lat,
      longitude: lng,
      elevation: elevation,
      candleLightingMinutes: nearJerusalem ? 40 : 20,
      inIsrael: inIsrael,
    );
  }
}
