import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/routing/app_router.dart';
import 'package:santijet_demir/core/responsive/app_safe_area.dart';
import 'package:santijet_demir/core/theme/app_theme.dart';
import 'package:santijet_demir/core/theme/theme_rebuild_gate.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/auth/session_expired_screen.dart';
import 'package:santijet_demir/domain/entities/app_settings.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

const _appLocalizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _appSupportedLocales = [
  Locale('tr', 'TR'),
  Locale('en', 'US'),
];

class SantijetDemirApp extends ConsumerWidget {
  const SantijetDemirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);
    final auth = ref.watch(authProvider);
    final modeKey = AppSettings.normalizeThemeMode(settings.themeMode);
    final themeMode = _themeModeFromSettings(modeKey);

    Widget wrap(Widget? child) => AppMediaQuery(
          child: AppColorsThemeSync(
            themeMode: modeKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );

    if (auth.user != null && !auth.isSessionValid) {
      return MaterialApp(
        title: 'ŞantiJET DEMİR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: const Locale('tr', 'TR'),
        localizationsDelegates: _appLocalizationsDelegates,
        supportedLocales: _appSupportedLocales,
        builder: (context, child) => wrap(child),
        home: const SessionExpiredScreen(),
      );
    }

    return MaterialApp.router(
      title: 'ŞantiJET DEMİR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: _appLocalizationsDelegates,
      supportedLocales: _appSupportedLocales,
      routerConfig: router,
      builder: (context, child) => wrap(child),
    );
  }

  /// Açık ve Koyu, Material teması ile [AppColors] paletini aynı moda bağlar.
  ThemeMode _themeModeFromSettings(String mode) => switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
