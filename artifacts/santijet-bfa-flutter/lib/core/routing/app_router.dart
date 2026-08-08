import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analiz/analiz_hub_screen.dart';
import '../../features/analiz_detail/analiz_detail_screen.dart';
import '../../features/analiz_list/analiz_list_screen.dart';
import '../../features/birim_fiyat/birim_fiyat_screen.dart';
import '../../features/design_gallery/design_gallery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/karsilastir/karsilastir_screen.dart';
import '../../features/katalog/analiz_katalog_screen.dart';
import '../../features/kesif/kesif_detail_screen.dart';
import '../../features/kesif/kesif_list_screen.dart';
import '../../features/legal/legal_document_screen.dart';
import '../../features/legal/sources_screen.dart';
import '../../features/ozel_analiz/analiz_editor_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../domain/enums/app_enums.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Kabuk: Ana Sayfa · Analiz · Birim Fiyat · Keşif.
/// Ayarlar kök (tam ekran) rotadır.
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
      // Eski Katalog sekmesi → Birim Fiyat
      GoRoute(
        path: AppRoutes.katalog,
        redirect: (_, __) => AppRoutes.birimFiyat,
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
                path: AppRoutes.analiz,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const AnalizHubScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.birimFiyat,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const BirimFiyatScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.kesif,
                pageBuilder: (context, state) => fadePage(
                  key: state.pageKey,
                  child: const KesifListScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ─── Kök (tam ekran) rotalar ───────────────────────────────────
      GoRoute(
        path: AppRoutes.ayarlar,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.pozlar,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: AnalizListScreen(
            modul: state.uri.queryParameters['modul'],
            query: state.uri.queryParameters['q'],
            cat: state.uri.queryParameters['cat'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.analizYeni,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final modul = state.uri.queryParameters['modul'];
          final discipline = switch (modul) {
            'mekanik' => AnalizDiscipline.mekanik,
            'elektrik' => AnalizDiscipline.elektrik,
            _ => AnalizDiscipline.insaat,
          };
          return fadeSlidePage(
            key: state.pageKey,
            child: AnalizEditorScreen(discipline: discipline),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.analizDuzenlePattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: AnalizEditorScreen(analizId: state.pathParameters['id']!),
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
        path: AppRoutes.analizKatalogu,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const AnalizKatalogScreen(),
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
        pageBuilder: (context, state) {
          final ids = state.uri.queryParameters['ids']
                  ?.split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              const [];
          return fadeSlidePage(
            key: state.pageKey,
            child: KarsilastirScreen(initialIds: ids),
          );
        },
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
