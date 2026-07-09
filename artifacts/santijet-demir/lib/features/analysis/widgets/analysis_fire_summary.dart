import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_fire_summary_details.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

class AnalysisFireSummaryPanel extends ConsumerStatefulWidget {
  const AnalysisFireSummaryPanel({super.key, required this.batch});

  final CuttingBendingBatch batch;

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
    final summary = computeAnalysisFireSummary(batch);
    final comparison =
        batch.isOptimized ? computeAnalysisComparison(batch) : null;
    final lengthMatchDone = isLengthMatchingComplete(batch.lengthMatches);
    final tahvilApproved =
        batch.tahvilGroups.where((group) => group.approved).length;
    final tahvilTotal = batch.tahvilGroups.length;
    final progress = ref.watch(optimumFireAnalysisProgressProvider);
    final analysisError = ref.watch(optimumFireAnalysisErrorProvider);
    final progressForBatch = progress.appliesTo(batch.id);
    final isRunning = progress.isRunning && progressForBatch;
    final isCompleted = progress.isCompleted && progressForBatch;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                            Text('Fire Özeti', style: AppTypography.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              batch.isOptimized
                                  ? 'Ham kaynak veri ile optimize sonuç karşılaştırması'
                                  : 'Ön imalat ham verisi — optimize analiz bekleniyor',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                              value: AppFormat.tonnage(summary.rawMaterialTonnage),
                              unit: 't',
                              accentColor: AppColors.electricBlueLight,
                              dense: true,
                              onTap: () =>
                                  _toggleDetail(FireSummaryDetailKind.rawMaterial),
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
                              value: AppFormat.tonnage(summary.rawWasteTonnage),
                              unit: 't',
                              percent:
                                  '%${summary.rawWastePercent.toStringAsFixed(1)}',
                              accentColor: AppColors.warning,
                              dense: true,
                              onTap: () =>
                                  _toggleDetail(FireSummaryDetailKind.rawFire),
                            ),
                          ),
                        ),
                        if (batch.isOptimized) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActiveKpiCard(
                              active: _expandedDetail ==
                                  FireSummaryDetailKind.plannedFire,
                              child: KpiCard(
                                label: 'Plan Fire',
                                value: summary.isPlannedReady
                                    ? AppFormat.tonnage(
                                        summary.plannedWasteTonnage!,
                                      )
                                    : '—',
                                unit: summary.isPlannedReady ? 't' : '',
                                percent: summary.isPlannedReady
                                    ? '%${summary.plannedWastePercent!.toStringAsFixed(1)}'
                                    : null,
                                accentColor: summary.isPlannedReady
                                    ? _fireColor(summary.plannedWastePercent!)
                                    : AppColors.textMuted,
                                dense: true,
                                onTap: summary.isPlannedReady
                                    ? () => _toggleDetail(
                                          FireSummaryDetailKind.plannedFire,
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
                                    ? AppFormat.tonnage(summary.savedWasteTonnage)
                                    : '—',
                                unit: summary.savedWasteTonnage > 0 ? 't' : '',
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
                      ],
                    ),
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
                        color: AppColors.textMuted,
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
                    const SizedBox(height: 14),
                    _FireReductionStrategyPanel(
                      batch: batch,
                      enabled: batch.pieceLines.isNotEmpty,
                      onStart: () => ref
                          .read(cuttingBendingBatchesProvider.notifier)
                          .runOptimumFireAnalysis(),
                      onSave: () async {
                        final strategy = ref.read(
                          selectedFireReductionStrategyProvider,
                        );
                        await ref
                            .read(cuttingBendingBatchesProvider.notifier)
                            .saveAnalysisResult();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${strategy.label} analizi kaydedildi'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                  if (batch.isOptimized) ...[
                    const SizedBox(height: 12),
                    if (batch.hasAnySavedOptimization)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final strategy in FireReductionStrategy.values)
                              if (batch.hasSavedOptimization(strategy))
                                _SavedStrategyChip(
                                  label: strategy.label,
                                  active: batch.optimizationStrategy == strategy &&
                                      batch.isOptimized,
                                ),
                          ],
                        ),
                      ),
                    if (batch.optimizationStrategy != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Strateji: ${batch.optimizationStrategy!.label}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.electricBlueLight,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PipelineChip(
                          label: 'Boy eşleştirme',
                          done: (batch.optimizationStrategy?.appliesLengthMatch ??
                                  false) &&
                              lengthMatchDone,
                          detail: !(batch.optimizationStrategy?.appliesLengthMatch ??
                              false)
                              ? 'Atlandı'
                              : lengthMatchDone
                                  ? '${batch.lengthMatches.length} grup'
                                  : 'Eksik',
                        ),
                        if (tahvilTotal > 0)
                          _PipelineChip(
                            label: 'Tahvil',
                            done: (batch.optimizationStrategy?.appliesTahvil ??
                                    false) &&
                                tahvilApproved > 0,
                            detail: !(batch.optimizationStrategy?.appliesTahvil ??
                                false)
                                ? 'Atlandı'
                                : '$tahvilApproved / $tahvilTotal',
                            optional: tahvilApproved == 0 &&
                                (batch.optimizationStrategy?.appliesTahvil ??
                                    false),
                          ),
                        _PipelineChip(
                          label: 'Kesim planı',
                          done: batch.stockCutPlans.isNotEmpty,
                          detail: batch.stockCutPlans.isNotEmpty
                              ? '${batch.stockCutPlans.length} çap'
                              : 'Yok',
                        ),
                      ],
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

class _FireReductionStrategyPanel extends ConsumerWidget {
  const _FireReductionStrategyPanel({
    required this.batch,
    required this.enabled,
    required this.onStart,
    required this.onSave,
  });

  final CuttingBendingBatch batch;
  final bool enabled;
  final VoidCallback onStart;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedFireReductionStrategyProvider);
    final notifier = ref.read(cuttingBendingBatchesProvider.notifier);
    final isSaved = batch.isCurrentOptimizationSaved;
    final canSave = batch.isOptimized && batch.optimizationStrategy == selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Fire azaltma stratejisi seçin',
          style: AppTypography.labelMedium,
        ),
        if (batch.hasAnySavedOptimization) ...[
          const SizedBox(height: 4),
          Text(
            'Kayıtlı stratejiye dokunarak sonucu yükleyin — '
            'tekrar analiz etmenize gerek kalmaz.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 10),
        ...FireReductionStrategy.values.map(
          (strategy) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StrategyOptionTile(
              strategy: strategy,
              selected: selected == strategy,
              saved: batch.hasSavedOptimization(strategy),
              isActiveView: batch.isOptimized &&
                  batch.optimizationStrategy == strategy,
              onTap: enabled
                  ? () => notifier.selectAnalysisStrategy(strategy)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _MatteGreenGradientButton(
          onPressed: enabled ? onStart : null,
          icon: Icons.auto_fix_high_outlined,
          label: batch.isOptimized && batch.optimizationStrategy == selected
              ? 'Analizi Yeniden Çalıştır'
              : 'Fire Analizini Başlat',
        ),
        if (canSave) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isSaved ? null : onSave,
            icon: Icon(
              isSaved ? Icons.check_circle_outline : Icons.save_outlined,
              size: 18,
            ),
            label: Text(
              isSaved
                  ? 'Kaydedildi'
                  : batch.hasSavedOptimization(selected)
                      ? 'Kaydı Güncelle'
                      : 'Analizi Kaydet',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isSaved
                  ? AppColors.success
                  : AppColors.electricBlueLight,
              side: BorderSide(
                color: isSaved
                    ? AppColors.success.withValues(alpha: 0.45)
                    : AppColors.electricBlueLight.withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedStrategyChip extends StatelessWidget {
  const _SavedStrategyChip({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.canvas,
        borderRadius: AppRadii.full,
        border: Border.all(
          color: active
              ? AppColors.success.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.save_outlined,
            size: 12,
            color: active ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: active ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyOptionTile extends StatelessWidget {
  const _StrategyOptionTile({
    required this.strategy,
    required this.selected,
    this.saved = false,
    this.isActiveView = false,
    this.onTap,
  });

  final FireReductionStrategy strategy;
  final bool selected;
  final bool saved;
  final bool isActiveView;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.success.withValues(alpha: 0.08)
          : AppColors.canvas,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected
                  ? AppColors.success.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: selected ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(strategy.label, style: AppTypography.bodyMedium),
                        ),
                        if (saved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlueLight
                                  .withValues(alpha: 0.12),
                              borderRadius: AppRadii.full,
                            ),
                            child: Text(
                              'Kayıtlı',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.electricBlueLight,
                              ),
                            ),
                          ),
                        if (isActiveView) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: AppRadii.full,
                            ),
                            child: Text(
                              'Aktif',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      strategy.description,
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
                      backgroundColor: AppColors.border,
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
                        color: AppColors.textMuted,
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
              backgroundColor: AppColors.border,
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
                color: AppColors.textPrimary,
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
                      color: AppColors.textMuted,
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
                  : AppColors.border,
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
                    : AppColors.textDisabled,
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
                        : AppColors.textDisabled,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                    height: 1.1,
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

class _PipelineChip extends StatelessWidget {
  const _PipelineChip({
    required this.label,
    required this.done,
    required this.detail,
    this.optional = false,
  });

  final String label;
  final bool done;
  final String detail;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.canvas,
        borderRadius: AppRadii.full,
        border: Border.all(
          color: done
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            optional ? '$label (ops.)' : label,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
          const SizedBox(width: 6),
          Text(
            detail,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
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
                    color: AppColors.textMuted,
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
