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

class ProjectProgressSection extends ConsumerStatefulWidget {
  const ProjectProgressSection({super.key});

  @override
  ConsumerState<ProjectProgressSection> createState() =>
      _ProjectProgressSectionState();
}

class _ProjectProgressSectionState
    extends ConsumerState<ProjectProgressSection> {
  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(projectProgressSummaryProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final groupedRows = _groupProgressRows(summary.rows);

    Future<void> applyToImalats(Set<String> imalatIds, double progressPercent) async {
      if (imalatIds.isEmpty) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(surveyProjectProvider.notifier).updateProgressForImalats(
              imalatIds: imalatIds,
              progressPercent: progressPercent,
            );
      } catch (_) {
        if (!mounted) return;
        messenger.showAppSnackBar(
          const SnackBar(content: Text('İlerleme kaydedilemedi')),
        );
      }
    }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proje İlerleme Durumu', style: AppTypography.headlineMedium),
        const SizedBox(height: 12),
        _OverallProgressCard(
          percent: overallPercent,
          totalPlanned: summary.totalPlanned,
          totalExpected: summary.totalExpected,
          canEdit: canEdit,
          onPercentCommitted: (value) => applyToImalats(allImalatIds, value),
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
                  onHeadingPercent: (value) => applyToImalats(
                    {entry.$2.first.imalatId},
                    value,
                  ),
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

class _ManualPercentField extends StatefulWidget {
  const _ManualPercentField({
    required this.percent,
    required this.enabled,
    required this.onCommitted,
    this.large = false,
  });

  final double percent;
  final bool enabled;
  final ValueChanged<double> onCommitted;
  final bool large;

  @override
  State<_ManualPercentField> createState() => _ManualPercentFieldState();
}

class _ManualPercentFieldState extends State<_ManualPercentField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _text(widget.percent));
    _focus = FocusNode()..addListener(_handleFocus);
  }

  void _handleFocus() {
    if (!mounted) return;
    if (_focus.hasFocus) {
      _editing = true;
      return;
    }
    _commit();
  }

  @override
  void didUpdateWidget(covariant _ManualPercentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.percent != widget.percent) {
      _controller.text = _text(widget.percent);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _text(double value) {
    final rounded = value.round().clamp(0, 100);
    return rounded == 0 ? '' : '$rounded';
  }

  void _commit() {
    setState(() => _editing = false);
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = _text(widget.percent);
      return;
    }
    final clamped = parsed.clamp(0, 100).toDouble();
    _controller.text = clamped == 0 ? '' : '${clamped.round()}';
    if (clamped != widget.percent) {
      widget.onCommitted(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.large
        ? AppTypography.kpiValue.copyWith(
            fontSize: AppTypography.scale * 28,
            color: AppColors.electricBlueLight,
          )
        : AppTypography.labelMedium.copyWith(
            color: AppColors.electricBlueLight,
            fontWeight: FontWeight.w700,
          );

    return SizedBox(
      width: widget.large ? 88 : 64,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        style: style,
        decoration: InputDecoration(
          isDense: true,
          suffixText: '%',
          suffixStyle: style,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: const OutlineInputBorder(),
        ),
        onTap: () => _editing = true,
        onChanged: (_) => _editing = true,
        onTapOutside: (_) => _focus.unfocus(),
        onEditingComplete: () => _focus.unfocus(),
        onSubmitted: (_) => _focus.unfocus(),
      ),
    );
  }
}

class _ProgressImalatGroup extends StatefulWidget {
  const _ProgressImalatGroup({
    required this.rows,
    required this.isFirst,
    required this.canEdit,
    required this.onHeadingPercent,
    required this.onProgressChanged,
  });

  final List<ProjectProgressRow> rows;
  final bool isFirst;
  final bool canEdit;
  final ValueChanged<double> onHeadingPercent;
  final void Function(ProjectProgressRow row, double value) onProgressChanged;

  @override
  State<_ProgressImalatGroup> createState() => _ProgressImalatGroupState();
}

class _ProgressImalatGroupState extends State<_ProgressImalatGroup> {
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
                  : BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _ManualPercentField(
                percent: overallPercent.toDouble(),
                enabled: widget.canEdit,
                onCommitted: widget.onHeadingPercent,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        if (_expanded)
          ...rows.map(
            (row) => _ProgressTableRow(
              row: row,
              canEdit: widget.canEdit,
              onProgressChanged: (value) => widget.onProgressChanged(row, value),
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
    required this.canEdit,
    required this.onPercentCommitted,
  });

  final int percent;
  final double totalPlanned;
  final double totalExpected;
  final bool canEdit;
  final ValueChanged<double> onPercentCommitted;

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
              _ManualPercentField(
                percent: percent.toDouble(),
                enabled: canEdit,
                large: true,
                onCommitted: onPercentCommitted,
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
        AppTableHeaderCell('PLAN. KULL.', flex: 3),
        AppTableHeaderCell('İLERLEME', flex: 3),
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
  late final FocusNode _focus;
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
    _focus = FocusNode()..addListener(_handleFocus);
  }

  void _handleFocus() {
    if (!mounted) return;
    if (_focus.hasFocus) {
      _isEditing = true;
      return;
    }
    _commitProgress();
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
    _focus.removeListener(_handleFocus);
    _focus.dispose();
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
                child: Text(
                  '${AppFormat.tonnage(_displayExpected)}t',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(child: _buildProgressCell(percent)),
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
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
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
            onTapOutside: (_) => _focus.unfocus(),
            onSubmitted: (_) => _focus.unfocus(),
            onEditingComplete: () => _focus.unfocus(),
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
