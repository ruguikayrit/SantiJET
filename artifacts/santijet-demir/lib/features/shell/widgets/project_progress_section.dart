import 'dart:async';

import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/shell/project_progress_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class ProjectProgressSection extends ConsumerWidget {
  const ProjectProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(activeProjectIdProvider, (previous, next) {
      if (previous != next) {
        ref.read(selectedProgressImalatIdsProvider.notifier).state = {};
      }
    });

    final summary = ref.watch(projectProgressSummaryProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final selectedImalatIds = ref.watch(selectedProgressImalatIdsProvider);
    final groupedRows = _groupProgressRows(summary.rows);

    if (summary.rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proje İlerleme Durumu', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Planlanan kullanım = keşif tonajı × ilerleme oranı',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          const ModuleEmptyState(type: EmptyStateType.noSurvey, inline: true),
        ],
      );
    }

    final overallPercent = summary.overallProgressPercent.round();
    final allImalatIds = {
      for (final group in groupedRows) group.first.imalatId,
    };

    void setSelectedImalats(Set<String> next) {
      ref.read(selectedProgressImalatIdsProvider.notifier).state = next;
    }

    Future<void> applyBulkProgress(double progressPercent) async {
      if (selectedImalatIds.isEmpty) return;
      try {
        await ref.read(surveyProjectProvider.notifier).updateProgressForImalats(
              imalatIds: selectedImalatIds,
              progressPercent: progressPercent,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showAppSnackBar(
            SnackBar(
              content: Text(
                '${selectedImalatIds.length} imalata '
                '%${progressPercent.round()} uygulandı',
              ),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showAppSnackBar(
            const SnackBar(content: Text('İlerleme kaydedilemedi')),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proje İlerleme Durumu', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Proje ilerleme = planlanan kullanım toplamı / keşif miktarı',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 12),
        _OverallProgressCard(
          percent: overallPercent,
          totalPlanned: summary.totalPlanned,
          totalExpected: summary.totalExpected,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: canEdit && selectedImalatIds.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _BulkProgressEntryPanel(
                    selectedImalatIds: selectedImalatIds,
                    allImalatIds: allImalatIds,
                    groupedRows: groupedRows,
                    onSelectionChanged: setSelectedImalats,
                    onApply: applyBulkProgress,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _ProgressTableHeader(),
              ...groupedRows.indexed.map(
                (entry) => _ProgressImalatGroup(
                  rows: entry.$2,
                  isFirst: entry.$1 == 0,
                  canEdit: canEdit,
                  selected: selectedImalatIds.contains(entry.$2.first.imalatId),
                  onSelectionChanged: (selected) {
                    final imalatId = entry.$2.first.imalatId;
                    final next = Set<String>.from(selectedImalatIds);
                    if (selected) {
                      next.add(imalatId);
                    } else {
                      next.remove(imalatId);
                    }
                    setSelectedImalats(next);
                  },
                  onProgressChanged: (row, value) async {
                    final notifier = ref.read(surveyProjectProvider.notifier);
                    try {
                      if (row.diameter == null) {
                        await notifier.updateImalatProgress(
                          imalatId: row.imalatId,
                          progressPercent: value,
                        );
                      } else {
                        await notifier.updateDiameterLineProgress(
                          imalatId: row.imalatId,
                          diameter: row.diameter!,
                          progressPercent: value,
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showAppSnackBar(
                          const SnackBar(content: Text('İlerleme kaydedilemedi')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<List<ProjectProgressRow>> _groupProgressRows(List<ProjectProgressRow> rows) {
  final groups = <String, List<ProjectProgressRow>>{};
  final order = <String>[];

  for (final row in rows) {
    if (!groups.containsKey(row.imalatId)) {
      order.add(row.imalatId);
      groups[row.imalatId] = [];
    }
    groups[row.imalatId]!.add(row);
  }

  return order.map((id) => groups[id]!).toList();
}

class _BulkProgressEntryPanel extends StatefulWidget {
  const _BulkProgressEntryPanel({
    required this.selectedImalatIds,
    required this.allImalatIds,
    required this.groupedRows,
    required this.onSelectionChanged,
    required this.onApply,
  });

  final Set<String> selectedImalatIds;
  final Set<String> allImalatIds;
  final List<List<ProjectProgressRow>> groupedRows;
  final ValueChanged<Set<String>> onSelectionChanged;
  final Future<void> Function(double progressPercent) onApply;

  @override
  State<_BulkProgressEntryPanel> createState() =>
      _BulkProgressEntryPanelState();
}

class _BulkProgressEntryPanelState extends State<_BulkProgressEntryPanel> {
  late final TextEditingController _controller;
  var _isApplying = false;
  var _livePercent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPercentChanged(String value) {
    final parsed = int.tryParse(value.trim());
    setState(() {
      _livePercent = parsed == null ? 0 : parsed.clamp(0, 100).toDouble();
    });
  }

  bool get _allSelected =>
      widget.allImalatIds.isNotEmpty &&
      widget.selectedImalatIds.length == widget.allImalatIds.length;

  int get _targetRowCount => widget.groupedRows
      .where((group) => widget.selectedImalatIds.contains(group.first.imalatId))
      .fold(0, (sum, group) => sum + group.length);

  String get _targetLabel {
    if (widget.selectedImalatIds.length == 1) {
      final group = widget.groupedRows.firstWhere(
        (rows) => widget.selectedImalatIds.contains(rows.first.imalatId),
      );
      return group.first.imalatName;
    }
    return '${widget.selectedImalatIds.length} imalat';
  }

  Future<void> _apply() async {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) return;

    setState(() => _isApplying = true);
    try {
      await widget.onApply(parsed.clamp(0, 100).toDouble());
      if (!mounted) return;
      _controller.text = '${parsed.clamp(0, 100)}';
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: AppColors.electricBlueLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.percent,
                size: 18,
                color: AppColors.electricBlueLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toplu ilerleme',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onSelectionChanged({}),
                child: const Text('Seçimi kaldır'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hedef: $_targetLabel · $_targetRowCount çap satırı',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: Icon(
                  _allSelected ? Icons.deselect : Icons.select_all,
                  size: 16,
                  color: AppColors.electricBlueLight,
                ),
                label: Text(
                  _allSelected ? 'Seçimi kaldır' : 'Tümünü seç',
                  style: AppTypography.labelMedium,
                ),
                backgroundColor: AppColors.canvas,
                side: BorderSide(color: AppColors.border),
                onPressed: () {
                  widget.onSelectionChanged(
                    _allSelected
                        ? <String>{}
                        : Set<String>.from(widget.allImalatIds),
                  );
                },
              ),
              ActionChip(
                label: Text(
                  '${widget.selectedImalatIds.length} seçili',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
                backgroundColor:
                    AppColors.electricBlue.withValues(alpha: 0.1),
                side: BorderSide(
                  color: AppColors.electricBlue.withValues(alpha: 0.35),
                ),
                onPressed: () => widget.onSelectionChanged({}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.electricBlueLight,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '0',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.sm,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadii.sm,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      onSubmitted: (_) => _apply(),
                      onChanged: _onPercentChanged,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '%',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricBlueLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _isApplying ? null : _apply,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.electricBlueLight,
                    foregroundColor: AppColors.canvas,
                  ),
                  child: _isApplying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Uygula'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnimatedProgressBar(
                  percent: _livePercent,
                  color: AppColors.electricBlueLight,
                  height: 8,
                ),
              ),
              const SizedBox(width: 10),
              AnimatedCountText(
                value: '${_livePercent.round()}',
                numericValue: _livePercent,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.electricBlueLight,
                  fontWeight: FontWeight.w700,
                ),
                formatter: (n) => '${n.round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressImalatGroup extends StatefulWidget {
  const _ProgressImalatGroup({
    required this.rows,
    required this.isFirst,
    required this.canEdit,
    required this.selected,
    required this.onSelectionChanged,
    required this.onProgressChanged,
  });

  final List<ProjectProgressRow> rows;
  final bool isFirst;
  final bool canEdit;
  final bool selected;
  final ValueChanged<bool> onSelectionChanged;
  final void Function(ProjectProgressRow row, double value) onProgressChanged;

  @override
  State<_ProgressImalatGroup> createState() => _ProgressImalatGroupState();
}

class _ProgressImalatGroupState extends State<_ProgressImalatGroup> {
  /// Çap tablosu varsayılan olarak açık; kullanıcı kapatabilir.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();

    final rows = widget.rows;
    final imalatName = rows.first.imalatName;
    final totalPlanned =
        rows.fold(0.0, (sum, row) => sum + row.plannedTonnage);
    final totalExpected =
        rows.fold(0.0, (sum, row) => sum + row.expectedTonnage);
    final overallPercent = totalPlanned > 0
        ? (totalExpected / totalPlanned * 100).round().clamp(0, 100)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.06),
            border: Border(
              top: widget.isFirst
                  ? BorderSide.none
                  : BorderSide(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              if (widget.canEdit) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: AppAnimatedCheckbox(
                    value: widget.selected,
                    onChanged: (value) =>
                        widget.onSelectionChanged(value == true),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        widget.canEdit ? 4 : 14,
                        12,
                        14,
                        10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.electricBlueLight,
                              borderRadius: AppRadii.full,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  imalatName,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rows.length} çap · Keşif ${AppFormat.tonnage(totalPlanned)}t',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  'Planlanan kullanım ${AppFormat.tonnage(totalExpected)}t',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue
                                  .withValues(alpha: 0.12),
                              borderRadius: AppRadii.full,
                              border: Border.all(
                                color: AppColors.electricBlue
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '$overallPercent%',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.electricBlueLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_expanded)
          ...rows.map(
            (row) => _ProgressTableRow(
              row: row,
              canEdit: widget.canEdit,
              onProgressChanged: (value) =>
                  widget.onProgressChanged(row, value),
            ),
          ),
      ],
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({
    required this.percent,
    required this.totalPlanned,
    required this.totalExpected,
  });

  final int percent;
  final double totalPlanned;
  final double totalExpected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Text('Proje İlerleme Oranı', style: AppTypography.titleMedium),
              AnimatedCountText(
                value: '$percent',
                numericValue: percent,
                style: AppTypography.kpiValue.copyWith(
                  fontSize: AppTypography.scale * 28,
                  color: AppColors.electricBlueLight,
                ),
                formatter: (n) => '${n.round()}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            percent: percent.toDouble(),
            color: AppColors.electricBlueLight,
            height: 10,
          ),
          const SizedBox(height: 10),
          Text(
            'Planlanan kullanım ${AppFormat.tonnage(totalExpected)}t / '
            'Keşif ${AppFormat.tonnage(totalPlanned)}t',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProgressTableHeader extends StatelessWidget {
  const _ProgressTableHeader();

  @override
  Widget build(BuildContext context) {
    return const AppTableHeaderRow(
      cells: [
        AppTableHeaderCell('ÇAP', flex: 2),
        AppTableHeaderCell('KEŞİF', flex: 3),
        AppTableHeaderCell('İLERLEME', flex: 3),
        AppTableHeaderCell('PLAN.', line2: 'KULL.', flex: 3),
      ],
    );
  }
}

class _ProgressTableRow extends StatefulWidget {
  const _ProgressTableRow({
    required this.row,
    required this.canEdit,
    required this.onProgressChanged,
  });

  final ProjectProgressRow row;
  final bool canEdit;
  final ValueChanged<double> onProgressChanged;

  @override
  State<_ProgressTableRow> createState() => _ProgressTableRowState();
}

class _ProgressTableRowState extends State<_ProgressTableRow> {
  late final TextEditingController _controller;
  bool _isEditing = false;
  double? _draftPercent;
  Timer? _persistTimer;

  static const _persistDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatPercent(widget.row.progressPercent),
    );
  }

  @override
  void didUpdateWidget(covariant _ProgressTableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing &&
        oldWidget.row.progressPercent != widget.row.progressPercent) {
      _controller.text = _formatPercent(widget.row.progressPercent);
      _draftPercent = null;
    }
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _formatPercent(double value) {
    final rounded = value.round().clamp(0, 100);
    return rounded == 0 ? '' : '$rounded';
  }

  double get _displayPercent =>
      _draftPercent ?? widget.row.progressPercent;

  double get _displayExpected => computeLinePlannedUsage(
        planned: widget.row.plannedTonnage,
        progressPercent: _displayPercent,
      );

  void _onTextChanged(String value) {
    setState(() {
      _isEditing = true;
      final parsed = int.tryParse(value.trim());
      _draftPercent =
          parsed == null ? 0 : parsed.clamp(0, 100).toDouble();
    });
    _schedulePersist();
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDelay, _persistProgress);
  }

  void _persistProgress() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) return;

    final clamped = parsed.clamp(0, 100).toDouble();
    if (clamped != widget.row.progressPercent) {
      widget.onProgressChanged(clamped);
    }
  }

  void _commitProgress() {
    _persistTimer?.cancel();
    _isEditing = false;
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      setState(() {
        _draftPercent = null;
        _controller.text = _formatPercent(widget.row.progressPercent);
      });
      return;
    }
    final clamped = parsed.clamp(0, 100).toDouble();
    _controller.text = clamped == 0 ? '' : '${clamped.round()}';
    setState(() => _draftPercent = null);
    if (clamped != widget.row.progressPercent) {
      widget.onProgressChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final percent = _displayPercent.round().clamp(0, 100);
    final capLabel =
        row.diameter == null ? '—' : 'Ø${row.diameter}';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  capLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: row.diameter == null
                        ? AppColors.textMuted
                        : AppColors.diameterColor(row.diameter!),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '${AppFormat.tonnage(row.plannedTonnage)}t',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(child: _buildProgressCell(percent)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '${AppFormat.tonnage(_displayExpected)}t',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: AnimatedProgressBar(
              percent: percent.toDouble(),
              color: AppColors.electricBlueLight,
              height: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCell(int percent) {
    if (!widget.canEdit) {
      return Text(
        '$percent%',
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.electricBlueLight,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 38,
          height: 32,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.electricBlueLight,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: AppRadii.sm,
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.sm,
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            onTap: () => _isEditing = true,
            onSubmitted: (_) => _commitProgress(),
            onEditingComplete: _commitProgress,
            onChanged: _onTextChanged,
          ),
        ),
        Text(
          '%',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.electricBlueLight,
          ),
        ),
      ],
    );
  }
}
