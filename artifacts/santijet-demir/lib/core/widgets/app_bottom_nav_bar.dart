import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

/// Alt navigasyon — ekranın fiziksel altına yaslanır; home indicator nav
/// arka planı içinde kalır, ekstra siyah boşluk oluşturmaz.
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
    final showLabels = ResponsiveLayout.isTablet(context);
    final iconBarHeight = showLabels ? 56.0 : 52.0;
    // viewPadding — padding değil; çift inset önlenir.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final bar = ColoredBox(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              height: iconBarHeight,
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
                          initialLocation: i == navigationShell.currentIndex,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (bottomInset > 0) SizedBox(height: bottomInset),
        ],
      ),
    );

    if (kIsWeb) {
      return PointerInterceptor(child: bar);
    }
    return bar;
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

    Widget child = SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 8 : 12,
                vertical: showLabel ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.electricBlue.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                size: showLabel ? 20 : 24,
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
    );

    if (kIsWeb) {
      child = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerUp: (_) => onTap(),
        child: child,
      );
    } else {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }

    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: true,
      child: child,
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
