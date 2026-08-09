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
          final accent = AppColors.useDarkChrome
              ? AppColors.electricBlueLight
              : AppColors.electricBlue;
          final idleBg = AppColors.surfaceElevated;
          final selectedBg = accent.withValues(alpha: 0.18);
          return FilterChip(
            label: Text(labels[index]),
            selected: selected,
            onSelected: (_) => onSelected(index),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? AppColors.statusInkOnChrome(accent)
                  : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            backgroundColor: idleBg,
            selectedColor: selectedBg,
            side: BorderSide(
              color: selected ? accent : AppColors.border,
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }
}
