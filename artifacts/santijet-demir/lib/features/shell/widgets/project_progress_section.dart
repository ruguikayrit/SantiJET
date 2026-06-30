import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/shell/project_progress_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class ProjectProgressSection extends ConsumerWidget {
  const ProjectProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(projectProgressSummaryProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);

    if (summary.rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proje İlerleme Durumu', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Beklenen miktar = keşif tonajı × ilerleme oranı',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          const ModuleEmptyState(type: EmptyStateType.noSurvey, inline: true),
        ],
      );
    }

    final overallPercent = summary.overallProgressPercent.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proje İlerleme Durumu', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Proje ilerleme = beklenen toplam / keşif miktarı',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 12),
        _OverallProgressCard(
          percent: overallPercent,
          totalPlanned: summary.totalPlanned,
          totalExpected: summary.totalExpected,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const _ProgressTableHeader(),
              ...summary.rows.map(
                (row) => _ProgressTableRow(
                  row: row,
                  canEdit: canEdit,
                  onProgressChanged: (value) {
                    final notifier = ref.read(surveyProjectProvider.notifier);
                    if (row.diameter == null) {
                      notifier.updateImalatProgress(
                        imalatId: row.imalatId,
                        progressPercent: value,
                      );
                    } else {
                      notifier.updateDiameterLineProgress(
                        imalatId: row.imalatId,
                        diameter: row.diameter!,
                        progressPercent: value,
                      );
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
              Text(
                '%$percent',
                style: AppTypography.kpiValue.copyWith(
                  fontSize: 28,
                  color: AppColors.electricBlueLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PercentBar(
            percent: percent.toDouble(),
            color: AppColors.electricBlueLight,
            height: 10,
          ),
          const SizedBox(height: 10),
          Text(
            'Beklenen ${AppFormat.tonnage(totalExpected)}t / Keşif ${AppFormat.tonnage(totalPlanned)}t',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('İMALAT', style: _headerStyle)),
          Expanded(flex: 2, child: Text('ÇAP', style: _headerStyle)),
          Expanded(flex: 2, child: Text('KEŞİF', style: _headerStyle)),
          Expanded(flex: 2, child: Text('İLERLEME', style: _headerStyle)),
          Expanded(flex: 2, child: Text('BEKLENEN', style: _headerStyle)),
        ],
      ),
    );
  }

  TextStyle get _headerStyle =>
      AppTypography.labelSmall.copyWith(color: AppColors.textMuted);
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(row.imalatName, style: AppTypography.titleMedium),
              ),
              Expanded(
                flex: 2,
                child: Text(capLabel, style: AppTypography.bodyMedium),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${AppFormat.tonnage(row.plannedTonnage)}t',
                  style: AppTypography.bodyMedium,
                ),
              ),
              Expanded(
                flex: 2,
                child: widget.canEdit
                    ? TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
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
                            horizontal: 8,
                            vertical: 6,
                          ),
                          hintText: '0',
                          suffixText: '%',
                          suffixStyle: AppTypography.bodySmall,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.sm,
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadii.sm,
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onTap: () => _isEditing = true,
                        onSubmitted: (_) => _commitProgress(),
                        onEditingComplete: _commitProgress,
                        onChanged: _onTextChanged,
                      )
                    : Text(
                        '%$percent',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.electricBlueLight,
                        ),
                      ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${AppFormat.tonnage(_displayExpected)}t',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PercentBar(
            percent: percent.toDouble(),
            color: AppColors.electricBlueLight,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _PercentBar extends StatelessWidget {
  const _PercentBar({
    required this.percent,
    required this.color,
    this.height = 8,
  });

  final double percent;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ratio = (percent / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: AppRadii.full,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.border),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
