import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/app_description_lines.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_fire_summary_details.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_report_actions.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

class AnalysisFireSummaryPanel extends ConsumerStatefulWidget {
  const AnalysisFireSummaryPanel({
    super.key,
    required this.batch,
    required this.sourceBatches,
  });

  final CuttingBendingBatch batch;
  final List<CuttingBendingBatch> sourceBatches;

  @override
  ConsumerState<AnalysisFireSummaryPanel> createState() =>
      _AnalysisFireSummaryPanelState();
}

class _AnalysisFireSummaryPanelState
    extends ConsumerState<AnalysisFireSummaryPanel> {
  FireSummaryDetailKind? _expandedDetail;

  @override
  void didUpdateWidget(covariant AnalysisFireSummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batch.id != widget.batch.id) {
      _expandedDetail = null;
    }
  }

  void _toggleDetail(FireSummaryDetailKind kind) {
    setState(() {
      _expandedDetail = _expandedDetail == kind ? null : kind;
    });
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final summary = ref.watch(analysisFireSummaryProvider) ??
        const AnalysisFireSummary(
          rawMaterialTonnage: 0,
          rawStockTonnage: 0,
          rawWasteTonnage: 0,
          rawWastePercent: 0,
        );
    final comparison = ref.watch(analysisComparisonProvider);
    final progress = ref.watch(optimumFireAnalysisProgressProvider);
    final analysisError = ref.watch(optimumFireAnalysisErrorProvider);
    final progressForBatch = progress.appliesTo(batch.id);
    final isRunning = progress.isRunning && progressForBatch;
    final isCompleted = progress.isCompleted && progressForBatch;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.cardBorderSubtle),
        boxShadow: AppColors.cardElevation.isEmpty
            ? const [
                BoxShadow(
                  color: AppColors.electricBlueGlow,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ]
            : [
                ...AppColors.cardElevation,
                const BoxShadow(
                  color: AppColors.electricBlueGlow,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.85),
                    AppColors.electricBlueLight.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_outlined,
                          color: AppColors.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FİRE ÖZETİ',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.cardTextPrimary,
                                fontSize:
                                    (AppTypography.titleMedium.fontSize ?? 14) *
                                        1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _ActiveKpiCard(
                                active: _expandedDetail ==
                                    FireSummaryDetailKind.rawMaterial,
                                child: KpiCard(
                                  label: 'Ham Tonaj',
                                  value: AppFormat.tonnage(
                                    summary.rawMaterialTonnage,
                                  ),
                                  unit: 't',
                                  accentColor: AppColors.electricBlueLight,
                                  dense: true,
                                  onTap: () => _toggleDetail(
                                    FireSummaryDetailKind.rawMaterial,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActiveKpiCard(
                                active: _expandedDetail ==
                                    FireSummaryDetailKind.rawFire,
                                child: KpiCard(
                                  label: 'Ham Fire',
                                  value: AppFormat.tonnage(
                                    summary.rawWasteTonnage,
                                  ),
                                  unit: 't',
                                  percent:
                                      '%${summary.rawWastePercent.toStringAsFixed(1)}',
                                  accentColor: AppColors.warning,
                                  dense: true,
                                  onTap: () => _toggleDetail(
                                    FireSummaryDetailKind.rawFire,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (batch.isOptimized) ...[
                        const SizedBox(height: 8),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _ActiveKpiCard(
                                  active: _expandedDetail ==
                                      FireSummaryDetailKind.plannedFire,
                                  child: KpiCard(
                                    label: 'Kesim Fire',
                                    value: summary.isPlannedReady
                                        ? AppFormat.tonnage(
                                            summary.plannedWasteTonnage!,
                                          )
                                        : '—',
                                    unit:
                                        summary.isPlannedReady ? 't' : '',
                                    percent: summary.isPlannedReady
                                        ? '%${summary.plannedWastePercent!.toStringAsFixed(1)}'
                                        : null,
                                    accentColor: summary.isPlannedReady
                                        ? _fireColor(
                                            summary.plannedWastePercent!,
                                          )
                                        : AppColors.cardTextMuted,
                                    dense: true,
                                    onTap: summary.isPlannedReady
                                        ? () => _toggleDetail(
                                              FireSummaryDetailKind
                                                  .plannedFire,
                                            )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ActiveKpiCard(
                                  active: _expandedDetail ==
                                      FireSummaryDetailKind.savings,
                                  child: KpiCard(
                                    label: 'Kazanç',
                                    value: summary.savedWasteTonnage > 0
                                        ? AppFormat.tonnage(
                                            summary.savedWasteTonnage,
                                          )
                                        : '—',
                                    unit: summary.savedWasteTonnage > 0
                                        ? 't'
                                        : '',
                                    percent: summary.savedWastePercent > 0
                                        ? '−%${summary.savedWastePercent.toStringAsFixed(1)}'
                                        : null,
                                    accentColor: AppColors.success,
                                    dense: true,
                                    onTap: summary.isPlannedReady
                                        ? () => _toggleDetail(
                                              FireSummaryDetailKind.savings,
                                            )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_expandedDetail != null)
                    FireSummaryDetailPanel(
                      kind: _expandedDetail!,
                      batch: batch,
                      summary: summary,
                      comparison: comparison,
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Detay görmek için karta dokunun',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.cardTextMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (isCompleted) ...[
                    const SizedBox(height: 14),
                    _AnalysisCompletedBanner(stepLabel: progress.stepLabel),
                  ],
                  if (isRunning) ...[
                    const SizedBox(height: 14),
                    _OptimumFireAnalysisProgressPanel(
                      percent: progress.percent,
                      stepLabel: progress.stepLabel,
                    ),
                  ] else if (analysisError != null) ...[
                    const SizedBox(height: 14),
                    _AnalysisErrorBanner(message: analysisError),
                  ] else if (!isRunning) ...[
                    if (!batch.isOptimized) ...[
                      const SizedBox(height: 14),
                      _MinimumFireAnalysisPanel(
                        enabled: batch.pieceLines.isNotEmpty,
                        onStart: () => confirmAndRunFireAnalysis(
                          context: context,
                          ref: ref,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const SizedBox(height: 12),
                    ],
                    AnalysisReportActions(
                      batch: batch,
                      sourceBatches: widget.sourceBatches,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _fireColor(double percent) {
    if (percent <= 1.5) return AppColors.success;
    if (percent <= 4) return AppColors.warning;
    return AppColors.critical;
  }
}

/// DWG listesi / Fire özeti ortak giriş: minimum fire kesim analizi.
Future<void> confirmAndRunFireAnalysis({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Fire Analizi'),
        content: const Text(
          'Zayiatsız kesim planı ve minimum fire için aynı çapta boy '
          'eşleştirme uygulanacak.\n\n'
          'Fire analizini başlatmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Analizi Başlat'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  await ref
      .read(cuttingBendingBatchesProvider.notifier)
      .runOptimumFireAnalysis();
}

/// Geriye dönük alias.
Future<void> confirmAndRunTahvilFireAnalysis({
  required BuildContext context,
  required WidgetRef ref,
}) =>
    confirmAndRunFireAnalysis(context: context, ref: ref);

class _ActiveKpiCard extends StatelessWidget {
  const _ActiveKpiCard({
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.md,
        border: Border.all(
          color: AppColors.electricBlueLight.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlueGlow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MinimumFireAnalysisPanel extends StatelessWidget {
  const _MinimumFireAnalysisPanel({
    required this.enabled,
    required this.onStart,
  });

  final bool enabled;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppDescriptionLines(
          [
            'Zayiatsız kesim planı ve minimum fire hedeflenir.',
            'Çap değiştirilmez; yakın boylar eşleştirilerek stok kesimi yapılır.',
          ],
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        _MatteGreenGradientButton(
          onPressed: enabled ? () => onStart() : null,
          icon: Icons.content_cut_outlined,
          label: 'Fire analizi yap',
        ),
      ],
    );
  }
}

class _OptimumFireAnalysisProgressPanel extends StatelessWidget {
  const _OptimumFireAnalysisProgressPanel({
    required this.percent,
    required this.stepLabel,
  });

  final int percent;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0, 100);
    final progressValue = clampedPercent / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 4,
                      backgroundColor: AppColors.cardBorder,
                      color: AppColors.success,
                    ),
                    Text(
                      '$clampedPercent%',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analiz devam ediyor',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.cardTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadii.full,
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: AppColors.cardBorder,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisErrorBanner extends StatelessWidget {
  const _AnalysisErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.cardTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCompletedBanner extends StatelessWidget {
  const _AnalysisCompletedBanner({required this.stepLabel});

  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiz tamamlandı',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
                if (stepLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    stepLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatteGreenGradientButton extends StatelessWidget {
  const _MatteGreenGradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  static const _enabledGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B6B50),
      Color(0xFF0F8566),
      Color(0xFF0A7258),
    ],
  );

  static const _disabledGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2E28),
      Color(0xFF1F3530),
      Color(0xFF1A2E28),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.md,
      elevation: enabled ? 2 : 0,
      shadowColor: enabled
          ? AppColors.success.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.md,
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Ink(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            gradient: enabled ? _enabledGradient : _disabledGradient,
            border: Border.all(
              color: enabled
                  ? const Color(0xFF14A07A).withValues(alpha: 0.55)
                  : AppColors.cardBorder,
              width: enabled ? 1.25 : 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: enabled
                    ? const Color(0xFFE8FFF5)
                    : AppColors.cardTextDisabled,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: enabled
                        ? Colors.white
                        : AppColors.cardTextDisabled,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                    fontSize: (AppTypography.titleMedium.fontSize ?? 14) * 1.125,
                    height: 0.825 * 0.75,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisStepHeader extends StatelessWidget {
  const AnalysisStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    this.complete = false,
  });

  final int step;
  final String title;
  final String subtitle;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.success : AppColors.electricBlueLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: complete
                ? Icon(Icons.check, size: 16, color: color)
                : Text(
                    '$step',
                    style: AppTypography.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.cardTextMuted,
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
