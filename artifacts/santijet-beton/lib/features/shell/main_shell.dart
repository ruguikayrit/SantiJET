import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_bottom_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/theme/theme_rebuild_gate.dart';

/// Ana kabuk — kalıcı alt navigasyon + indexedStack.
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
      icon: Icons.pie_chart_outline,
      activeIcon: Icons.pie_chart,
      label: 'Keşif',
    ),
    SJNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Sipariş',
    ),
    SJNavItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping,
      label: 'Döküm',
    ),
    SJNavItem(
      icon: Icons.science_outlined,
      activeIcon: Icons.science,
      label: 'Test',
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
        body: ThemeRebuildGate(child: navigationShell),
        bottomNavigationBar: MediaQuery.removePadding(
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
      ),
    );
  }
}
