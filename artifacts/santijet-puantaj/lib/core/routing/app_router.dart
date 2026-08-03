import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/imalat/imalat_screen.dart';
import '../../features/personnel/personnel_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/puantaj/puantaj_screen.dart';
import '../../features/settings/catalog_screens.dart';
import '../../features/settings/company_settings_screen.dart';
import '../../features/settings/management_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/verim/verim_screen.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Alt sekmeler: Ana Sayfa, Puantaj, İmalat, Verim, Ayarlar.
/// Yönetim (Personel / Meslekler / Ekipler) ve Projeler Ayarlar altındadır.
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
                    path: 'projeler',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const ProjectsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'hakkinda',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const AboutScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'yonetim',
                    pageBuilder: (context, state) => fadePage(
                      key: state.pageKey,
                      child: const ManagementScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'firma',
                        pageBuilder: (context, state) => fadePage(
                          key: state.pageKey,
                          child: const CompanySettingsScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'personel',
                        pageBuilder: (context, state) => fadePage(
                          key: state.pageKey,
                          child: const PersonnelScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'meslekler',
                        pageBuilder: (context, state) => fadePage(
                          key: state.pageKey,
                          child: const ProfessionsScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'ekipler',
                        pageBuilder: (context, state) => fadePage(
                          key: state.pageKey,
                          child: const TeamsScreen(),
                        ),
                      ),
                    ],
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
