import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_siddur/data/datasources/location_device_datasource.dart';
import 'package:smart_siddur/data/datasources/location_local_datasource.dart';
import 'package:smart_siddur/data/models/user_location_model.dart';
import 'package:smart_siddur/data/repositories/location_repository_impl.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class _MockDevice extends Mock implements LocationDeviceDataSource {}

class _MockLocal extends Mock implements LocationLocalDataSource {}

// ── Fixtures ───────────────────────────────────────────────────────────────

const _telAviv = UserLocationModel(
  latitude: 32.0853,
  longitude: 34.7818,
  timezone: 'Asia/Jerusalem',
  displayName: 'תל אביב',
);

const _jerusalem = UserLocationModel(
  latitude: 31.7683,
  longitude: 35.2137,
  timezone: 'Asia/Jerusalem',
  displayName: 'ירושלים',
);

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late _MockDevice mockDevice;
  late _MockLocal mockLocal;
  late LocationRepositoryImpl sut;

  setUpAll(() {
    // Required by mocktail for any() matchers on custom types.
    registerFallbackValue(
      const UserLocationModel(
        latitude: 0,
        longitude: 0,
        timezone: 'UTC',
        displayName: '',
      ),
    );
  });

  setUp(() {
    mockDevice = _MockDevice();
    mockLocal = _MockLocal();
    sut = LocationRepositoryImpl(device: mockDevice, local: mockLocal);
  });

  group('LocationRepositoryImpl', () {
    // ── fetchDeviceLocation ──────────────────────────────────────────────

    group('fetchDeviceLocation — GPS מצליח', () {
      setUp(() {
        when(() => mockDevice.getCurrentLocation())
            .thenAnswer((_) async => _telAviv);
        when(() => mockLocal.cacheLocation(any()))
            .thenAnswer((_) async {});
      });

      test('מחזיר את מיקום המכשיר', () async {
        final result = await sut.fetchDeviceLocation();
        expect(result, equals(_telAviv));
      });

      test('שומר את המיקום באחסון המקומי', () async {
        await sut.fetchDeviceLocation();
        verify(() => mockLocal.cacheLocation(_telAviv)).called(1);
      });
    });

    group('fetchDeviceLocation — GPS נכשל, יש מיקום שמור', () {
      setUp(() {
        when(() => mockDevice.getCurrentLocation())
            .thenThrow(Exception('permission denied'));
        when(() => mockLocal.getCachedLocation())
            .thenAnswer((_) async => _jerusalem);
      });

      test('מחזיר את המיקום השמור ללא זריקת חריגה', () async {
        expect(await sut.fetchDeviceLocation(), equals(_jerusalem));
      });

      test('אינו מנסה לשמור במהלך ה-Fallback', () async {
        await sut.fetchDeviceLocation();
        verifyNever(() => mockLocal.cacheLocation(any()));
      });
    });

    group('fetchDeviceLocation — GPS נכשל, אין מיקום שמור (הפעלה ראשונה)', () {
      setUp(() {
        when(() => mockDevice.getCurrentLocation())
            .thenThrow(Exception('sensor unavailable'));
        when(() => mockLocal.getCachedLocation())
            .thenAnswer((_) async => null);
      });

      test('מחזיר את ירושלים כברירת מחדל הלכתית', () async {
        final result = await sut.fetchDeviceLocation();

        expect(result.timezone, equals('Asia/Jerusalem'));
        expect(result.displayName, equals('ירושלים'));
        expect(result.latitude, closeTo(31.7683, 0.001));
        expect(result.longitude, closeTo(35.2137, 0.001));
      });
    });

    // ── loadSavedLocation ────────────────────────────────────────────────

    group('loadSavedLocation', () {
      test('מחזיר מיקום כאשר קיים בדיסק', () async {
        when(() => mockLocal.getCachedLocation())
            .thenAnswer((_) async => _jerusalem);

        expect(await sut.loadSavedLocation(), equals(_jerusalem));
      });

      test('מחזיר null כאשר אין מיקום שמור', () async {
        when(() => mockLocal.getCachedLocation())
            .thenAnswer((_) async => null);

        expect(await sut.loadSavedLocation(), isNull);
      });
    });

    // ── saveLocation ─────────────────────────────────────────────────────

    group('saveLocation', () {
      test('מעביר את המיקום ל-DataSource המקומי כ-Model', () async {
        when(() => mockLocal.cacheLocation(any()))
            .thenAnswer((_) async {});

        await sut.saveLocation(_telAviv);

        verify(() => mockLocal.cacheLocation(_telAviv)).called(1);
      });
    });
  });
}
