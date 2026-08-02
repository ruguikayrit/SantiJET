import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dokum/dokum_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/kesif/kesif_screen.dart';
import '../../features/program/program_screen.dart';
import '../../features/projects/join_project_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/quality/quality_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Alt sekmeler: Ana Sayfa, Keşif, Sipariş, Döküm, Ayarlar.
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) =>
                    fadePage(key: state.pageKey, child: const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.kesif,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const KesifScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.program,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const ProgramScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dokum,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const DokumScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ayarlar,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'projeler',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const ProjectsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'katil',
                        pageBuilder: (context, state) => fadePage(
                          key: state.pageKey,
                          child: const JoinProjectScreen(),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'kalite',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const QualityScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'hakkinda',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const AboutScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
