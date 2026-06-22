import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/features/analysis/analysis_screen.dart';
import 'package:santijet_demir/features/analysis/performance_analysis_screen.dart';
import 'package:santijet_demir/features/field_count/count_detail_screen.dart';
import 'package:santijet_demir/features/field_count/field_count_screen.dart';
import 'package:santijet_demir/features/field_count/new_count_screen.dart';
import 'package:santijet_demir/features/field_count/reconciliation_screen.dart';
import 'package:santijet_demir/features/incoming_rebar/delivery_detail_screen.dart';
import 'package:santijet_demir/features/incoming_rebar/delivery_list_screen.dart';
import 'package:santijet_demir/features/incoming_rebar/incoming_rebar_screen.dart';
import 'package:santijet_demir/features/incoming_rebar/new_delivery_screen.dart';
import 'package:santijet_demir/features/incoming_rebar/supplier_performance_screen.dart';
import 'package:santijet_demir/features/orders/new_order_wizard.dart';
import 'package:santijet_demir/features/orders/orders_screen.dart';
import 'package:santijet_demir/features/reports/report_detail_screen.dart';
import 'package:santijet_demir/features/reports/reports_screen.dart';
import 'package:santijet_demir/features/settings/company_settings_screen.dart';
import 'package:santijet_demir/features/settings/notification_settings_screen.dart';
import 'package:santijet_demir/features/settings/project_settings_screen.dart';
import 'package:santijet_demir/features/settings/settings_screen.dart';
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
      GoRoute(
        path: AppRoutes.deliveryList,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeliveryListScreen(),
      ),
      GoRoute(
        path: AppRoutes.newDelivery,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewDeliveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.supplierPerformance,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupplierPerformanceScreen(),
      ),
      GoRoute(
        path: '/incoming-rebar/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DeliveryDetailScreen(deliveryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.reconciliation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReconciliationScreen(),
      ),
      GoRoute(
        path: AppRoutes.newCount,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewCountScreen(),
      ),
      GoRoute(
        path: '/field-count/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CountDetailScreen(countId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.performanceAnalysis,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PerformanceAnalysisScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/reports/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReportDetailScreen(reportId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'company',
            builder: (context, state) => const CompanySettingsScreen(),
          ),
          GoRoute(
            path: 'project',
            builder: (context, state) => const ProjectSettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: 'empty-states',
            builder: (context, state) => const EmptyStatesPreviewScreen(),
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
