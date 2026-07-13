import 'package:flutter/material.dart';
import 'package:santijet_demir/core/responsive/responsive_layout.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';

class SummaryKpiItem {
  const SummaryKpiItem({
    required this.label,
    required this.value,
    this.unit = 't',
    this.percent,
    required this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final String? percent;
  final Color accentColor;
  final VoidCallback? onTap;
}

class SummaryKpiRow extends StatelessWidget {
  const SummaryKpiRow({
    super.key,
    required this.items,
    this.aspectRatio = 1.15,
    this.dense = false,
    this.spacing = 12,
  });

  final List<SummaryKpiItem> items;
  final double aspectRatio;
  final bool dense;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: _SummaryKpiCard(
                item: items[i],
                dense: dense,
                compactHeight: aspectRatio >= 2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SummaryKpiGrid extends StatelessWidget {
  const SummaryKpiGrid({
    super.key,
    required this.items,
    this.crossAxisCount,
    this.childAspectRatio,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
  });

  final List<SummaryKpiItem> items;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    final columns = crossAxisCount ?? (isTablet ? 3 : 2);
    final ratio = childAspectRatio ?? (isTablet ? 1.25 / 1.2 : 1.35);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: ratio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _SummaryKpiCard(item: items[index]),
    );
  }
}

class SummaryKpiSliverGrid extends StatelessWidget {
  const SummaryKpiSliverGrid({
    super.key,
    required this.items,
    this.crossAxisCount,
    this.childAspectRatio,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.padding = EdgeInsets.zero,
  });

  final List<SummaryKpiItem> items;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    final columns = crossAxisCount ?? (isTablet ? 3 : 2);
    final ratio = childAspectRatio ?? (isTablet ? 1.25 / 1.2 : 1.35);

    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: ratio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _SummaryKpiCard(item: items[index]),
          childCount: items.length,
        ),
      ),
    );
  }
}

class _SummaryKpiCard extends StatelessWidget {
  const _SummaryKpiCard({
    required this.item,
    this.dense = false,
    this.compactHeight = false,
  });

  final SummaryKpiItem item;
  final bool dense;
  final bool compactHeight;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      label: item.label,
      value: item.value,
      unit: item.unit,
      percent: item.percent,
      accentColor: item.accentColor,
      onTap: item.onTap,
      dense: dense,
      compactHeight: compactHeight,
    );
  }
}
