import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

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
    this.style = 'classic',
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

  /// `classic`, `navy`, `pill`, `line`.
  final String style;

  static double totalHeightOf(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return _iconBarHeight + bottomInset + bottomLift;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final chrome = _NavChrome.of(style, lightChrome: lightChrome);

    return Padding(
      padding: const EdgeInsets.only(bottom: bottomLift),
      child: ColoredBox(
        color: chrome.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: chrome.border)),
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
                          chrome: chrome,
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

class _NavChrome {
  const _NavChrome({
    required this.surface,
    required this.border,
    required this.selected,
    required this.muted,
    required this.pill,
    required this.line,
  });

  final Color surface;
  final Color border;
  final Color selected;
  final Color muted;
  final bool pill;
  final bool line;

  static _NavChrome of(String style, {required bool lightChrome}) {
    const navy = AppColors.headerNavyBottom;
    return switch (style) {
      'navy' => const _NavChrome(
          surface: navy,
          border: Color(0x33FFFFFF),
          selected: Colors.white,
          muted: Color(0xFF8AA0B8),
          pill: false,
          line: false,
        ),
      'pill' => const _NavChrome(
          surface: Colors.white,
          border: Color(0xFFE6EBF3),
          selected: Colors.white,
          muted: Color(0xFF64748B),
          pill: true,
          line: false,
        ),
      'line' => const _NavChrome(
          surface: Colors.white,
          border: Color(0xFFE6EBF3),
          selected: navy,
          muted: Color(0xFF94A3B8),
          pill: false,
          line: true,
        ),
      _ => _NavChrome(
          surface: lightChrome ? Colors.white : AppColors.surface,
          border: lightChrome ? const Color(0xFFE6EBF3) : AppColors.border,
          selected: lightChrome ? const Color(0xFF2563EB) : AppColors.electricBlue,
          muted: lightChrome ? const Color(0xFF94A3B8) : AppColors.textMuted,
          pill: false,
          line: false,
        ),
    };
  }
}

class _NavItemView extends StatelessWidget {
  const _NavItemView({
    required this.item,
    required this.selected,
    required this.chrome,
    required this.onTap,
  });

  final SJNavItem item;
  final bool selected;
  final _NavChrome chrome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = chrome.pill
        ? (selected ? Colors.white : chrome.muted)
        : (selected ? chrome.selected : chrome.muted);
    final icon = Icon(selected ? item.activeIcon : item.icon, size: 22, color: color);
    final label = Text(
      item.label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return InkWell(
      onTap: onTap,
      child: chrome.pill
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? AppColors.headerNavyBottom : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(height: 2),
                    label,
                  ],
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (chrome.line)
                  Container(
                    width: 22,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: selected ? chrome.selected : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                icon,
                const SizedBox(height: 2),
                label,
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

    final navStyle = ref.watch(appSettingsProvider.select((s) => s.navStyle));
    final bar = SJBottomNavigation(
      items: items,
      currentIndex: current,
      lightChrome: lightChrome,
      style: navStyle,
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
