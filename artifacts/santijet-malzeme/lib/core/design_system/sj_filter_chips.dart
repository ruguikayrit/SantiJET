import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// ŞantiJET Design System — yatay filtre çipleri (Demir `FilterChips` birebir).
class SJFilterChips extends StatelessWidget {
  const SJFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.horizontalPadding = AppSpacing.md,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _FilterChipItem(
            label: labels[index],
            selected: index == selectedIndex,
            onSelected: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: selected ? AppColors.textPrimary : AppColors.textMuted,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.electricBlue.withValues(alpha: 0.22),
      side: BorderSide(
        color: selected ? AppColors.electricBlue : AppColors.border,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
