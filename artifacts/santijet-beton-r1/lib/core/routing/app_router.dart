import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dokum/dokum_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/quality/quality_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/siparis/siparis_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (c, s) =>
                  fadePage(key: s.pageKey, child: const HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.plan,
              pageBuilder: (c, s) =>
                  fadePage(key: s.pageKey, child: const PlanScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dokum,
              pageBuilder: (c, s) =>
                  fadePage(key: s.pageKey, child: const DokumScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.siparis,
              pageBuilder: (c, s) =>
                  fadePage(key: s.pageKey, child: const SiparisScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.ayarlar,
              pageBuilder: (c, s) =>
                  fadePage(key: s.pageKey, child: const SettingsScreen()),
              routes: [
                GoRoute(
                  path: 'projeler',
                  pageBuilder: (c, s) =>
                      fadePage(key: s.pageKey, child: const ProjectsScreen()),
                ),
                GoRoute(
                  path: 'kalite',
                  pageBuilder: (c, s) =>
                      fadePage(key: s.pageKey, child: const QualityScreen()),
                ),
                GoRoute(
                  path: 'hakkinda',
                  pageBuilder: (c, s) =>
                      fadePage(key: s.pageKey, child: const AboutScreen()),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
