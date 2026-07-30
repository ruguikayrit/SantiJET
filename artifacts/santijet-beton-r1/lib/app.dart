import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_info.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/theme_rebuild_gate.dart';

/// ŞantiJET BETON R1 kökü.
class SantijetBetonR1App extends ConsumerWidget {
  const SantijetBetonR1App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final modeKey = ref.watch(themeModeProvider);
    final themeMode = themeModeFromSettings(modeKey);

    return MaterialApp.router(
      title: AppInfo.legalName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => AppColorsThemeSync(
        themeMode: modeKey,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
