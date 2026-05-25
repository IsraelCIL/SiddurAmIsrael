import '../models/user_location_model.dart';

/// Contract for reading the device's hardware location sensor (GPS/network).
///
/// Implementations must NOT be imported by the domain layer.
/// Inject via [LocationRepository] only.
abstract class LocationDeviceDataSource {
  /// Returns the current device position as a [UserLocationModel].
  ///
  /// **Offline**: hardware positioning is on-device and works without a
  /// network connection when GPS satellites are visible.
  ///
  /// **Permissions**: the implementation is responsible for checking and
  /// requesting OS-level location permissions before accessing the sensor.
  /// Throws when permission is permanently denied so the repository can
  /// surface the error to the caller.
  ///
  /// Throws when:
  /// - Location permission is denied or permanently revoked.
  /// - The sensor cannot obtain a fix within the implementation-defined
  ///   timeout (e.g. indoors, flight mode, sensor hardware failure).
  Future<UserLocationModel> getCurrentLocation();
}
