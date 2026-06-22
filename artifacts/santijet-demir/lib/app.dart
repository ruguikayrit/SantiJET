import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/routing/app_router.dart';
import 'package:santijet_demir/core/theme/app_theme.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class SantijetDemirApp extends ConsumerWidget {
  const SantijetDemirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ŞantiJET DEMİR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeModeFromSettings(settings.themeMode),
      routerConfig: router,
    );
  }

  ThemeMode _themeModeFromSettings(String mode) => switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
