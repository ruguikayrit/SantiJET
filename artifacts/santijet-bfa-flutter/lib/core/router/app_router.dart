import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/analiz_detail/presentation/analiz_detail_screen.dart';
import '../../features/analiz_list/presentation/analiz_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/karsilastir/presentation/karsilastir_screen.dart';
import '../../features/kesif/presentation/kesif_detail_screen.dart';
import '../../features/kesif/presentation/kesif_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// Uygulama yönlendiricisi (go_router) — Riverpod ile sağlanır.
///
/// Faz 5'te bottom navigation için `StatefulShellRoute` ve geçiş animasyonları
/// genişletilecektir. Şu an Faz 1 iskelet rotaları tanımlıdır.
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.pozlar,
        name: AppRoutes.pozlarName,
        builder: (context, state) => AnalizListScreen(
          modul: state.uri.queryParameters['modul'],
          query: state.uri.queryParameters['q'],
        ),
        routes: [
          GoRoute(
            path: ':id',
            name: AppRoutes.pozDetayName,
            builder: (context, state) =>
                AnalizDetailScreen(analizId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.karsilastir,
        name: AppRoutes.karsilastirName,
        builder: (context, state) => const KarsilastirScreen(),
      ),
      GoRoute(
        path: AppRoutes.kesif,
        name: AppRoutes.kesifName,
        builder: (context, state) => const KesifListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: AppRoutes.kesifDetayName,
            builder: (context, state) =>
                KesifDetailScreen(projectId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ayarlar,
        name: AppRoutes.ayarlarName,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
