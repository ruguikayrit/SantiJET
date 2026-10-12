import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';

/// Alt navigasyon sekmesi — Saha [SJNavItem] + Demir shell branch indeksi.
class SJNavItem {
  const SJNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.branchIndex,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// go_router [StatefulNavigationShell] dalı ([BottomNavTab.index]).
  final int branchIndex;
}

/// ŞantiJET DEMİR alt navigasyon — Saha `SJBottomNavigation` stil / kurgu.
///
/// 52px ikon satırı, üst kenarlık, `AppColors.surface`, lift dışarıda (canvas),
/// seçili `electricBlue` / pasif `textMuted`, ikon 22, etiket labelSmall.
class SJBottomNavigation extends StatelessWidget {
  const SJBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.lightChrome = false,
    super.key,
  });

  static const _iconBarHeight = 52.0;

  /// Alt kenara yakın duruş. Sayfa rengi şerit kalmasın.
  static const bottomLift = 0.0;

  final List<SJNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Ana sayfa referansı: beyaz zemin, mavi seçili sekme.
  final bool lightChrome;

  static double totalHeightOf(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return _iconBarHeight + bottomInset + bottomLift;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final surface = lightChrome ? Colors.white : AppColors.surface;
    final border = lightChrome ? const Color(0xFFE6EBF3) : AppColors.border;

    // Saha ile aynı ağaç: lift yüzey dışında → 8px şerit canvas rengi.
    return Padding(
      padding: const EdgeInsets.only(bottom: bottomLift),
      child: ColoredBox(
        color: surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: border)),
              ),
              child: SizedBox(
                height: _iconBarHeight,
                width: double.infinity,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItemView(
                          item: items[i],
                          selected: items[i].branchIndex == currentIndex,
                          lightChrome: lightChrome,
                          onTap: () => onTap(items[i].branchIndex),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (bottomInset > 0) SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }
}

class _NavItemView extends StatelessWidget {
  const _NavItemView({
    required this.item,
    required this.selected,
    required this.lightChrome,
    required this.onTap,
  });

  final SJNavItem item;
  final bool selected;
  final bool lightChrome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? (lightChrome ? const Color(0xFF2563EB) : AppColors.electricBlue)
        : (lightChrome ? const Color(0xFF94A3B8) : AppColors.textMuted);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Demir kabuk bağlayıcısı — yetki filtresi + web PointerInterceptor.
///
/// Geriye dönük API: [totalHeightOf] FAB / scroll boşlukları için.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({
    super.key,
    required this.navigationShell,
    this.lightChrome = false,
  });

  final bool lightChrome;

  final StatefulNavigationShell navigationShell;

  static const iconBarHeight = 52.0;
  static const bottomLift = SJBottomNavigation.bottomLift;

  static const _icons = [
    Icons.home_outlined,
    Icons.engineering_outlined,
    Icons.assignment_outlined,
    Icons.local_shipping_outlined,
    Icons.calendar_today_outlined,
  ];

  static const _activeIcons = [
    Icons.home,
    Icons.engineering,
    Icons.assignment,
    Icons.local_shipping,
    Icons.calendar_today,
  ];

  static double totalHeightOf(BuildContext context) =>
      SJBottomNavigation.totalHeightOf(context);

  static SJNavItem _itemFor(BottomNavTab tab) => SJNavItem(
        icon: _icons[tab.index],
        activeIcon: _activeIcons[tab.index],
        label: tab.navLabel,
        branchIndex: tab.index,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleTabs = ref.watch(visibleBottomNavTabsProvider);
    final items = [for (final tab in visibleTabs) _itemFor(tab)];

    final current = navigationShell.currentIndex;
    final currentAllowed = visibleTabs.any((t) => t.index == current);
    if (!currentAllowed && visibleTabs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(visibleTabs.first.index);
      });
    }

    final bar = SJBottomNavigation(
      items: items,
      currentIndex: current,
      lightChrome: lightChrome,
      onTap: (branchIndex) {
        Router.neglect(context, () {
          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        });
      },
    );

    if (kIsWeb) {
      return PointerInterceptor(child: bar);
    }
    return bar;
  }
}
