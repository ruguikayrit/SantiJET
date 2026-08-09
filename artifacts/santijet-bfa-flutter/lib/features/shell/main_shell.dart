import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_bottom_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/theme/theme_rebuild_gate.dart';

/// Ana kabuk — 5 yüzey: Ana Sayfa · Analiz · Metraj · Keşif · Y.Maliyet.
/// Ayarlar / Projelerim bottom tab değil.
class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    SJNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Ana Sayfa',
    ),
    SJNavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analiz',
    ),
    SJNavItem(
      icon: Icons.straighten_outlined,
      activeIcon: Icons.straighten,
      label: 'Metraj',
    ),
    SJNavItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
      label: 'Keşif',
    ),
    SJNavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Y.Maliyet',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    AppColors.applyPaletteFromMode(themeMode, Theme.of(context).brightness);

    return PopScope(
      // Alt sekmeler arası tarayıcı/geçmiş kaydırmasıyla geri gitmeyi engelle.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Expanded(
              child: ThemeRebuildGate(child: navigationShell),
            ),
            MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: SJBottomNavigation(
                items: _items,
                currentIndex: navigationShell.currentIndex,
                onTap: (index) {
                  // Sekme değişimini tarayıcı geçmişine yazma → sağa/sola
                  // kaydırarak sekme geçişi oluşmasın.
                  Router.neglect(context, () {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
