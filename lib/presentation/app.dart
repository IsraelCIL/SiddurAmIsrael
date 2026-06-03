import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:siddur_am_israel_chai/presentation/app_shell.dart';
import 'package:siddur_am_israel_chai/presentation/theme/app_colors.dart';
import 'package:siddur_am_israel_chai/presentation/widgets/dev_overlay.dart';

class SmartSiddurApp extends ConsumerWidget {
  const SmartSiddurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'סידור חכם',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('he'), Locale('en')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        // Frank Ruhl Libre — traditional Torah-style serif font with full
        // nikud (Hebrew vowel) support. Applied as the global text theme so
        // every Text widget that does not specify an explicit fontFamily
        // inherits this typeface automatically, including all prayer body text.
        //
        // Note for App Store release: bundle the font as a local asset and
        // call GoogleFonts.config.allowRuntimeFetching = false in main() to
        // guarantee offline operation without a network request.
        textTheme: GoogleFonts.frankRuhlLibreTextTheme(
          ThemeData.light().textTheme,
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
