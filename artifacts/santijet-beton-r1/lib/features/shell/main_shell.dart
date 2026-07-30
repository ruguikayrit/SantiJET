import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_bottom_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/theme/theme_rebuild_gate.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  static const _items = [
    SJNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Özet'),
    SJNavItem(icon: Icons.event_note_outlined, activeIcon: Icons.event_note, label: 'Plan'),
    SJNavItem(icon: Icons.water_drop_outlined, activeIcon: Icons.water_drop, label: 'Döküm'),
    SJNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Sipariş'),
    SJNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    AppColors.applyPaletteFromMode(themeMode, Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: ThemeRebuildGate(child: navigationShell),
      bottomNavigationBar: MediaQuery.removePadding(
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
    );
  }
}
