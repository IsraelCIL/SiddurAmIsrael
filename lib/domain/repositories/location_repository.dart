import '../entities/user_location.dart';

/// Contract for all location-related sensing and persistence operations.
///
/// Concrete implementations live in the data layer and are injected at
/// runtime. The domain layer depends only on this abstract interface.
abstract class LocationRepository {
  /// Requests a fresh GPS fix from the device sensor.
  ///
  /// **Offline**: GPS sensing is entirely on-device and requires no network
  /// connection. The call may still fail in environments with poor satellite
  /// visibility (e.g. indoors, underground).
  ///
  /// **Permissions**: when the user has denied location access the
  /// implementation must throw an exception clearly communicating the denial
  /// so that the presentation layer can prompt the user to open Settings.
  /// It must never silently swallow a permission error.
  ///
  /// Throws when:
  /// - Location permission has been denied by the user.
  /// - The device sensor cannot obtain a GPS fix within the allotted time.
  Future<UserLocation> fetchDeviceLocation();

  /// Loads the most recently persisted [UserLocation] from local storage.
  ///
  /// Returns `null` on a fresh install or after the saved location has been
  /// cleared — never throws for the absence of a value.
  ///
  /// **Offline**: reads exclusively from local storage; no network call is
  /// made. If the storage layer itself is unavailable the implementation
  /// should throw rather than return `null`, so the caller can distinguish
  /// "no location saved yet" from "storage error".
  Future<UserLocation?> loadSavedLocation();

  /// Persists [location] to local storage, replacing any previously saved
  /// value.
  ///
  /// **Offline**: writes exclusively to local storage; no network call is
  /// made.
  ///
  /// Throws when the underlying storage layer is unavailable or returns an
  /// error, so callers can surface the failure to the user.
  Future<void> saveLocation(UserLocation location);
}
