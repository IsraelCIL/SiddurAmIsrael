/// An immutable value object representing the user's resolved geographic location.
///
/// All fields are required. Construct via the primary constructor; use
/// [copyWith] to derive a modified copy.
class UserLocation {
  /// Decimal degrees latitude (positive = North, negative = South).
  final double latitude;

  /// Decimal degrees longitude (positive = East, negative = West).
  final double longitude;

  /// IANA time-zone identifier for this coordinate, e.g. `'Asia/Jerusalem'`.
  ///
  /// Used by the Halachic calendar engine to derive local zmanim.
  final String timezone;

  /// Human-readable label shown in the UI, e.g. `'ירושלים'` or `'New York'`.
  final String displayName;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.displayName,
  });

  /// Returns a copy of this location with the specified fields replaced.
  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? timezone,
    String? displayName,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timezone == other.timezone &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(latitude, longitude, timezone, displayName);

  @override
  String toString() =>
      'UserLocation(lat: $latitude, lon: $longitude, tz: $timezone, name: $displayName)';
}
