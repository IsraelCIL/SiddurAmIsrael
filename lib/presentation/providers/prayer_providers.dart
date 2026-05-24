import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendar/hebrew_date.dart';
import '../../data/datasources/local/prayer_local_datasource.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../../domain/entities/assembled_segment.dart';
import '../../domain/entities/user_context.dart';
import '../../domain/repositories/i_prayer_repository.dart';
import '../../domain/services/halachic_calendar_service.dart';
import '../../domain/services/i_calendar_flag_provider.dart';
import '../../domain/services/i_prayer_assembler.dart';
import '../../domain/services/prayer_assembler.dart';

// ── Infrastructure ───────────────────────────────────────────────────────────

final prayerLocalDatasourceProvider = Provider<PrayerLocalDatasource>(
  (ref) => PrayerLocalDatasource(),
);

final prayerRepositoryProvider = Provider<IPrayerRepository>(
  (ref) => PrayerRepositoryImpl(ref.watch(prayerLocalDatasourceProvider)),
);

final prayerAssemblerProvider = Provider<IPrayerAssembler>(
  (ref) => PrayerAssembler(ref.watch(prayerRepositoryProvider)),
);

final calendarServiceProvider = Provider<ICalendarFlagProvider>(
  (ref) => HalachicCalendarService(),
);

// ── User preferences (mutable state) ────────────────────────────────────────

final nusachProvider = StateProvider<String>((ref) => 'ashkenaz');

final isInIsraelProvider = StateProvider<bool>((ref) => true);

final userGenderProvider = StateProvider<Gender>((ref) => Gender.male);

final fontSizeFactorProvider = StateProvider<double>((ref) => 1.0);

// ── Derived / computed ───────────────────────────────────────────────────────

final hebrewDateProvider = Provider<HebrewDate>(
  (ref) => HebrewDate.fromGregorian(DateTime.now()),
);

final userContextProvider = Provider<UserContext>((ref) {
  final nusach = ref.watch(nusachProvider);
  final isInIsrael = ref.watch(isInIsraelProvider);
  final gender = ref.watch(userGenderProvider);
  final service = ref.watch(calendarServiceProvider);
  final baseCtx = UserContext(nusach: nusach, isInIsrael: isInIsrael, gender: gender);
  final dayFlags = service.flagsFor(DateTime.now(), baseCtx);
  return UserContext(
    nusach: nusach,
    isInIsrael: isInIsrael,
    gender: gender,
    activeFlags: dayFlags.flags,
  );
});

// ── Prayer content ───────────────────────────────────────────────────────────

final minchaProvider = FutureProvider<List<AssembledSegment>>((ref) {
  final assembler = ref.watch(prayerAssemblerProvider);
  final baseCtx = ref.watch(userContextProvider);
  // Inject Mincha-specific flags. tisha_beav is a whole-day flag, but Nachem
  // (and EM's Tisha B'Av chatima) only enter the bracha at Mincha.
  final minchaFlags = <String>{
    ...baseCtx.activeFlags,
    if (baseCtx.activeFlags.contains('tisha_beav')) 'tisha_beav_mincha',
  }.toList();
  final ctx = UserContext(
    nusach: baseCtx.nusach,
    isInIsrael: baseCtx.isInIsrael,
    gender: baseCtx.gender,
    activeFlags: minchaFlags,
  );
  return assembler.assemble(templateId: 'mincha', userContext: ctx);
});
