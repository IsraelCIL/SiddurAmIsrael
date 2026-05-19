import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_device_datasource.dart';
import '../datasources/location_local_datasource.dart';
import '../models/user_location_model.dart';

/// Concrete implementation of [LocationRepository].
///
/// Resolution order for [fetchDeviceLocation]:
///   1. Live GPS fix via [LocationDeviceDataSource].
///   2. Last persisted location from [LocationLocalDataSource].
///   3. Hard-coded Jerusalem default — ensures the app always has valid
///      zmanim even on first launch with no GPS or saved location.
class LocationRepositoryImpl implements LocationRepository {
  final LocationDeviceDataSource _device;
  final LocationLocalDataSource _local;

  // ירושלים — Halachic default when no device or cached location is available.
  static const UserLocationModel _jerusalemDefault = UserLocationModel(
    latitude: 31.7683,
    longitude: 35.2137,
    timezone: 'Asia/Jerusalem',
    displayName: 'ירושלים',
  );

  const LocationRepositoryImpl({
    required LocationDeviceDataSource device,
    required LocationLocalDataSource local,
  })  : _device = device,
        _local = local;

  /// Attempts a live GPS fix, caches the result on success, and falls back
  /// to the last saved location or [_jerusalemDefault] on any failure.
  ///
  /// Failures include permission denial, sensor unavailability, and timeouts.
  /// Graceful degradation is intentional: the app must always open with valid
  /// zmanim rather than blocking the user behind an error screen.
  @override
  Future<UserLocation> fetchDeviceLocation() async {
    try {
      final model = await _device.getCurrentLocation();
      await _local.cacheLocation(model);
      return model;
    } on Exception {
      final saved = await _local.getCachedLocation();
      return saved ?? _jerusalemDefault;
    }
  }

  @override
  Future<UserLocation?> loadSavedLocation() {
    return _local.getCachedLocation();
  }

  @override
  Future<void> saveLocation(UserLocation location) {
    return _local.cacheLocation(UserLocationModel.fromDomain(location));
  }
}
