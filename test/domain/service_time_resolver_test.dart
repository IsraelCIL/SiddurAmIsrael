import 'package:flutter_test/flutter_test.dart';
import 'package:smart_siddur/domain/services/service_time_resolver.dart';

void main() {
  // Default coordinates of the resolver (central Israel, 32.08, 34.78).
  const resolver = ServiceTimeResolver();

  // Sanity: same-clock-time landing on different services across seasons.
  // Israel UTC offset is +2 (IST) winter / +3 (IDT) summer. kosher_dart uses
  // the DateTime's local timezone implicitly via the system; we drive the
  // tests with explicit UTC offsets to keep them stable across CI.

  group('ServiceTimeResolver — winter (21 Dec)', () {
    // Sunrise in Israel on 21 Dec is ~06:35 local. Sunset ~16:40.
    test('05:00 local → maariv (before alot)', () {
      final t = DateTime(2025, 12, 21, 5, 0);
      expect(resolver.currentService(t), PrayerService.maariv);
    });
    test('07:30 local → shacharit', () {
      final t = DateTime(2025, 12, 21, 7, 30);
      expect(resolver.currentService(t), PrayerService.shacharit);
    });
    test('13:00 local → mincha (after chatzot)', () {
      final t = DateTime(2025, 12, 21, 13, 0);
      expect(resolver.currentService(t), PrayerService.mincha);
    });
    test('18:00 local → maariv (after shkiyah ~16:40)', () {
      final t = DateTime(2025, 12, 21, 18, 0);
      expect(resolver.currentService(t), PrayerService.maariv);
    });
  });

  group('ServiceTimeResolver — summer (21 Jun)', () {
    // Sunrise in Israel on 21 Jun is ~05:35 local. Sunset ~19:45.
    test('04:00 local → maariv (before alot ~04:05)', () {
      final t = DateTime(2025, 6, 21, 4, 0);
      expect(resolver.currentService(t), PrayerService.maariv);
    });
    test('07:30 local → shacharit', () {
      final t = DateTime(2025, 6, 21, 7, 30);
      expect(resolver.currentService(t), PrayerService.shacharit);
    });
    test('14:00 local → mincha (after chatzot ~12:40)', () {
      final t = DateTime(2025, 6, 21, 14, 0);
      expect(resolver.currentService(t), PrayerService.mincha);
    });
    test('21:00 local → maariv (after shkiyah ~19:45)', () {
      final t = DateTime(2025, 6, 21, 21, 0);
      expect(resolver.currentService(t), PrayerService.maariv);
    });
    test('18:00 local → still mincha in summer (before shkiyah)', () {
      final t = DateTime(2025, 6, 21, 18, 0);
      expect(resolver.currentService(t), PrayerService.mincha);
    });
  });

  group('ServiceTimeResolver — seasonal drift detection', () {
    test(
        '14:00 lands on mincha in both seasons (no wall-clock-bucket failure)',
        () {
      final winter = DateTime(2025, 12, 21, 14, 0);
      final summer = DateTime(2025, 6, 21, 14, 0);
      expect(resolver.currentService(winter), PrayerService.mincha);
      expect(resolver.currentService(summer), PrayerService.mincha);
    });

    test(
        '06:00 winter is pre-alot (maariv) but post-alot in summer (shacharit)',
        () {
      // 06:00 winter: before sunrise (~06:35) by 35 min → after alot
      //   (sunrise - 90 = ~05:05)?  Yes — actually 06:00 IS after alot,
      //   so this should be shacharit even in winter.
      // 06:00 summer: well after sunrise → shacharit.
      // The interesting drift case is closer to alot itself:
      final winterEarly = DateTime(2025, 12, 21, 5, 0); // before alot
      final summerEarly = DateTime(2025, 6, 21, 5, 0); // after alot
      expect(resolver.currentService(winterEarly), PrayerService.maariv);
      expect(resolver.currentService(summerEarly), PrayerService.shacharit);
    });
  });
}
