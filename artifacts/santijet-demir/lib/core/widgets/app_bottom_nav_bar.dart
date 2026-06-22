import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
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

  /// iOS Safari PWA çoğu zaman viewPadding=0 döndürür; home indicator payı.
  static double _iosHomeIndicatorInset(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    if (viewPadding.bottom >= 20) return viewPadding.bottom;
    if (ResponsiveLayout.isTablet(context)) return 8;
    return 34;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: _iosHomeIndicatorInset(context)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Builder(
            builder: (context) {
              // Telefonda yalnızca ikon — 5 sekme dar ekranda taşmayı önler.
              final showLabels = ResponsiveLayout.isTablet(context);
              final barHeight = showLabels ? 50.0 : 44.0;

              return SizedBox(
                height: barHeight,
                width: double.infinity,
                child: Row(
                  children: [
                    for (var i = 0; i < BottomNavTab.values.length; i++)
                      Expanded(
                        child: _NavItem(
                          icon: _icons[i],
                          activeIcon: _activeIcons[i],
                          label: BottomNavTab.values[i].navLabel,
                          semanticsLabel: BottomNavTab.values[i].label,
                          selected: navigationShell.currentIndex == i,
                          showLabel: showLabels,
                          onTap: () => navigationShell.goBranch(
                            i,
                            initialLocation:
                                i == navigationShell.currentIndex,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String semanticsLabel;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.electricBlueLight : AppColors.textMuted;

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 8 : 10,
                  vertical: showLabel ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.electricBlue.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  size: showLabel ? 20 : 22,
                  color: color,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppTypography.tabLabel.copyWith(
                      color: color,
                      fontSize: 9,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: true,
      child: showLabel
          ? content
          : Tooltip(
              message: semanticsLabel,
              preferBelow: false,
              child: content,
            ),
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
