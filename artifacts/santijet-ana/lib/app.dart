import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_info.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_provider.dart';

/// Uygulama kökü — seçili [ThemeDefinition] ile MaterialApp.router.
class SantijetAnaApp extends ConsumerWidget {
  const SantijetAnaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeDefinitionProvider);

    return MaterialApp.router(
      title: AppInfo.displayName,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.buildThemeData(theme),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
