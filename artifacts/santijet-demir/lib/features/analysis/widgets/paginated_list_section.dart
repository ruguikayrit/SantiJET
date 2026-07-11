import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

/// Büyük veri listelerinde yalnızca görünür dilimi render eder.
class PaginatedListSection<T> extends StatefulWidget {
  const PaginatedListSection({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 50,
    this.header,
    this.empty,
    this.showMoreLabel,
  });

  static const defaultPageSize = 50;

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final Widget? header;
  final Widget? empty;
  final String Function(int visible, int total)? showMoreLabel;

  @override
  State<PaginatedListSection<T>> createState() =>
      _PaginatedListSectionState<T>();
}

class _PaginatedListSectionState<T> extends State<PaginatedListSection<T>> {
  late int _visibleCount;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialVisibleCount();
  }

  @override
  void didUpdateWidget(covariant PaginatedListSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.items.length != widget.items.length) {
      _visibleCount = _initialVisibleCount();
    }
  }

  int _initialVisibleCount() {
    if (widget.items.length <= widget.pageSize) return widget.items.length;
    return widget.pageSize;
  }

  void _showMore() {
    setState(() {
      _visibleCount = (_visibleCount + widget.pageSize).clamp(
        0,
        widget.items.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return widget.empty ?? const SizedBox.shrink();
    }

    final visible = items.take(_visibleCount).toList();
    final hasMore = _visibleCount < items.length;
    final labelBuilder = widget.showMoreLabel ??
        (visibleCount, total) =>
            'Daha fazla göster ($visibleCount / $total)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null) widget.header!,
        for (var i = 0; i < visible.length; i++)
          widget.itemBuilder(context, visible[i], i),
        if (hasMore) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _showMore,
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text(
                labelBuilder(_visibleCount, items.length),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// ListView.builder tabanlı sanal liste — sabit yükseklikte binlerce satır.
class VirtualizedScrollTable extends StatelessWidget {
  const VirtualizedScrollTable({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.header,
    this.maxHeight = 360,
    this.empty,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget header;
  final double maxHeight;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          empty ?? const SizedBox.shrink(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SizedBox(
          height: maxHeight,
          child: ListView.builder(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}
