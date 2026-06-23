import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_info.dart';
import '../core/router/app_router.dart';
import '../core/theme/sj_theme.dart';
import '../core/theme/theme_provider.dart';

/// Uygulama kökü — MaterialApp.router + Riverpod ile sağlanan tema ve router.
class SantijetBfaApp extends ConsumerWidget {
  const SantijetBfaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: AppInfo.legalName,
      debugShowCheckedModeBanner: false,
      theme: SJTheme.light(),
      darkTheme: SJTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
