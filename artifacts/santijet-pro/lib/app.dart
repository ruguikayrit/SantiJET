import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/theme/pro_theme.dart';

class SantijetProApp extends StatelessWidget {
  const SantijetProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ŞantiJET Pro',
      theme: ProTheme.dark,
      routerConfig: appRouter,
    );
  }
}
