import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_info.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_rebuild_gate.dart';
import 'data/daily_crew_repository.dart';
import 'data/program_repository.dart';
import 'data/project_repository.dart';
import 'domain/program_item.dart';
import 'features/form/program_form_screen.dart';
import 'features/interop/transfer_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/account_screen.dart';
import 'features/settings/app_intro_screen.dart';
import 'features/settings/projects_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/work_code_screen.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_state.dart';
import 'ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter('isprog_data');
  await Hive.openBox<String>(programBoxName);
  final settings = await Hive.openBox<dynamic>(settingsBoxName);
  await Hive.openBox<dynamic>(licenseBoxName);
  await Hive.openBox<String>(dailyCrewBoxName);
  final projects = await Hive.openBox<String>(projectBoxName);

  final programBox = Hive.box<String>(programBoxName);
  final crewBox = Hive.box<String>(dailyCrewBoxName);
  if (programBox.isEmpty &&
      !(settings.get('demoInitialized', defaultValue: false) as bool)) {
    final repository = ProgramRepository(programBox);
    await repository.replaceWithDemo();
    final crew = DailyCrewRepository(crewBox);
    await crew.clear();
    for (final entry in demoDailyCrew(
      repository.readAll(),
      today: DateTime.now(),
    )) {
      await crew.save(entry);
    }
    await settings.put('demoInitialized', true);
  }
  final projectRepo = ProjectRepository(projects);
  if (projectRepo.readAll().isEmpty) {
    final names = ProgramRepository(programBox).readAll().map((item) => item.santiyeId);
    final created = await projectRepo.migrateFromSiteNames(names);
    final preferred = settings.get('defaultSite') as String?;
    final active = created.where((project) => project.name == preferred).firstOrNull ??
        created.firstOrNull;
    if (active != null) await settings.put('activeProjectId', active.id);
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
      path: '/aktar',
      builder: (context, state) => const TransferScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/hesap',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/settings/is-kodu',
      builder: (context, state) => const WorkCodeScreen(),
    ),
    GoRoute(
      path: '/settings/projeler',
      builder: (context, state) => const ProjectsScreen(),
    ),
    GoRoute(
      path: '/settings/tanitim',
      builder: (context, state) => const AppIntroScreen(),
    ),
    GoRoute(
      path: '/settings/hakkinda',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);

class SantijetIsProgramiApp extends ConsumerWidget {
  const SantijetIsProgramiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeKey = ref.watch(themeModeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppInfo.legalName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeModeFromSettings(modeKey),
      routerConfig: appRouter,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AppColorsThemeSync(
        themeMode: modeKey,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
