import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/routing/app_router.dart';
import 'package:santijet_demir/core/responsive/app_safe_area.dart';
import 'package:santijet_demir/core/theme/app_theme.dart';
import 'package:santijet_demir/core/theme/theme_rebuild_gate.dart';
import 'package:santijet_demir/features/auth/app_lock_screen.dart';
import 'package:santijet_demir/features/auth/providers/app_lock_provider.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/auth/session_expired_screen.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class SantijetDemirApp extends ConsumerWidget {
  const SantijetDemirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);
    final lock = ref.watch(appLockProvider);
    final auth = ref.watch(authProvider);
    final themeMode = _themeModeFromSettings(settings.themeMode);
    final modeKey = settings.themeMode;

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
        builder: (context, child) => wrap(child),
        home: const SessionExpiredScreen(),
      );
    }

    if (lock.isEnabled && !lock.isUnlocked) {
      return MaterialApp(
        title: 'ŞantiJET DEMİR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        builder: (context, child) => wrap(child),
        home: const AppLockScreen(),
      );
    }

    return MaterialApp.router(
      title: 'ŞantiJET DEMİR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => wrap(child),
    );
  }

  /// ŞantiJET açık Material chrome; ŞantiJET Pro koyu chrome — kartlar [AppColors.cardSurface].
  ThemeMode _themeModeFromSettings(String mode) => switch (mode) {
        'light' || 'santijet' => ThemeMode.light,
        'dark' || 'santijet_pro' || 'gecejet' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
