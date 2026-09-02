import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/shell_tab_guard.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_batch_list_panel.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_fire_summary.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/metraj_cutting_actions.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final state = ref.watch(cuttingBendingBatchesProvider);
    final analysisScope = ref.watch(selectedAnalysisBatchIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'Hesap / Analiz / Rapor'),
            ),
            if (!hasActiveProject)
              const ActiveProjectSliverGate()
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _ReportsQuickAccessBar(
                    onTap: () => context.push(AppRoutes.reports),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Amaç: demir firesi azaltmak ve planlı kesim üretmek',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              if (state.batches.isEmpty) ...[
                SliverToBoxAdapter(
                  child: ModuleEmptyState(
                    type: EmptyStateType.noAnalysis,
                    actionLabel: 'İmalattan Veri Al',
                    onAction: () => showImalatAnalysisImportSheet(context, ref),
                  ),
                ),
              ] else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: AnalysisBatchListPanel(
                    batches: state.batches,
                    analysisScopeIds: analysisScope,
                    onScopeChanged: (scope) => ref
                        .read(cuttingBendingBatchesProvider.notifier)
                        .setAnalysisScope(scope),
                    onDeleteSelected: (ids) =>
                        _confirmDeleteBatches(context, ref, ids),
                    onImportFromPreProduction: () =>
                        showImalatAnalysisImportSheet(context, ref),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _AnalysisSelectedBatchArea()),
              ],
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
              ),
            ],
          ],
        ),
    );
  }

  Future<void> _confirmDeleteBatches(
    BuildContext context,
    WidgetRef ref,
    Set<String> batchIds,
  ) async {
    if (batchIds.isEmpty) return;

    final state = ref.read(cuttingBendingBatchesProvider);
    final titles = state.batches
        .where((batch) => batchIds.contains(batch.id))
        .map((batch) => batch.title)
        .toList();
    final preview = titles.take(3).join('\n• ');
    final extra = titles.length > 3 ? '\n… ve ${titles.length - 3} dosya daha' : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          batchIds.length == 1 ? 'Listeyi sil' : '${batchIds.length} listeyi sil',
        ),
        content: Text(
          batchIds.length == 1
              ? '"${titles.first}" analiz listesini silmek istediğinize emin misiniz?'
              : 'Seçili ${batchIds.length} analiz listesini silmek istediğinize '
                  'emin misiniz?\n\n• $preview$extra',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(cuttingBendingBatchesProvider.notifier)
        .deleteBatches(batchIds);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(
        content: Text(
          batchIds.length == 1
              ? 'Analiz listesi silindi.'
              : '${batchIds.length} analiz listesi silindi.',
        ),
      ),
    );
  }
}

class _AnalysisSelectedBatchArea extends ConsumerWidget {
  const _AnalysisSelectedBatchArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(mergedAnalysisBatchProvider);
    final state = ref.watch(cuttingBendingBatchesProvider);
    final analysisScope = ref.watch(selectedAnalysisBatchIdsProvider);
    final scopedBatches = state.batches
        .where((item) => analysisScope.contains(item.id))
        .toList();

    if (batch == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_box_outline_blank,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Analiz için dosya seçin',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Yukarıdaki listeden analize almak istediğiniz '
                'DWG dosyalarını işaretleyin. Tüm dosyaları birlikte '
                'seçmek minimum fire için en doğru yöntemdir.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, AppSpacing.md),
      child: AnalysisFireSummaryPanel(
        batch: batch,
        sourceBatches: scopedBatches,
      ),
    );
  }
}

class _ReportsQuickAccessBar extends StatelessWidget {
  const _ReportsQuickAccessBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadii.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.description, color: AppColors.partial, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Raporlar · 16 rapor hazır',
                style: AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
