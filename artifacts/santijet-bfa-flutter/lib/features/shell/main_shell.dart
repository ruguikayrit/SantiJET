import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_bottom_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/theme/theme_rebuild_gate.dart';

/// Ana kabuk — 4 yüzey: Ana Sayfa · Analiz · Birim Fiyat · Keşif.
/// Ayarlar bottom tab değil (header / Ana Sayfa'dan).
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
      icon: Icons.sell_outlined,
      activeIcon: Icons.sell,
      label: 'Birim Fiyat',
    ),
    SJNavItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
      label: 'Keşif',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    AppColors.applyPaletteFromMode(themeMode, Theme.of(context).brightness);

    return Scaffold(
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
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
