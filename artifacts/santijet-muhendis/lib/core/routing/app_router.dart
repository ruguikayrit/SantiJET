import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/connection/connection_calc_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// ŞantiJET Mühendis yönlendiricisi — splash → birleşim hesabı.
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
        path: AppRoutes.home,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const ConnectionCalcScreen(),
        ),
      ),
    ],
  );
});
