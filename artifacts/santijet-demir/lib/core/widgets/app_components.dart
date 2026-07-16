import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_bottom_nav_bar.dart';

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
    this.percent,
    this.trend,
    this.trendUp,
    this.accentColor = AppColors.electricBlueLight,
    this.onTap,
    this.dense = false,
    this.compactHeight = false,
    this.centerContent = false,
  });

  final String label;
  final String value;
  final String unit;
  final String? percent;
  final String? trend;
  final bool? trendUp;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool dense;
  final bool compactHeight;
  final bool centerContent;

  Widget _buildLabel() {
    final parts = label.trim().split(RegExp(r'\s+'));
    final align = centerContent ? TextAlign.center : TextAlign.start;
    // Dense cards keep the title on one line (value sits below).
    if (!dense && !compactHeight && parts.length == 2) {
      return Column(
        crossAxisAlignment:
            centerContent ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parts[0], style: AppTypography.labelMedium, textAlign: align),
          Text(parts[1], style: AppTypography.labelMedium, textAlign: align),
        ],
      );
    }
    return Text(
      label,
      style: AppTypography.labelMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = compactHeight ? 8.0 : (dense ? 10.0 : 16.0);
    final valueStyle = dense
        ? AppTypography.kpiValue.copyWith(color: accentColor, fontSize: 20)
        : AppTypography.kpiValue.copyWith(color: accentColor);

    final compactBody = compactHeight
        ? Row(
            children: [
              Expanded(child: _buildLabel()),
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: valueStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(unit, style: AppTypography.labelSmall),
                      ),
                    ],
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                    ],
                  ],
                ),
              ),
            ],
          )
        : null;

    final stackedBody = Column(
      crossAxisAlignment:
          centerContent ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: centerContent
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      mainAxisSize: centerContent ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              centerContent ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (centerContent)
              Flexible(child: _buildLabel())
            else
              Expanded(child: _buildLabel()),
            if (onTap != null && !dense)
              Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ],
        ),
        if (centerContent) const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              centerContent ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: centerContent ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Flexible(
              child: Text(
                value,
                style: valueStyle,
                overflow: TextOverflow.ellipsis,
                textAlign: centerContent ? TextAlign.center : TextAlign.start,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Padding(
                padding: EdgeInsets.only(bottom: dense ? 2 : 4),
                child: Text(
                  unit,
                  style: dense
                      ? AppTypography.labelSmall
                      : AppTypography.labelMedium,
                ),
              ),
            ],
          ],
        ),
        if (percent != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: centerContent
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  percent!,
                  style: AppTypography.bodySmall.copyWith(
                    color: accentColor,
                  ),
                  textAlign: centerContent ? TextAlign.center : TextAlign.start,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.unfold_more,
                  size: 14,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ] else if (onTap != null && !centerContent) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.unfold_more,
              size: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
        if (trend != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: centerContent
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
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
    );

    final content = Container(
      padding: EdgeInsets.all(padding),
      alignment: centerContent ? Alignment.center : null,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: compactHeight
          ? (centerContent
              ? Center(child: compactBody)
              : compactBody!)
          : stackedBody,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: content,
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
    required     this.onSelected,
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

class AppTappable extends StatelessWidget {
  const AppTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerUp: (_) => onTap(),
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: child,
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
    this.aboveBottomNav = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool extended;

  /// Alt sekmeli gezinme çubuğunun üstünde konumlandır (MainShell sekmeleri).
  final bool aboveBottomNav;

  static const _extendedHeight = 56.0;
  static const _fabEdgeMargin = 16.0;
  /// FAB ile son etkileşimli içerik arasında ek boşluk.
  static const _contentGap = 24.0;

  /// Kaydırılabilir içerik altına konacak boşluk — FAB / alt nav hiçbir butonu örtmez.
  static double scrollClearanceOf(
    BuildContext context, {
    bool aboveBottomNav = true,
  }) {
    final nav = aboveBottomNav ? AppBottomNavBar.totalHeightOf(context) : 0.0;
    return nav + _extendedHeight + _fabEdgeMargin + _contentGap;
  }

  @override
  Widget build(BuildContext context) {
    final Widget fab;
    if (extended) {
      fab = FloatingActionButton.extended(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
      );
    } else {
      fab = FloatingActionButton(
        onPressed: onPressed,
        child: const Icon(Icons.add),
      );
    }

    if (!aboveBottomNav) return fab;

    return Padding(
      padding: EdgeInsets.only(bottom: AppBottomNavBar.totalHeightOf(context)),
      child: fab,
    );
  }
}
