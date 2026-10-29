import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/diameter_status_cells.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/shell_tab_guard.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

enum _CountSort {
  newest('En yeni'),
  oldest('En eski'),
  tonsDesc('Tonaj çok → az'),
  tonsAsc('Tonaj az → çok'),
  region('Bölge A–Z');

  const _CountSort(this.label);
  final String label;
}

double _countTotal(FieldCountRecord record) =>
    record.lines.fold<double>(0, (sum, line) => sum + (line.actual > 0 ? line.actual : 0));

String _countName(FieldCountRecord record) =>
    (record.region.isNotEmpty ? record.region : record.title).toLowerCase();

List<FieldCountRecord> _sortCounts(List<FieldCountRecord> counts, _CountSort sort) {
  final sorted = [...counts];
  switch (sort) {
    case _CountSort.newest:
      sorted.sort((a, b) => b.date.compareTo(a.date));
    case _CountSort.oldest:
      sorted.sort((a, b) => a.date.compareTo(b.date));
    case _CountSort.tonsDesc:
      sorted.sort((a, b) => _countTotal(b).compareTo(_countTotal(a)));
    case _CountSort.tonsAsc:
      sorted.sort((a, b) => _countTotal(a).compareTo(_countTotal(b)));
    case _CountSort.region:
      sorted.sort((a, b) => _countName(a).compareTo(_countName(b)));
  }
  return sorted;
}

class FieldCountScreen extends ConsumerStatefulWidget {
  const FieldCountScreen({super.key});

  @override
  ConsumerState<FieldCountScreen> createState() => _FieldCountScreenState();
}

class _FieldCountScreenState extends ConsumerState<FieldCountScreen> {
  _CountSort _sort = _CountSort.newest;

  @override
  Widget build(BuildContext context) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final counts = _sortCounts(ref.watch(fieldCountsProvider), _sort);
    final canEdit = ref.watch(canEditFieldCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      floatingActionButtonLocation: ShellAddFab.location,
      floatingActionButton: hasActiveProject && canEdit
          ? ShellAddFab(
              heroTag: 'new-count',
              onPressed: () => context.push(AppRoutes.newCount),
            )
          : null,
      body: Column(
        children: [
          const SantijetHeader(subtitle: 'Saha Sayım'),
          if (!hasActiveProject)
            const Expanded(child: ActiveProjectGate(child: SizedBox.shrink()))
          else
            Expanded(
              child: Column(
                children: [
                  if (counts.length > 1) ...[
                    const SizedBox(height: 14),
                    _SortChips(
                      selected: _sort,
                      onSelected: (sort) => setState(() => _sort = sort),
                    ),
                  ],
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        counts.length > 1 ? 10 : 16,
                        16,
                        AppFab.scrollClearanceOf(context),
                      ),
                      children: [
                        if (counts.isEmpty)
                          const _EmptyCountList()
                        else
                          for (final record in counts) ...[
                            _CountRecordTile(
                              record: record,
                              onTap: canEdit
                                  ? () => context.push(AppRoutes.editCount(record.id))
                                  : () => context.push(AppRoutes.countDetail(record.id)),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({required this.selected, required this.onSelected});

  final _CountSort selected;
  final ValueChanged<_CountSort> onSelected;

  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    const sorts = _CountSort.values;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sorts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sort = sorts[index];
          final active = sort == selected;
          return Material(
            color: active ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(99),
            child: InkWell(
              onTap: () => onSelected(sort),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: active ? _blue : const Color(0xFFE6EBF3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index == 0) ...[
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 16,
                        color: active ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      sort.label,
                      style: GoogleFonts.inter(
                        color: active ? Colors.white : const Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCountList extends StatelessWidget {
  const _EmptyCountList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 34, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            'Henüz sayım kaydı yok',
            style: AppTypography.titleMedium.copyWith(
              color: const Color(0xFF1C2430),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sağ alttaki + ile sahadaki demir tonajını kaydedin.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _CountRecordTile extends StatelessWidget {
  const _CountRecordTile({required this.record, required this.onTap});

  final FieldCountRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy · HH:mm').format(record.date);
    final lines = record.lines.where((line) => line.actual > 0).toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));
    final total = lines.fold<double>(0, (sum, line) => sum + line.actual);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.region.isNotEmpty ? record.region : record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: AppTypography.labelMedium.copyWith(color: const Color(0xFF8B95A5)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                ],
              ),
              if (record.personnel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  record.personnel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: const Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 10),
              _TotalWithDiameterCells(
                total: total,
                lines: lines,
                totalStyle: AppTypography.titleLarge,
                gap: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toplam tonaj + çap hücreleri; 4'ten fazla çapta sağda «Kaydır» butonu.
class _TotalWithDiameterCells extends StatefulWidget {
  const _TotalWithDiameterCells({
    required this.total,
    required this.lines,
    required this.totalStyle,
    required this.gap,
  });

  final double total;
  final List<FieldCountLineRecord> lines;
  final TextStyle totalStyle;
  final double gap;

  @override
  State<_TotalWithDiameterCells> createState() => _TotalWithDiameterCellsState();
}

class _TotalWithDiameterCellsState extends State<_TotalWithDiameterCells> {
  static const _maxVisible = 4;
  static const _blue = Color(0xFF2563EB);

  final _scroll = ScrollController();
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncEnd);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncEnd() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final atEnd = position.pixels > 1 && position.pixels >= position.maxScrollExtent - 1;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  void _page() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target = _atEnd
        ? 0.0
        : (position.pixels + position.viewportDimension).clamp(0.0, position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    final overflow = lines.length > _maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppFormat.tonnage(widget.total),
                style: widget.totalStyle.copyWith(
                  color: _blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (overflow) _pageButton(),
          ],
        ),
        if (lines.isNotEmpty) ...[
          SizedBox(height: widget.gap),
          DiameterStatusCells(
            maxVisible: _maxVisible,
            controller: _scroll,
            items: [
              for (final line in lines)
                DiameterStatusCellItem(
                  diameter: line.diameter,
                  bottomLabel: AppFormat.tonnage(line.actual),
                  sortValue: line.actual,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _pageButton() {
    final backToStart = _atEnd;
    const labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _blue);
    return Semantics(
      button: true,
      label: backToStart ? 'Çapları başa kaydır' : 'Sonraki çaplara kaydır',
      child: Material(
        color: _blue.withValues(alpha: 0.08),
        shape: StadiumBorder(side: BorderSide(color: _blue.withValues(alpha: 0.25))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _page,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Padding(
              padding: EdgeInsets.fromLTRB(backToStart ? 6 : 12, 0, backToStart ? 12 : 6, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: backToStart
                    ? const [
                        Icon(Icons.chevron_left_rounded, size: 18, color: _blue),
                        SizedBox(width: 2),
                        Text('Başa dön', style: labelStyle),
                      ]
                    : const [
                        Text('Kaydır', style: labelStyle),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 18, color: _blue),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
