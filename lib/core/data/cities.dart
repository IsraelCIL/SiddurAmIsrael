import 'package:siddur_am_israel_chai/domain/entities/city.dart';

/// Offline list of supported cities for zmanim.
///
/// Candle-lighting is **40 minutes in Jerusalem** and **20 minutes everywhere
/// else** (project Halachic decision). Jerusalem is first so it is the default.
const List<City> kCities = [
  // ── Eretz Yisrael ──
  City(id: 'jerusalem', name: 'ירושלים', latitude: 31.7683, longitude: 35.2137, elevation: 754, candleLightingMinutes: 40, inIsrael: true),
  City(id: 'tel_aviv', name: 'תל אביב', latitude: 32.0853, longitude: 34.7818, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'bnei_brak', name: 'בני ברק', latitude: 32.0807, longitude: 34.8338, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'haifa', name: 'חיפה', latitude: 32.7940, longitude: 34.9896, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'beer_sheva', name: 'באר שבע', latitude: 31.2520, longitude: 34.7915, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'beit_shemesh', name: 'בית שמש', latitude: 31.7457, longitude: 34.9886, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'tzfat', name: 'צפת', latitude: 32.9646, longitude: 35.4960, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'tiberias', name: 'טבריה', latitude: 32.7959, longitude: 35.5300, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'ashdod', name: 'אשדוד', latitude: 31.8040, longitude: 34.6553, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'netanya', name: 'נתניה', latitude: 32.3215, longitude: 34.8532, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'petah_tikva', name: 'פתח תקווה', latitude: 32.0840, longitude: 34.8878, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'beitar', name: 'ביתר עילית', latitude: 31.6997, longitude: 35.1167, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'modiin_illit', name: 'מודיעין עילית', latitude: 31.9320, longitude: 35.0440, elevation: 0, candleLightingMinutes: 20, inIsrael: true),
  City(id: 'elad', name: 'אלעד', latitude: 32.0500, longitude: 34.9500, elevation: 0, candleLightingMinutes: 20, inIsrael: true),

  // ── Diaspora ──
  City(id: 'new_york', name: 'ניו יורק', latitude: 40.7128, longitude: -74.0060, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'lakewood', name: 'לייקווד', latitude: 40.0978, longitude: -74.2179, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'los_angeles', name: 'לוס אנג׳לס', latitude: 34.0522, longitude: -118.2437, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'miami', name: 'מיאמי', latitude: 25.7617, longitude: -80.1918, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'london', name: 'לונדון', latitude: 51.5074, longitude: -0.1278, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'antwerp', name: 'אנטוורפן', latitude: 51.2194, longitude: 4.4025, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'paris', name: 'פריז', latitude: 48.8566, longitude: 2.3522, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'montreal', name: 'מונטריאול', latitude: 45.5017, longitude: -73.5673, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
  City(id: 'toronto', name: 'טורונטו', latitude: 43.6532, longitude: -79.3832, elevation: 0, candleLightingMinutes: 20, inIsrael: false),
];

/// Default city when none is chosen yet (Jerusalem).
final City kDefaultCity = kCities.first;

/// Looks up a city by [id], falling back to [kDefaultCity].
City cityById(String id) =>
    kCities.firstWhere((c) => c.id == id, orElse: () => kDefaultCity);
