import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/hareket_form/hareket_form_screen.dart';
import '../../features/hareketler/hareketler_screen.dart';
import '../../features/kasa/kasa_screen.dart';
import '../../features/rapor/rapor_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Splash → kabuk. Ayarlar / form root navigator.
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
      GoRoute(
        path: AppRoutes.ayarlar,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hareketForm,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return fadePage(
            key: state.pageKey,
            child: HareketFormScreen(hareketId: id),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.kasa,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const KasaScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hareketler,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const HareketlerScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rapor,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const RaporScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
