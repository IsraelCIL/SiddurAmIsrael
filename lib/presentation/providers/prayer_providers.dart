import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kosher_dart/kosher_dart.dart';
import 'package:siddur_am_israel_chai/core/calendar/hebrew_date.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/gra_ssy_datasource.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/kriah_datasource.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/omer_mapping_datasource.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/prayer_local_datasource.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/settings_local_datasource.dart';
import 'package:siddur_am_israel_chai/data/datasources/local/sukkot_korbanot_datasource.dart';
import 'package:siddur_am_israel_chai/data/repositories/gra_ssy_repository_impl.dart';
import 'package:siddur_am_israel_chai/data/repositories/kriah_repository_impl.dart';
import 'package:siddur_am_israel_chai/data/repositories/omer_mapping_repository_impl.dart';
import 'package:siddur_am_israel_chai/data/repositories/prayer_repository_impl.dart';
import 'package:siddur_am_israel_chai/data/repositories/settings_repository_impl.dart';
import 'package:siddur_am_israel_chai/data/repositories/sukkot_korbanot_repository_impl.dart';
import 'package:siddur_am_israel_chai/domain/entities/assembled_segment.dart';
import 'package:siddur_am_israel_chai/domain/entities/day_flags.dart';
import 'package:siddur_am_israel_chai/domain/entities/omer_day.dart';
import 'package:siddur_am_israel_chai/domain/entities/user_context.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_gra_ssy_repository.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_kriah_repository.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_omer_mapping_repository.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_prayer_repository.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_settings_repository.dart';
import 'package:siddur_am_israel_chai/domain/repositories/i_sukkot_korbanot_repository.dart';
import 'package:siddur_am_israel_chai/domain/services/halachic_calendar_service.dart';
import 'package:siddur_am_israel_chai/domain/services/i_calendar_flag_provider.dart';
import 'package:siddur_am_israel_chai/domain/services/i_prayer_assembler.dart';
import 'package:siddur_am_israel_chai/domain/services/prayer_assembler.dart';
import 'package:siddur_am_israel_chai/domain/services/service_time_resolver.dart';

// ── Dev date/time override (debug builds only) ───────────────────────────────

/// When non-null (debug builds only), overrides the "current time" used by
/// [hebrewDateProvider], [userContextProvider], and [currentServiceProvider].
/// Set via the dev panel in the Settings screen.
final devDateTimeOverrideProvider = StateProvider<DateTime?>(
  (ref) => null,
  // Wipe the override on every hot-restart so it never pollutes a new session.
);

// Convenience: resolves the effective "now" across all providers.
DateTime _effectiveNow(Ref ref) {
  if (kDebugMode) {
    return ref.watch(devDateTimeOverrideProvider) ?? DateTime.now();
  }
  return DateTime.now();
}

// ── Persistence ──────────────────────────────────────────────────────────────

/// Overridden in main() with the resolved instance, so widgets get it
/// synchronously without async hops.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  ),
);

final settingsLocalDatasourceProvider = Provider<SettingsLocalDatasource>(
  (ref) => SettingsLocalDatasource(ref.watch(sharedPreferencesProvider)),
);

final settingsRepositoryProvider = Provider<ISettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDatasourceProvider)),
);

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

final serviceTimeResolverProvider = Provider<ServiceTimeResolver>(
  (ref) => const ServiceTimeResolver(),
);

// ── User preferences (persistent state) ──────────────────────────────────────

/// Notifier base that loads the initial value from the settings repository
/// and persists each change. Avoids the verbose StateNotifier boilerplate for
/// these simple value holders.
class _PersistentNotifier<T> extends Notifier<T> {
  _PersistentNotifier({required this.read, required this.write});

  final T Function(ISettingsRepository) read;
  final Future<void> Function(ISettingsRepository, T) write;

  @override
  T build() => read(ref.read(settingsRepositoryProvider));

  void set(T value) {
    state = value;
    // Fire-and-forget; SharedPreferences writes are local & fast.
    write(ref.read(settingsRepositoryProvider), value);
  }
}

final nusachProvider = NotifierProvider<_PersistentNotifier<String>, String>(
  () => _PersistentNotifier<String>(
    read: (r) => r.getNusach(),
    write: (r, v) => r.setNusach(v),
  ),
);

final isInIsraelProvider = NotifierProvider<_PersistentNotifier<bool>, bool>(
  () => _PersistentNotifier<bool>(
    read: (r) => r.getIsInIsrael(),
    write: (r, v) => r.setIsInIsrael(v),
  ),
);

final userGenderProvider =
    NotifierProvider<_PersistentNotifier<Gender>, Gender>(
  () => _PersistentNotifier<Gender>(
    read: (r) => r.getGender(),
    write: (r, v) => r.setGender(v),
  ),
);

final withMinyanProvider = NotifierProvider<_PersistentNotifier<bool>, bool>(
  () => _PersistentNotifier<bool>(
    read: (r) => r.getWithMinyan(),
    write: (r, v) => r.setWithMinyan(v),
  ),
);

final purimDateProvider =
    NotifierProvider<_PersistentNotifier<PurimDate>, PurimDate>(
  () => _PersistentNotifier<PurimDate>(
    read: (r) => r.getPurimDate(),
    write: (r, v) => r.setPurimDate(v),
  ),
);

final fontSizeFactorProvider =
    NotifierProvider<_PersistentNotifier<double>, double>(
  () => _PersistentNotifier<double>(
    read: (r) => r.getFontSizeFactor(),
    write: (r, v) => r.setFontSizeFactor(v),
  ),
);

final hasSeenSettingsBannerProvider =
    NotifierProvider<_PersistentNotifier<bool>, bool>(
  () => _PersistentNotifier<bool>(
    read: (r) => r.getHasSeenSettingsBanner(),
    write: (r, v) => r.setHasSeenSettingsBanner(v),
  ),
);

final showSegmentLabelsProvider =
    NotifierProvider<_PersistentNotifier<bool>, bool>(
  () => _PersistentNotifier<bool>(
    read: (r) => r.getShowSegmentLabels(),
    write: (r, v) => r.setShowSegmentLabels(v),
  ),
);

/// Persists which optional segment IDs the user has chosen to keep expanded.
/// Tapping an accordion toggle saves/removes the ID from this set so the
/// choice survives app restarts — stored locally via SharedPreferences.
class _ExpandedSegmentsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      ref.read(settingsRepositoryProvider).getExpandedSegments();

  void toggle(String segmentId) {
    final next = {...state};
    if (next.contains(segmentId)) {
      next.remove(segmentId);
    } else {
      next.add(segmentId);
    }
    state = next;
    ref.read(settingsRepositoryProvider).setExpandedSegments(next);
  }
}

final expandedSegmentsProvider =
    NotifierProvider<_ExpandedSegmentsNotifier, Set<String>>(
  _ExpandedSegmentsNotifier.new,
);

/// Whether the user wears a tallit gadol (default true).
/// Used to inject [DayFlag.wearsTallitGadol] into the Shacharit context for
/// Ashkenaz/Sfard, gating the seder atifat tallit gadol accordion.
final isShaliachTzibburProvider = NotifierProvider<_PersistentNotifier<bool>, bool>(
  () => _PersistentNotifier<bool>(
    read: (r) => r.getIsShaliachTzibbur(),
    write: (r, v) => r.setIsShaliachTzibbur(v),
  ),
);

final einKohanumProvider = NotifierProvider<_PersistentNotifier<bool>, bool>(
  () => _PersistentNotifier<bool>(
    read: (r) => r.getEinKohanim(),
    write: (r, v) => r.setEinKohanim(v),
  ),
);

/// Selected city id for the Hebrew calendar's zmanim (default Jerusalem).
final selectedCityIdProvider =
    NotifierProvider<_PersistentNotifier<String>, String>(
  () => _PersistentNotifier<String>(
    read: (r) => r.getLocationCityId(),
    write: (r, v) => r.setLocationCityId(v),
  ),
);

final wearsTallitGadolProvider = NotifierProvider<_PersistentNotifier<bool>, bool>(
  () => _PersistentNotifier<bool>(
    read: (r) => r.getWearsTallitGadol(),
    write: (r, v) => r.setWearsTallitGadol(v),
  ),
);

// ── Derived / computed ───────────────────────────────────────────────────────

final hebrewDateProvider = Provider<HebrewDate>(
  (ref) => HebrewDate.fromGregorian(_effectiveNow(ref)),
);

final userContextProvider = Provider<UserContext>((ref) {
  final nusach = ref.watch(nusachProvider);
  final isInIsrael = ref.watch(isInIsraelProvider);
  final gender = ref.watch(userGenderProvider);
  final withMinyan = ref.watch(withMinyanProvider);
  final purimDate = ref.watch(purimDateProvider);
  final service = ref.watch(calendarServiceProvider);
  final baseCtx = UserContext(
    nusach: nusach,
    isInIsrael: isInIsrael,
    gender: gender,
    purimDate: purimDate,
    withMinyan: withMinyan,
  );
  final dayFlags = service.flagsFor(_effectiveNow(ref), baseCtx);
  final flags = <String>{
    ...dayFlags.flags,
    if (withMinyan) DayFlag.withMinyan,
  }.toList();
  return UserContext(
    nusach: nusach,
    isInIsrael: isInIsrael,
    gender: gender,
    purimDate: purimDate,
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
/// period.
final currentOmerDayProvider = FutureProvider<OmerDay?>((ref) async {
  final ctx = ref.watch(userContextProvider);
  if (ctx.omerDay == null) return null;
  final repo = ref.watch(omerMappingRepositoryProvider);
  return repo.loadDay(ctx.omerDay!);
});

/// Which prayer service is current right now (by halachic zmanim).
/// Initial tab in the AppShell reads this once on startup.
final currentServiceProvider = Provider<PrayerService>((ref) {
  final resolver = ref.watch(serviceTimeResolverProvider);
  return resolver.currentService(_effectiveNow(ref));
});

// ── Prayer content ───────────────────────────────────────────────────────────

UserContext _ctxWithExtraFlags(UserContext base, Iterable<String> extra) {
  final merged = <String>{...base.activeFlags, ...extra}.toList();
  return UserContext(
    nusach: base.nusach,
    isInIsrael: base.isInIsrael,
    gender: base.gender,
    purimDate: base.purimDate,
    withMinyan: base.withMinyan,
    activeFlags: merged,
    omerDay: base.omerDay,
    sukkotDay: base.sukkotDay,
    pesachDay: base.pesachDay,
    chanukahDay: base.chanukahDay,
    chagYt1Weekday: base.chagYt1Weekday,
    upcomingParshah: base.upcomingParshah,
  );
}

final shacharitProvider = FutureProvider<List<AssembledSegment>>((ref) {
  final assembler = ref.watch(prayerAssemblerProvider);
  final baseCtx = ref.watch(userContextProvider);
  final wearsTallitGadol = ref.watch(wearsTallitGadolProvider);
  final isShaliachTzibbur = ref.watch(isShaliachTzibburProvider);
  final einKohanim = ref.watch(einKohanumProvider);
  final isMale = baseCtx.gender == Gender.male;
  final extra = [
    DayFlag.serviceShacharit,
    // Tallit / shaliach tzibbur flags are male-only — women do not wear a
    // tallit gadol or serve as shaliach tzibbur in Orthodox Halacha.
    if (isMale &&
        wearsTallitGadol &&
        (baseCtx.nusach == 'ashkenaz' || baseCtx.nusach == 'sfard'))
      DayFlag.wearsTallitGadol,
    if (isMale && isShaliachTzibbur) DayFlag.isShaliachTzibbur,
    if (einKohanim) DayFlag.einKohanim,
  ];
  final ctx = _ctxWithExtraFlags(baseCtx, extra);
  return assembler.assemble(
    templateId: 'shacharit_${ctx.nusach}',
    userContext: ctx,
  );
});

final minchaProvider = FutureProvider<List<AssembledSegment>>((ref) {
  final assembler = ref.watch(prayerAssemblerProvider);
  final baseCtx = ref.watch(userContextProvider);
  // Inject Mincha-specific flags. tisha_beav is a whole-day flag, but Nachem
  // (and EM's Tisha B'Av chatima) only enter the bracha at Mincha.
  final ctx = _ctxWithExtraFlags(
    baseCtx,
    [
      DayFlag.serviceMincha,
      if (baseCtx.activeFlags.contains('tisha_beav')) 'tisha_beav_mincha',
    ],
  );
  return assembler.assemble(templateId: 'mincha', userContext: ctx);
});

/// Checks whether any of the Yom Tovim that block Vihi Noam for Ashkenaz/
/// Sfard fall within the next 6 days (Sun–Fri) or on the next Shabbat
/// (+7 days). Returns a record of (onWeekday, onShabbat).
({bool onWeekday, bool onShabbat}) _viHiNoamYomTovCheck(
    DateTime motzaei, bool inIsrael) {
  const blockedMonths = {
    JewishDate.TISHREI: [1, 2, 10, 15, 22], // RH, YK, Sukkot1, SA
    JewishDate.NISSAN: [15, 21],             // Pesach1, Pesach7
  };

  for (var delta = 1; delta <= 7; delta++) {
    final d = motzaei.add(Duration(days: delta));
    final cal = JewishCalendar.fromDateTime(d);
    cal.inIsrael = inIsrael;
    final m = cal.getJewishMonth();
    final day = cal.getJewishDayOfMonth();
    final blocked = blockedMonths[m];
    if (blocked != null && blocked.contains(day)) {
      if (delta == 7) return (onWeekday: false, onShabbat: true); // next Shabbat
      return (onWeekday: true, onShabbat: false); // weekday
    }
  }
  return (onWeekday: false, onShabbat: false);
}

final maarivProvider = FutureProvider<List<AssembledSegment>>((ref) {
  final assembler = ref.watch(prayerAssemblerProvider);
  final baseCtx = ref.watch(userContextProvider);
  final isShabbat = baseCtx.activeFlags.contains(DayFlag.shabbat);
  final extra = <String>[];
  if (isShabbat) {
    extra.add(DayFlag.motzaeiShabbat);
    // For A/S: check if a blocking Yom Tov falls in the next week.
    if (baseCtx.nusach == 'ashkenaz' || baseCtx.nusach == 'sfard') {
      final now = kDebugMode
          ? (ref.read(devDateTimeOverrideProvider) ?? DateTime.now())
          : DateTime.now();
      final check = _viHiNoamYomTovCheck(now, baseCtx.isInIsrael);
      if (check.onWeekday) extra.add(DayFlag.yomTovNextWeek);
      if (check.onShabbat) extra.add('yom_tov_next_shabbat');
    }
  }
  final ctx = extra.isEmpty ? baseCtx : _ctxWithExtraFlags(baseCtx, extra);
  return assembler.assemble(
    templateId: 'maariv_${ctx.nusach}',
    userContext: ctx,
  );
});
