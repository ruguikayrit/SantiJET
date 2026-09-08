import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_bottom_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/theme/theme_rebuild_gate.dart';

/// Ana kabuk — 3 sekme; Ayarlar navda yok.
class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    SJNavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Kasa',
    ),
    SJNavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Hareketler',
    ),
    SJNavItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights,
      label: 'Rapor',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    AppColors.applyPaletteFromMode(themeMode, Theme.of(context).brightness);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        resizeToAvoidBottomInset: false,
        body: ThemeRebuildGate(child: navigationShell),
        bottomNavigationBar: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: SJBottomNavigation(
            items: _items,
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              Router.neglect(context, () {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              });
            },
          ),
        ),
      ),
    );
  }
}
