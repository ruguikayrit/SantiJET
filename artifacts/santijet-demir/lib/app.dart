import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/routing/app_router.dart';
import 'package:santijet_demir/core/theme/app_theme.dart';
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

    if (auth.user != null && !auth.isSessionValid) {
      return MaterialApp(
        title: 'ŞantiJET DEMİR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
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
    );
  }

  ThemeMode _themeModeFromSettings(String mode) => switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
