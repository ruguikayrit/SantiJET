import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_batch_list_panel.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_comparison_section.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_fire_summary.dart';
import 'package:santijet_demir/features/analysis/widgets/collapsible_analysis_section.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_optimization_results.dart';
import 'package:santijet_demir/features/analysis/widgets/stock_cut_section.dart';
import 'package:santijet_demir/features/analysis/widgets/tahvil_calculator_section.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/metraj_cutting_actions.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/rebar_label_details_section.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  static const _innerCardGap = AppSpacing.xs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cuttingBendingBatchesProvider);
    final batch = state.activeBatch;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'HESAP VE ANALİZ', showNotification: false),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: CollapsibleAnalysisSection(
                  sectionId: AnalysisSectionIds.tahvilCalculator,
                  title: 'Araç · Tahvil Hesaplayıcı',
                  subtitle: 'Manuel tahvil denemesi — analizden bağımsız referans aracı',
                  headerAccentColor: AppColors.diameter28,
                  child: const TahvilCalculatorSection(hideHeader: true),
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
            if (batch == null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('Analiz listesi boş', style: AppTypography.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Ön imalattan onaylı metraj alın; boy eşleştirme ve '
                        'kesim planı ile fireyi düşürün.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            showPreProductionAnalysisImportSheet(context, ref),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Ön İmalattan Veri Al'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ]
            else ...[
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
                    activeBatchId: state.activeBatchId,
                    onSelectBatch: (id) => ref
                        .read(cuttingBendingBatchesProvider.notifier)
                        .setActiveBatch(id),
                    onDeleteSelected: (ids) =>
                        _confirmDeleteBatches(context, ref, ids),
                    onImportFromPreProduction: () =>
                        showPreProductionAnalysisImportSheet(context, ref),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: _BatchHeader(batch: batch),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: AnalysisFireSummaryPanel(batch: batch),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    CollapsibleAnalysisSection(
                      sectionId: AnalysisSectionIds.comparison,
                      title: 'Mukayese',
                      subtitle: 'Kaynak, revize ve strateji sonuçlarını karşılaştırın',
                      child: AnalysisComparisonSection(batch: batch),
                    ),
                    CollapsibleAnalysisSection(
                      sectionId: AnalysisSectionIds.dataSource,
                      title: '1 · Kaynak Veri',
                      subtitle: 'Metraj etiketleri ve ham parça listesi',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (batch.labelDetails.isNotEmpty) ...[
                            Text('Etiketler', style: AppTypography.labelMedium),
                            const SizedBox(height: 8),
                            RebarLabelDetailsSection(
                              details: batch.labelDetails,
                              hideHeader: true,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text('Ham parça listesi', style: AppTypography.labelMedium),
                          const SizedBox(height: 8),
                          _PieceListTable(pieces: batch.pieceLines),
                        ],
                      ),
                    ),
                    CollapsibleAnalysisSection(
                      sectionId: AnalysisSectionIds.optimizationPipeline,
                      title: '2 · Fire Azaltma',
                      subtitle: 'Otomatik fire azaltma sonuçları',
                      child: !batch.isOptimized
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.auto_fix_high_outlined,
                                    size: 40,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Fire azaltma analizi henüz çalıştırılmadı.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Fire Özeti bölümünden strateji seçip '
                                    '"Fire Analizini Başlat" butonuna basın.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : AnalysisOptimizationResultsSection(batch: batch),
                    ),
                    CollapsibleAnalysisSection(
                      sectionId: AnalysisSectionIds.plannedCutting,
                      title: '3 · Planlı Kesim',
                      subtitle:
                          'Revize listeden ${CuttingBendingBatch.defaultStockBarLengthM.toStringAsFixed(0)} m '
                          'stok minimum fire kesim planı',
                      child: !batch.isOptimized
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Planlı kesim, optimum fire analizi '
                                'tamamlandıktan sonra burada görünür.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : batch.stockCutPlans.isEmpty
                              ? const ModuleEmptyState(
                                  type: EmptyStateType.noSearchResult,
                                  inline: true,
                                )
                              : StockCutSection(
                                  batchId: batch.id,
                                  plans: batch.stockCutPlans,
                                ),
                    ),
                  ]),
                ),
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
    ScaffoldMessenger.of(context).showSnackBar(
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

class _BatchHeader extends StatelessWidget {
  const _BatchHeader({required this.batch});

  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final totalPieces = batch.pieceLines.fold(0, (sum, p) => sum + p.quantity);

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
                    AppColors.partial.withValues(alpha: 0.9),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.partial.withValues(alpha: 0.22),
                              AppColors.partial.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.partial.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: AppColors.electricBlueLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.title,
                              style: AppTypography.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MetaChip(
                                  icon: Icons.schedule,
                                  label: dateFormat.format(batch.createdAt),
                                ),
                                _MetaChip(
                                  icon: Icons.format_list_numbered,
                                  label: '${AppFormat.integer(totalPieces)} adet',
                                ),
                                _MetaChip(
                                  icon: Icons.table_rows_outlined,
                                  label: '${batch.pieceLines.length} satır',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.full,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceListTable extends StatelessWidget {
  const _PieceListTable({required this.pieces});

  final List<RebarPieceLine> pieces;

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) {
      return const ModuleEmptyState(type: EmptyStateType.noSearchResult, inline: true);
    }

    return Column(
      children: [
        const _TableHeader(cells: ['ÇAP', 'BOY (m)', 'ADET']),
        ...pieces.map(
          (piece) => _TableRow(
            cells: [
              'Ø${piece.diameter}',
              piece.lengthM.toStringAsFixed(2),
              AppFormat.integer(piece.quantity),
            ],
            accentColor: AppColors.diameterColor(piece.diameter),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.cells});

  final List<String> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: Text(
                cells[i],
                style: AppTypography.labelMedium,
                textAlign: i == cells.length - 1 ? TextAlign.end : TextAlign.start,
              ),
            ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, this.accentColor});

  final List<String> cells;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: Text(
                cells[i],
                style: (i == 0 ? AppTypography.titleMedium : AppTypography.bodyMedium)
                    .copyWith(color: i == 0 ? accentColor : null),
                textAlign: i == cells.length - 1 ? TextAlign.end : TextAlign.start,
              ),
            ),
        ],
      ),
    );
  }
}
