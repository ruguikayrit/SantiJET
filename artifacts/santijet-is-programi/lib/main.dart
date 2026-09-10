import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/program_repository.dart';
import 'domain/program_item.dart';
import 'features/form/program_form_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_state.dart';
import 'ui/app_shell.dart';
import 'ui/design_system.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter('isprog_data');
  await Hive.openBox<String>(programBoxName);
  final settings = await Hive.openBox<dynamic>(settingsBoxName);
  await Hive.openBox<dynamic>(licenseBoxName);

  final programBox = Hive.box<String>(programBoxName);
  if (programBox.isEmpty &&
      !(settings.get('demoInitialized', defaultValue: false) as bool)) {
    await ProgramRepository(programBox).replaceWithDemo();
    await settings.put('demoInitialized', true);
  }
  runApp(const ProviderScope(child: SantijetIsProgramiApp()));
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/', builder: (context, state) => const AppShell()),
    GoRoute(
      path: '/form',
      builder: (context, state) =>
          ProgramFormScreen(item: state.extra as ProgramItem?),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class SantijetIsProgramiApp extends ConsumerWidget {
  const SantijetIsProgramiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'ŞantiJET İş Programı',
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ref.watch(themeModeProvider),
    routerConfig: appRouter,
    locale: const Locale('tr', 'TR'),
    supportedLocales: const [Locale('tr', 'TR')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}
