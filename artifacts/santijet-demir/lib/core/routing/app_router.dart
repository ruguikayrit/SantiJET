import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/routing/page_transitions.dart';
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
import 'package:santijet_demir/features/auth/login_screen.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/auth/register_screen.dart';
import 'package:santijet_demir/features/projects/join_project_screen.dart';
import 'package:santijet_demir/features/projects/project_list_screen.dart';
import 'package:santijet_demir/features/projects/project_members_screen.dart';
import 'package:santijet_demir/features/splash/splash_screen.dart';
import 'package:santijet_demir/features/survey/survey_detail_screen.dart';
import 'package:santijet_demir/features/survey/survey_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final publicRoutes = {
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
      };

      if (auth.user != null && !auth.isSessionValid) {
        return null;
      }

      if (!auth.isAuthenticated && !publicRoutes.contains(location)) {
        return AppRoutes.login;
      }

      if (auth.isAuthenticated &&
          (location == AppRoutes.login || location == AppRoutes.register)) {
        return AppRoutes.projects;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.projects,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const ProjectListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'join',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const JoinProjectScreen(),
            ),
          ),
          GoRoute(
            path: ':id/members',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return fadeSlidePage(
                key: state.pageKey,
                child: ProjectMembersScreen(projectId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newOrder,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const NewOrderWizardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.survey,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const SurveyListScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return fadeSlidePage(
                key: state.pageKey,
                child: SurveyDetailScreen(imalatId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.deliveryList,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const DeliveryListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.newDelivery,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const NewDeliveryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.supplierPerformance,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const SupplierPerformanceScreen(),
        ),
      ),
      GoRoute(
        path: '/incoming-rebar/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return fadeSlidePage(
            key: state.pageKey,
            child: DeliveryDetailScreen(deliveryId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.reconciliation,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const ReconciliationScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.newCount,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const NewCountScreen(),
        ),
      ),
      GoRoute(
        path: '/field-count/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return fadeSlidePage(
            key: state.pageKey,
            child: CountDetailScreen(countId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.performanceAnalysis,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const PerformanceAnalysisScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.reports,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const ReportsScreen(),
        ),
      ),
      GoRoute(
        path: '/reports/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return fadeSlidePage(
            key: state.pageKey,
            child: ReportDetailScreen(reportId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'company',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const CompanySettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'project',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const ProjectSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const NotificationSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'about',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const AboutScreen(),
            ),
          ),
          GoRoute(
            path: 'empty-states',
            pageBuilder: (context, state) => fadeSlidePage(
              key: state.pageKey,
              child: const EmptyStatesPreviewScreen(),
            ),
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
