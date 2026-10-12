import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
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
    final allImalatIds = {for (final row in summary.rows) row.imalatId};

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
      ],
    );
  }
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
            'Planlanan kullanım ${AppFormat.tonnage(totalExpected)} / '
            'Keşif ${AppFormat.tonnage(totalPlanned)}',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
