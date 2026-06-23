import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analiz_detail/analiz_detail_screen.dart';
import '../../features/analiz_list/analiz_list_screen.dart';
import '../../features/design_gallery/design_gallery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/karsilastir/karsilastir_screen.dart';
import '../../features/kesif/kesif_detail_screen.dart';
import '../../features/kesif/kesif_list_screen.dart';
import '../../features/legal/legal_document_screen.dart';
import '../../features/legal/sources_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Uygulama yönlendiricisi — Demir konvansiyonuyla `StatefulShellRoute` +
/// kalıcı alt navigasyon. Sekmeler: Ana Sayfa, Katalog, Keşif, Ayarlar.
/// Detay/ikincil ekranlar kök navigatörde tam ekran açılır (alt çubuğu kapatır).
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
                path: AppRoutes.katalog,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const AnalizListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.kesif,
                pageBuilder: (context, state) => fadePage(
                    key: state.pageKey, child: const KesifListScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ayarlar,
                pageBuilder: (context, state) =>
                    fadePage(key: state.pageKey, child: const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),

      // ─── Kök (tam ekran) rotalar ───────────────────────────────────
      GoRoute(
        path: AppRoutes.pozlar,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: AnalizListScreen(
            modul: state.uri.queryParameters['modul'],
            query: state.uri.queryParameters['q'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.pozDetayPattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: AnalizDetailScreen(analizId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.kesifDetayPattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: KesifDetailScreen(projectId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.karsilastir,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const KarsilastirScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.tasarimSistemi,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const DesignGalleryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.legalDocumentPattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: LegalDocumentScreen(documentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.sources,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const SourcesScreen(),
        ),
      ),
    ],
  );
});
