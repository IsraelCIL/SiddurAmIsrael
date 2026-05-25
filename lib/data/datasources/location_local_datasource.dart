import '../models/user_location_model.dart';

/// Contract for reading and writing a persisted [UserLocationModel] to disk.
///
/// Implementations may use SharedPreferences, Isar, or any other local
/// store — callers are shielded from the choice by this interface.
abstract class LocationLocalDataSource {
  /// Reads the most recently cached location from disk.
  ///
  /// Returns `null` when no location has been persisted yet (fresh install
  /// or after [clearCachedLocation]). Never throws for an absent value.
  ///
  /// **Offline**: reads only from local storage; no network access.
  /// Throws when the storage layer itself is unavailable or the stored
  /// data is corrupt and cannot be deserialised.
  Future<UserLocationModel?> getCachedLocation();

  /// Writes [location] to disk, replacing any previously stored value.
  ///
  /// **Offline**: writes only to local storage; no network access.
  /// Throws when the storage layer is unavailable or the write fails.
  Future<void> cacheLocation(UserLocationModel location);

  /// Removes the persisted location from disk.
  ///
  /// After this call, [getCachedLocation] returns `null` until a new
  /// location is cached. Does not throw if no location was stored.
  Future<void> clearCachedLocation();
}
