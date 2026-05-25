import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendar/hebrew_date.dart';
import '../../domain/entities/day_flags.dart';
import '../../data/datasources/local/gra_ssy_datasource.dart';
import '../../data/datasources/local/kriah_datasource.dart';
import '../../data/datasources/local/omer_mapping_datasource.dart';
import '../../data/datasources/local/prayer_local_datasource.dart';
import '../../data/datasources/local/sukkot_korbanot_datasource.dart';
import '../../data/repositories/gra_ssy_repository_impl.dart';
import '../../data/repositories/kriah_repository_impl.dart';
import '../../data/repositories/omer_mapping_repository_impl.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../../data/repositories/sukkot_korbanot_repository_impl.dart';
import '../../domain/entities/assembled_segment.dart';
import '../../domain/entities/omer_day.dart';
import '../../domain/entities/user_context.dart';
import '../../domain/repositories/i_gra_ssy_repository.dart';
import '../../domain/repositories/i_kriah_repository.dart';
import '../../domain/repositories/i_omer_mapping_repository.dart';
import '../../domain/repositories/i_prayer_repository.dart';
import '../../domain/repositories/i_sukkot_korbanot_repository.dart';
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

final omerMappingDatasourceProvider = Provider<OmerMappingDatasource>(
  (ref) => OmerMappingDatasource(),
);

final omerMappingRepositoryProvider = Provider<IOmerMappingRepository>(
  (ref) => OmerMappingRepositoryImpl(ref.watch(omerMappingDatasourceProvider)),
);

final sukkotKorbanotDatasourceProvider = Provider<SukkotKorbanotDatasource>(
  (ref) => SukkotKorbanotDatasource(),
);

final sukkotKorbanotRepositoryProvider = Provider<ISukkotKorbanotRepository>(
  (ref) => SukkotKorbanotRepositoryImpl(ref.watch(sukkotKorbanotDatasourceProvider)),
);

final graSsyDatasourceProvider = Provider<GraSsyDatasource>(
  (ref) => GraSsyDatasource(),
);

final graSsyRepositoryProvider = Provider<IGraSsyRepository>(
  (ref) => GraSsyRepositoryImpl(ref.watch(graSsyDatasourceProvider)),
);

final kriahDatasourceProvider = Provider<KriahDatasource>(
  (ref) => KriahDatasource(),
);

final kriahRepositoryProvider = Provider<IKriahRepository>(
  (ref) => KriahRepositoryImpl(ref.watch(kriahDatasourceProvider)),
);

final prayerAssemblerProvider = Provider<IPrayerAssembler>(
  (ref) => PrayerAssembler(
    ref.watch(prayerRepositoryProvider),
    omerRepository: ref.watch(omerMappingRepositoryProvider),
    sukkotRepository: ref.watch(sukkotKorbanotRepositoryProvider),
    graSsyRepository: ref.watch(graSsyRepositoryProvider),
    kriahRepository: ref.watch(kriahRepositoryProvider),
  ),
);

final calendarServiceProvider = Provider<ICalendarFlagProvider>(
  (ref) => HalachicCalendarService(),
);

// ── User preferences (mutable state) ────────────────────────────────────────

final nusachProvider = StateProvider<String>((ref) => 'ashkenaz');

final isInIsraelProvider = StateProvider<bool>((ref) => true);

final userGenderProvider = StateProvider<Gender>((ref) => Gender.male);

final fontSizeFactorProvider = StateProvider<double>((ref) => 1.0);

// Default true: most users daven b'tzibur. Toggle off for b'yechidut, which
// hides Kaddish / Chazarat HaShatz / Kriat HaTorah / Barchu / Yud-Gimel Middot.
final withMinyanProvider = StateProvider<bool>((ref) => true);

// ── Derived / computed ───────────────────────────────────────────────────────

final hebrewDateProvider = Provider<HebrewDate>(
  (ref) => HebrewDate.fromGregorian(DateTime.now()),
);

final userContextProvider = Provider<UserContext>((ref) {
  final nusach = ref.watch(nusachProvider);
  final isInIsrael = ref.watch(isInIsraelProvider);
  final gender = ref.watch(userGenderProvider);
  final withMinyan = ref.watch(withMinyanProvider);
  final service = ref.watch(calendarServiceProvider);
  final baseCtx = UserContext(
    nusach: nusach,
    isInIsrael: isInIsrael,
    gender: gender,
    withMinyan: withMinyan,
  );
  final dayFlags = service.flagsFor(DateTime.now(), baseCtx);
  final flags = <String>{
    ...dayFlags.flags,
    if (withMinyan) DayFlag.withMinyan,
  }.toList();
  return UserContext(
    nusach: nusach,
    isInIsrael: isInIsrael,
    gender: gender,
    withMinyan: withMinyan,
    activeFlags: flags,
    omerDay: dayFlags.omerDay,
    sukkotDay: dayFlags.sukkotDay,
    pesachDay: dayFlags.pesachDay,
    chanukahDay: dayFlags.chanukahDay,
    chagYt1Weekday: dayFlags.chagYt1Weekday,
    upcomingParshah: dayFlags.upcomingParshah,
  );
});

/// Resolves the current day's [OmerDay] entry, or null when not in the omer
/// period. Consumed by widgets that display the per-day sefira / Ana BeKoach
/// word / Lamenatzeach word / Yismechu letter alongside the count.
final currentOmerDayProvider = FutureProvider<OmerDay?>((ref) async {
  final ctx = ref.watch(userContextProvider);
  if (ctx.omerDay == null) return null;
  final repo = ref.watch(omerMappingRepositoryProvider);
  return repo.loadDay(ctx.omerDay!);
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
    withMinyan: baseCtx.withMinyan,
    activeFlags: minchaFlags,
    omerDay: baseCtx.omerDay,
    sukkotDay: baseCtx.sukkotDay,
    pesachDay: baseCtx.pesachDay,
    chanukahDay: baseCtx.chanukahDay,
    chagYt1Weekday: baseCtx.chagYt1Weekday,
    upcomingParshah: baseCtx.upcomingParshah,
  );
  return assembler.assemble(templateId: 'mincha', userContext: ctx);
});
