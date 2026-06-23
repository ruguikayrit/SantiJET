import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analiz_detail/analiz_detail_screen.dart';
import '../../features/analiz_list/analiz_list_screen.dart';
import '../../features/design_gallery/design_gallery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/karsilastir/karsilastir_screen.dart';
import '../../features/kesif/kesif_detail_screen.dart';
import '../../features/kesif/kesif_list_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'app_routes.dart';

/// Uygulama yönlendiricisi — Demir konvansiyonuyla düz Provider (codegen yok).
///
/// Faz 5'te bottom navigation için `StatefulShellRoute` ve geçiş animasyonları
/// (Demir `page_transitions.dart` deseni) eklenecektir.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.pozlar,
        builder: (context, state) => AnalizListScreen(
          modul: state.uri.queryParameters['modul'],
          query: state.uri.queryParameters['q'],
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                AnalizDetailScreen(analizId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.karsilastir,
        builder: (context, state) => const KarsilastirScreen(),
      ),
      GoRoute(
        path: AppRoutes.kesif,
        builder: (context, state) => const KesifListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                KesifDetailScreen(projectId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ayarlar,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.tasarimSistemi,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
    ],
  );
});
