import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_siddur/domain/entities/user_context.dart';
import 'package:smart_siddur/presentation/providers/prayer_providers.dart';

void main() {
  group('prayer providers — defaults', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('nusachProvider defaults to ashkenaz', () {
      expect(container.read(nusachProvider), 'ashkenaz');
    });

    test('isInIsraelProvider defaults to true', () {
      expect(container.read(isInIsraelProvider), isTrue);
    });

    test('userGenderProvider defaults to male', () {
      expect(container.read(userGenderProvider), Gender.male);
    });

    test('fontSizeFactorProvider defaults to 1.0', () {
      expect(container.read(fontSizeFactorProvider), 1.0);
    });

    test('hebrewDateProvider returns a plausible Hebrew year', () {
      final date = container.read(hebrewDateProvider);
      expect(date.year, greaterThan(5780));
      expect(date.month, inInclusiveRange(1, 13));
      expect(date.day, inInclusiveRange(1, 30));
    });
  });

  group('userContextProvider — reactivity', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('reflects default nusach', () {
      final ctx = container.read(userContextProvider);
      expect(ctx.nusach, 'ashkenaz');
    });

    test('reflects updated nusach', () {
      container.read(nusachProvider.notifier).state = 'sfard';
      final ctx = container.read(userContextProvider);
      expect(ctx.nusach, 'sfard');
    });

    test('reflects updated isInIsrael', () {
      container.read(isInIsraelProvider.notifier).state = false;
      final ctx = container.read(userContextProvider);
      expect(ctx.isInIsrael, isFalse);
    });

    test('reflects updated gender', () {
      container.read(userGenderProvider.notifier).state = Gender.female;
      final ctx = container.read(userContextProvider);
      expect(ctx.gender, Gender.female);
    });
  });

  group('fontSizeFactorProvider — mutation', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('can be incremented', () {
      container.read(fontSizeFactorProvider.notifier).state = 1.2;
      expect(container.read(fontSizeFactorProvider), closeTo(1.2, 0.001));
    });

    test('can be decremented', () {
      container.read(fontSizeFactorProvider.notifier).state = 0.8;
      expect(container.read(fontSizeFactorProvider), closeTo(0.8, 0.001));
    });
  });
}
