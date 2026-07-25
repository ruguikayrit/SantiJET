import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/imalat/imalat_screen.dart';
import '../../features/personnel/personnel_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/puantaj/puantaj_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/verim/verim_screen.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Alt sekmeler: Ana Sayfa, Puantaj, İmalat, Verim, Ayarlar.
/// Personel / Projeler Ayarlar altındadır.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
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
                path: AppRoutes.puantaj,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const PuantajScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.imalat,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const ImalatScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.verim,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const VerimScreen(),
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
                    path: 'personel',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const PersonnelScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'projeler',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const ProjectsScreen(),
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
