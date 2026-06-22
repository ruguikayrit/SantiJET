import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/features/orders/new_order_wizard.dart';
import 'package:santijet_demir/features/orders/orders_screen.dart';
import 'package:santijet_demir/features/shell/main_shell.dart';
import 'package:santijet_demir/features/splash/splash_screen.dart';
import 'package:santijet_demir/features/survey/survey_detail_screen.dart';
import 'package:santijet_demir/features/survey/survey_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.newOrder,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewOrderWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.survey,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SurveyListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SurveyDetailScreen(imalatId: id);
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.incomingRebar,
                builder: (context, state) => const IncomingRebarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.fieldCount,
                builder: (context, state) => const FieldCountScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analysis,
                builder: (context, state) => const AnalysisScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
