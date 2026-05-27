import 'package:smart_siddur/domain/entities/day_flags.dart';
import 'package:smart_siddur/domain/entities/user_context.dart';

abstract class ICalendarFlagProvider {
  /// Returns the full set of Halachic flags for [date] given the user's
  /// preferences.  [date] is a Gregorian date (time-of-day is ignored).
  DayFlags flagsFor(DateTime date, UserContext context);
}
