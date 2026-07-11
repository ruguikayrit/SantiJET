import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santijet_demir/core/responsive/app_safe_area.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

/// Alt navigasyon — arka plan ekranın dibine kadar uzanır, ikonlar home indicator üstünde.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _iconBarHeight = 52.0;
  static const _iconBarHeightTablet = 56.0;

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

  static double _bottomInsetOf(BuildContext context) {
    return AppSafeAreaInsets.bottomNavInsetOf(context);
  }

  static double totalHeightOf(BuildContext context) {
    final showLabels = ResponsiveLayout.isTablet(context);
    final iconBarHeight = showLabels ? _iconBarHeightTablet : _iconBarHeight;
    final bottomInset = _bottomInsetOf(context);
    return iconBarHeight + bottomInset;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showLabels = ResponsiveLayout.isTablet(context);
    final iconBarHeight = showLabels ? _iconBarHeightTablet : _iconBarHeight;
    final bottomInset = _bottomInsetOf(context);

    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.85),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
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
    final activeColor = AppColors.electricBlueLight;
    final inactiveColor = AppColors.textMuted.withValues(alpha: 0.85);

    Widget child = SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: selected ? 44 : 40,
            height: selected ? 32 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.electricBlue.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(
                      color: AppColors.electricBlueLight.withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Icon(
              selected ? activeIcon : icon,
              size: showLabel ? 20 : 22,
              color: selected ? activeColor : inactiveColor,
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
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 9,
                  height: 1.0,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ],
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
