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
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt,
      label: 'Hesap',
    ),
    SJNavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      label: 'Tablo',
    ),
    SJNavItem(
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
      label: 'Kayıtlar',
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
