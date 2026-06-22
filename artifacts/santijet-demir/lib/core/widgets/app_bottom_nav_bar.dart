import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.local_shipping_outlined,
    Icons.inventory_2_outlined,
    Icons.analytics_outlined,
  ];

  static const _activeIcons = [
    Icons.dashboard,
    Icons.receipt_long,
    Icons.local_shipping,
    Icons.inventory_2,
    Icons.analytics,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.electricBlue.withValues(alpha: 0.15),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (var i = 0; i < BottomNavTab.values.length; i++)
          NavigationDestination(
            icon: Icon(_icons[i], color: AppColors.textMuted),
            selectedIcon: Icon(_activeIcons[i], color: AppColors.electricBlueLight),
            label: BottomNavTab.values[i].label,
          ),
      ],
    );
  }
}

class PlaceholderTabScreen extends StatelessWidget {
  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: AppTypography.headlineLarge),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 72, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Faz 3\'te implement edilecek',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
