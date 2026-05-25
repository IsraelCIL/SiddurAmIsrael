import '../../domain/entities/user_location.dart';

/// Data-layer representation of [UserLocation] with JSON serialisation.
///
/// Extends [UserLocation] so it is accepted everywhere the domain entity
/// is expected. Serialisation keys use snake_case to match the on-disk
/// format stored by SharedPreferences / Isar.
class UserLocationModel extends UserLocation {
  const UserLocationModel({
    required super.latitude,
    required super.longitude,
    required super.timezone,
    required super.displayName,
  });

  /// Deserialises a [UserLocationModel] from a JSON map.
  ///
  /// Expects the keys: `latitude`, `longitude`, `timezone`, `display_name`.
  /// Numeric values are accepted as both [int] and [double] via [num.toDouble].
  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      displayName: json['display_name'] as String,
    );
  }

  /// Serialises this model to a JSON map suitable for local storage.
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'display_name': displayName,
      };

  /// Wraps a domain [UserLocation] in a [UserLocationModel] without copying data.
  factory UserLocationModel.fromDomain(UserLocation location) {
    return UserLocationModel(
      latitude: location.latitude,
      longitude: location.longitude,
      timezone: location.timezone,
      displayName: location.displayName,
    );
  }
}
