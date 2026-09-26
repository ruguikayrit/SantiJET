import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/module_host/module_host_screen.dart';
import '../../modules/pro_module.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    for (final module in ProModule.catalog)
      GoRoute(
        path: module.route,
        builder: (context, state) => ModuleHostScreen(module: module),
      ),
  ],
);
