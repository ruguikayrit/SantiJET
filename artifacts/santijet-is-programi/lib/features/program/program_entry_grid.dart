import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/man_day_progress.dart';
import '../../domain/program_item.dart';
import '../../ui/design_system.dart';

/// MS Project Giriş tablosu — telefon genişliğine oturan çizgili ızgara.
///
/// Yatay kaydırma yok; her görev üç satırda tüm Giriş alanlarını taşır.
class ProgramEntryGrid extends StatelessWidget {
  const ProgramEntryGrid({
    required this.items,
    required this.progressFor,
    required this.onTap,
    super.key,
  });

  final List<ProgramItem> items;
  final ManDayProgress Function(ProgramItem item) progressFor;
  final ValueChanged<ProgramItem> onTap;

  static final _dayFmt = DateFormat('E dd.MM.yy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    return SJCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _EntryHeader(),
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) Divider(height: 1, thickness: 1, color: _gridLine),
            _EntryRow(
              index: index + 1,
              item: items[index],
              progress: progressFor(items[index]),
              onTap: () => onTap(items[index]),
            ),
          ],
        ],
      ),
    );
  }

  static Color get _gridLine => AppColors.cardBorder;
}

class _EntryHeader extends StatelessWidget {
  const _EntryHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardInsetSurface,
        border: Border(bottom: BorderSide(color: ProgramEntryGrid._gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GridRow(
            cells: const [
              _GridCellSpec(flex: 1, label: '#'),
              _GridCellSpec(flex: 2, label: 'WBS'),
              _GridCellSpec(flex: 9, label: 'Görev adı'),
            ],
            header: true,
          ),
          Divider(height: 1, thickness: 1, color: ProgramEntryGrid._gridLine),
          _GridRow(
            cells: const [
              _GridCellSpec(flex: 2, label: 'Süre'),
              _GridCellSpec(flex: 3, label: 'Başlangıç'),
              _GridCellSpec(flex: 3, label: 'Bitiş'),
              _GridCellSpec(flex: 2, label: '% Tam.'),
            ],
            header: true,
          ),
          Divider(height: 1, thickness: 1, color: ProgramEntryGrid._gridLine),
          _GridRow(
            cells: const [
              _GridCellSpec(flex: 4, label: 'Öncüller'),
              _GridCellSpec(flex: 6, label: 'Kaynak adları'),
            ],
            header: true,
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.index,
    required this.item,
    required this.progress,
    required this.onTap,
  });

  final int index;
  final ProgramItem item;
  final ManDayProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = progress.effectiveStatus;
    final statusColor = programStatusColor(status);
    final wbs = (item.wbs ?? '').trim().isEmpty ? '$index' : item.wbs!.trim();
    final duration = item.isMilestone
        ? '0 gün'
        : '${item.calculatedDays} gün';
    final predecessors = (item.predecessors ?? '').trim();
    final resource = item.responsible.trim();
    final indent = (item.outlineLevel - 1).clamp(0, 6) * 10.0;
    final nameStyle = AppTypography.cardBodySmall.copyWith(
      fontWeight: item.outlineLevel <= 1 ? FontWeight.w700 : FontWeight.w500,
      height: 1.25,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GridRow(
              cells: [
                _GridCellSpec(
                  flex: 1,
                  child: Text(
                    '$index',
                    style: AppTypography.cardBodySmall.copyWith(
                      color: AppColors.cardTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _GridCellSpec(
                  flex: 2,
                  child: Text(
                    wbs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardBodySmall.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                _GridCellSpec(
                  flex: 9,
                  child: Row(
                    children: [
                      if (item.isMilestone) ...[
                        Icon(
                          Icons.flag_rounded,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: indent),
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: nameStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 1, thickness: 1, color: ProgramEntryGrid._gridLine),
            _GridRow(
              cells: [
                _GridCellSpec(
                  flex: 2,
                  child: Text(duration, style: AppTypography.cardBodySmall),
                ),
                _GridCellSpec(
                  flex: 3,
                  child: Text(
                    ProgramEntryGrid._dayFmt.format(item.startDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardBodySmall,
                  ),
                ),
                _GridCellSpec(
                  flex: 3,
                  child: Text(
                    ProgramEntryGrid._dayFmt.format(item.endDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardBodySmall,
                  ),
                ),
                _GridCellSpec(
                  flex: 2,
                  child: Text(
                    '${progress.progress}%',
                    style: AppTypography.cardBodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 1, thickness: 1, color: ProgramEntryGrid._gridLine),
            _GridRow(
              cells: [
                _GridCellSpec(
                  flex: 4,
                  child: Text(
                    predecessors.isEmpty ? '—' : predecessors,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardBodySmall.copyWith(
                      color: predecessors.isEmpty
                          ? AppColors.cardTextMuted
                          : null,
                    ),
                  ),
                ),
                _GridCellSpec(
                  flex: 6,
                  child: Text(
                    resource.isEmpty ? '—' : resource,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardBodySmall.copyWith(
                      color: resource.isEmpty ? AppColors.cardTextMuted : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCellSpec {
  const _GridCellSpec({
    required this.flex,
    this.label,
    this.child,
  });

  final int flex;
  final String? label;
  final Widget? child;
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.cells,
    this.header = false,
  });

  final List<_GridCellSpec> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: ProgramEntryGrid._gridLine,
              ),
            Expanded(
              flex: cells[i].flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: header
                    ? Text(
                        cells[i].label ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardBodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: AppColors.cardTextMuted,
                        ),
                      )
                    : cells[i].child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
