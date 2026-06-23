import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
/// aktif/pasif ikon). Faz 5'te go_router `StatefulNavigationShell` ile bağlanır;
/// burada yeniden kullanılabilir, durum-bağımsız sunum bileşeni olarak tanımlıdır.
class SJBottomNavigation extends StatelessWidget {
  const SJBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<SJNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return ColoredBox(
      color: surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SizedBox(
              height: 56,
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
          if (bottomInset > 0) SizedBox(height: bottomInset),
        ],
      ),
    );
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
    final color = selected
        ? AppColors.electricBlue
        : theme.colorScheme.onSurfaceVariant;

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
