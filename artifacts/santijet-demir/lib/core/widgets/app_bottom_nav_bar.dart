import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';

/// Alt navigasyon — Puantaj [SJBottomNavigation] ana tasarımı ve konum iskeleti:
/// yüzey zemin, üst kenarlık, ikon satırı + safe-area dolgusu + hafif alt lift.
/// Sekme ikonları / seçim halkası / yetki filtresi Demir’e özgü kalır.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Puantaj ile aynı ikon satırı yüksekliği.
  static const iconBarHeight = 52.0;

  /// Alt kenardan hafif yukarı — Puantaj `bottomLift`.
  static const bottomLift = AppSpacing.xs;

  /// Geriye dönük sabit (tercihen [bottomInsetOf] / [totalHeightOf]).
  static const bottomInset = 0.0;

  /// Geriye dönük sabit toplam (tercihen [totalHeightOf]).
  static const totalHeight = iconBarHeight + bottomInset;

  /// Demir sekme butonları — aktif halka / ikon ölçüleri.
  static const _iconSize = 26.0;
  static const _activeIndicatorSize = 42.0;

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

  static double iconBarHeightOf(BuildContext context) => iconBarHeight;

  /// Home indicator / safe-area — Puantaj gibi nav yüzeyiyle doldurulur.
  static double bottomInsetOf(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  static double totalHeightOf(BuildContext context) =>
      iconBarHeight + bottomInsetOf(context) + bottomLift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showLabels = ResponsiveLayout.isTablet(context);
    final visibleTabs = ref.watch(visibleBottomNavTabsProvider);
    final safeBottom = bottomInsetOf(context);

    final current = navigationShell.currentIndex;
    final currentAllowed = visibleTabs.any((t) => t.index == current);
    if (!currentAllowed && visibleTabs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(visibleTabs.first.index);
      });
    }

    final bar = Padding(
      padding: const EdgeInsets.only(bottom: bottomLift),
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.85),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: AppColors.isDark ? 8 : 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: iconBarHeight,
                width: double.infinity,
                child: Row(
                  children: [
                    for (final tab in visibleTabs)
                      Expanded(
                        child: _NavItem(
                          height: iconBarHeight,
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
            ),
            if (safeBottom > 0) SizedBox(height: safeBottom),
          ],
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
    required this.height,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final double height;
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

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
                    color: AppColors.electricBlueLight.withValues(alpha: 0.35),
                  )
                : null,
          ),
          child: Icon(
            selected ? activeIcon : icon,
            size: AppBottomNavBar._iconSize,
            color: selected ? activeColor : inactiveColor,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.tabLabel.copyWith(
              color: selected ? activeColor : inactiveColor,
              fontSize: AppTypography.scale * 9,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ],
    );

    Widget child = SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: content,
          ),
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
