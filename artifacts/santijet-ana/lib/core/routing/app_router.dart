import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/app_state_provider.dart';
import '../../features/asistan/asistan_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/workspace_setup_screen.dart';
import '../../features/butce/butce_screen.dart';
import '../../features/dosyalar/dosyalar_screen.dart';
import '../../features/gorev/gorev_screen.dart';
import '../../features/gunluk_rapor/gunluk_rapor_screen.dart';
import '../../features/hakedis/hakedis_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/ilerleme/ilerleme_screen.dart';
import '../../features/imalat/imalat_screen.dart';
import '../../features/is_programi/is_programi_screen.dart';
import '../../features/kantar/kantar_screen.dart';
import '../../features/kesif/kesif_screen.dart';
import '../../features/kullanicilar/kullanicilar_screen.dart';
import '../../features/malzeme/malzeme_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/proje/proje_screen.dart';
import '../../features/puantaj/puantaj_screen.dart';
import '../../features/rapor/rapor_screen.dart';
import '../../features/satin_alma/satin_alma_screen.dart';
import '../../features/settings/ayarlar_screen.dart';
import '../../features/settings/catalog_screens.dart';
import '../../features/settings/dil_screen.dart';
import '../../features/settings/imalat_pozlari_screen.dart';
import '../../features/settings/temalar_screen.dart';
import '../../features/settings/yybm_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/taseron/taseron_screen.dart';
import '../../features/veri_yonetim/veri_yonetim_screen.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(appStateProvider, (_, __) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final app = ref.read(appStateProvider);
      final loc = state.matchedLocation;

      final public = {
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.workspaceSetup,
      };

      if (!app.loaded) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final needsOnboarding =
          app.workspaceInfo == null || app.currentUserId == null;

      if (loc == AppRoutes.splash) return null;

      if (needsOnboarding) {
        if (public.contains(loc)) return null;
        return AppRoutes.onboarding;
      }

      if (loc == AppRoutes.onboarding ||
          loc == AppRoutes.login ||
          loc == AppRoutes.workspaceSetup) {
        return AppRoutes.home;
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
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
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
        path: AppRoutes.workspaceSetup,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const WorkspaceSetupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.proje,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const ProjeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dosyalar,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const DosyalarScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.kesif,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const KesifScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.isProgrami,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const IsProgramiScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.puantaj,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const PuantajScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.gunlukRapor,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const GunlukRaporScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.imalat,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const ImalatScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.gorev,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const GorevScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.malzeme,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const MalzemeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.taseron,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const TaseronScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.satinAlma,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const SatinAlmaScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.kantar,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const KantarScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.butce,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const ButceScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hakedis,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const HakedisScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.ilerleme,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const IlerlemeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.kullanicilar,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const KullanicilarScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.ayarlar,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const AyarlarScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.temalar,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const TemalarScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dil,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const DilScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.asistan,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const AsistanScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.rapor,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const RaporScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.veriYonetim,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const VeriYonetimScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.imalatPozlari,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const ImalatPozlariScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.yybm,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const YybmScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.meslekler,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const MesleklerScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.meslekGrubu,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const MeslekGrubuScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.malzemeKategorisi,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const MalzemeKategorisiScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.malzemeListesi,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const MalzemeListesiScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.malzemeBirimi,
        pageBuilder: (context, state) => fadePage(
          key: state.pageKey,
          child: const MalzemeBirimiScreen(),
        ),
      ),
    ],
  );
});
