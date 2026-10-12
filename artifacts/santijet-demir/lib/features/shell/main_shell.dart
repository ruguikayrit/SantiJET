import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/theme_rebuild_gate.dart';
import 'package:santijet_demir/core/widgets/app_bottom_nav_bar.dart';
import 'package:santijet_demir/core/widgets/project_permission_gate.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_running_lock_overlay.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';
import 'package:santijet_demir/features/shell/widgets/home_dashboard.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tema değişince shell + nav yeniden çizilsin (AppColors Theme bağımlısı değil).
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    AppColors.applyPaletteFromMode(themeMode, Theme.of(context).brightness);

    // Saha ile aynı: klavye açıkken nav gizlenir; gövde daralsın.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Stack yalnızca analiz kilidi için — nav yüksekliğini etkilemez.
    // Tüm sekmeler siyah wordmark başlığı kullanır; status ikonları açık kalır.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor: HomeDashboard.page,
          resizeToAvoidBottomInset: true,
          // Başlık kendi status boşluğunu çizer.
          // Alt false: nav kendi viewPadding inset'ini çizer.
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReadOnlyBanner(),
                Expanded(child: ThemeRebuildGate(child: navigationShell)),
              ],
            ),
          ),
          bottomNavigationBar: keyboardOpen
              ? null
              : MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: AppBottomNavBar(
                    navigationShell: navigationShell,
                    lightChrome: true,
                  ),
                ),
        ),
        const AnalysisRunningLockOverlay(),
      ],
    ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: HomeDashboard.page,
      body: HomeDashboard(),
    );
  }
}
