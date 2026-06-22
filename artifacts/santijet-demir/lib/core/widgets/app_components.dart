import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadii.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SapmaTag extends StatelessWidget {
  const SapmaTag({
    super.key,
    required this.value,
    this.unit = 't',
  });

  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isZero = value == 0;
    final color = isZero
        ? AppColors.success
        : isPositive
            ? AppColors.info
            : value.abs() > 10
                ? AppColors.critical
                : AppColors.warning;

    final prefix = isZero ? '✓' : isPositive ? '+' : '';
    final text = isZero ? '✓' : '$prefix${value.toStringAsFixed(1)}$unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.sm,
      ),
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.trend,
    this.trendUp,
    this.accentColor = AppColors.electricBlueLight,
  });

  final String label;
  final String value;
  final String unit;
  final String? trend;
  final bool? trendUp;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.kpiValue.copyWith(color: accentColor),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: AppTypography.labelMedium),
              ),
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendUp == true ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trendUp == true ? AppColors.success : AppColors.critical,
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: AppTypography.labelMedium.copyWith(
                    color: trendUp == true ? AppColors.success : AppColors.critical,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.severityColor,
    this.onTap,
  });

  final String title;
  final String message;
  final Color severityColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: AppRadii.xs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(message, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.titleMedium),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: AppTypography.titleMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadii.full,
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.hint = 'Ara...',
    this.onChanged,
    this.onFilterTap,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              isDense: true,
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onFilterTap,
            icon: const Icon(Icons.tune, color: AppColors.textMuted),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
            ),
          ),
        ],
      ],
    );
  }
}

class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
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
            labelStyle: AppTypography.labelMedium.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            backgroundColor: AppColors.surfaceElevated,
            selectedColor: AppColors.electricBlue.withValues(alpha: 0.2),
            side: BorderSide(
              color: selected ? AppColors.electricBlue : AppColors.border,
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.extended = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
      );
    }
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}
