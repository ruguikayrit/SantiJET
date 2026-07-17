import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santijet_demir/core/responsive/app_safe_area.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';

/// Alt navigasyon — arka plan ekranın dibine kadar uzanır, ikonlar home indicator üstünde.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _iconBarHeight = 52.0;
  static const _iconBarHeightTablet = 56.0;
  static const _iconSize = 24.0;
  static const _iconSizeTablet = 22.0;
  static const _activeIndicatorSize = 44.0;
  static const _minTapExtent = 48.0;

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
    final visibleTabs = ref.watch(visibleBottomNavTabsProvider);

    // Yetkisiz sekmedeyse ilk görünür sekmeye yönlendir.
    final current = navigationShell.currentIndex;
    final currentAllowed = visibleTabs.any((t) => t.index == current);
    if (!currentAllowed && visibleTabs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(visibleTabs.first.index);
      });
    }

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
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: iconBarHeight,
            width: double.infinity,
            child: Row(
              children: [
                for (final tab in visibleTabs)
                  Expanded(
                    child: _NavItem(
                      icon: _icons[tab.index],
                      activeIcon: _activeIcons[tab.index],
                      label: tab.navLabel,
                      semanticsLabel: tab.label,
                      selected: navigationShell.currentIndex == tab.index,
                      showLabel: showLabels,
                      onTap: () => navigationShell.goBranch(
                        tab.index,
                        initialLocation:
                            tab.index == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
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
    final activeColor = AppColors.electricBlueLight;
    final inactiveColor = AppColors.textMuted.withValues(alpha: 0.85);

    Widget child = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppBottomNavBar._minTapExtent),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: AppBottomNavBar._activeIndicatorSize,
              height: AppBottomNavBar._activeIndicatorSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.electricBlue.withValues(alpha: 0.18)
                    : Colors.transparent,
                border: selected
                    ? Border.all(
                        color:
                            AppColors.electricBlueLight.withValues(alpha: 0.35),
                      )
                    : null,
              ),
              child: Icon(
                selected ? activeIcon : icon,
                size: showLabel
                    ? AppBottomNavBar._iconSizeTablet
                    : AppBottomNavBar._iconSize,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AppTypography.tabLabel.copyWith(
                    color: selected ? activeColor : inactiveColor,
                    fontSize: 10,
                    height: 1.0,
                    decoration: TextDecoration.none,
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
