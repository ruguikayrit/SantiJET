import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Alt navigasyon sekmesi tanımı.
class SJNavItem {
  const SJNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// ŞantiJET Design System — alt navigasyon.
///
/// ŞantiJET Demir `AppBottomNavBar` görsel deseni (üst kenarlık + yüzey zemin +
/// aktif/pasif ikon). Web'de [PointerInterceptor] ile HTML katmanının
/// dokunmaları çalması engellenir.
class SJBottomNavigation extends StatelessWidget {
  const SJBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  static const _iconBarHeight = 52.0;

  /// Alt kenardan hafif yukarı kaydırma — home indicator alanında daha dengeli duruş.
  static const bottomLift = AppSpacing.xs;

  final List<SJNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static double totalHeightOf(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return _iconBarHeight + bottomInset + bottomLift;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    // Lift, ColoredBox içinde — padding boşluğu hit-test dışı kalmasın.
    final bar = Material(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
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
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: bottomInset + bottomLift),
        ],
      ),
    );

    if (kIsWeb) {
      return PointerInterceptor(child: bar);
    }
    return bar;
  }
}

class _NavItemView extends StatelessWidget {
  const _NavItemView({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SJNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected ? AppColors.electricBlue : AppColors.textMuted;

    // Opaque hit target — InkWell yalnız ikon/metin boyutunda kalmasın.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 22,
                color: color,
              ),
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
        ),
      ),
    );
  }
}
