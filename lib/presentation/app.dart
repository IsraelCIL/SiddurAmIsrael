import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siddur_am_israel_chai/presentation/app_shell.dart';
import 'package:siddur_am_israel_chai/presentation/i18n/app_locale.dart';
import 'package:siddur_am_israel_chai/presentation/i18n/app_strings.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/dev_overlay.dart';

class SmartSiddurApp extends ConsumerWidget {
  const SmartSiddurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Interface language drives the framework chrome's locale & direction.
    // Prayer texts remain Hebrew/RTL regardless (enforced per prayer screen).
    final language = ref.watch(appLanguageEnumProvider);
    return MaterialApp(
      title: 'סידור חכם',
      debugShowCheckedModeBanner: false,
      locale: language.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLanguage.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const DevOverlay(child: AppShell()),
    );
  }
}
