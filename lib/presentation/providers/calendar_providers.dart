import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siddur_am_israel_chai/core/data/cities.dart';
import 'package:siddur_am_israel_chai/domain/entities/calendar_day.dart';
import 'package:siddur_am_israel_chai/domain/entities/city.dart';
import 'package:siddur_am_israel_chai/domain/services/calendar_service.dart';
import 'package:siddur_am_israel_chai/presentation/providers/prayer_providers.dart';

/// Today at local noon (stable for date arithmetic).
DateTime calendarToday() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, 12);
}

final calendarDayServiceProvider =
    Provider<CalendarService>((ref) => const CalendarService());

/// The city currently selected for zmanim (from settings; default Jerusalem).
final selectedCityProvider = Provider<City>((ref) {
  final id = ref.watch(selectedCityIdProvider);
  return cityById(id);
});

/// Gregorian date whose Hebrew month is displayed in the grid (default today).
final calendarAnchorProvider = StateProvider<DateTime>((ref) => calendarToday());

/// The day whose full info is shown below the grid (default today).
final calendarSelectedDayProvider =
    StateProvider<DateTime>((ref) => calendarToday());

/// Full info (Hebrew date, holidays, Daf, all zmanim) for a day at the
/// selected city.
final calendarDayProvider = Provider.family<CalendarDay, DateTime>((ref, date) {
  final city = ref.watch(selectedCityProvider);
  return ref.watch(calendarDayServiceProvider).dayFor(date, city);
});
