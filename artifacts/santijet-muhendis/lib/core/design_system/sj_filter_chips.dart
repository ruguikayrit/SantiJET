import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// ŞantiJET Design System — yatay filtre çipleri.
///
/// ŞantiJET Demir `FilterChips` deseni. BFA'da kategori filtreleri için
/// kullanılır.
class SJFilterChips extends StatelessWidget {
  const SJFilterChips({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return FilterChip(
            label: Text(labels[index]),
            selected: selected,
            onSelected: (_) => onSelected(index),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            selectedColor: AppColors.electricBlue.withValues(alpha: 0.2),
            side: BorderSide(
              color: selected ? AppColors.electricBlue : theme.dividerColor,
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }
}
