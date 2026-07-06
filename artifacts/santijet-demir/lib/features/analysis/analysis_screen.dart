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
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_batch_list_panel.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_fire_summary.dart';
import 'package:santijet_demir/features/analysis/widgets/collapsible_analysis_section.dart';
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'HESAP VE ANALİZ', showNotification: false),
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
                  child: _BatchHeader(
                    batch: batch,
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
                              onDeleteDetail: (detail) =>
                                  _confirmDeleteLabel(context, ref, detail),
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
                      subtitle:
                          'Boy eşleştirme → tahvil → revize parça listesi',
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
                                    'Fire azaltma adımları henüz çalıştırılmadı.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Üstteki Optimum Fire Analizi butonuna basın; '
                                    'sistem boy eşleştirme, tahvil ve revize listeyi '
                                    'otomatik oluşturur.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnalysisStepHeader(
                            step: 1,
                            title: 'Boy Eşleştirme',
                            subtitle:
                                'Yakın boyları birleştirerek çeşit azaltın',
                            complete: isLengthMatchingComplete(batch.lengthMatches),
                          ),
                          _LengthMatchToleranceField(
                            toleranceCm: batch.lengthMatchToleranceCm,
                            onApply: (toleranceCm) => ref
                                .read(cuttingBendingBatchesProvider.notifier)
                                .setLengthMatchTolerance(toleranceCm),
                          ),
                          const SizedBox(height: 8),
                          if (batch.lengthMatches.isEmpty)
                            const ModuleEmptyState(
                              type: EmptyStateType.noSearchResult,
                              inline: true,
                            )
                          else
                            ...batch.lengthMatches.map(
                              (group) => _LengthMatchCard(
                                group: group,
                                onApprove: (approved, selectedLengthM) => ref
                                    .read(cuttingBendingBatchesProvider.notifier)
                                    .approveLengthMatch(
                                      group.id,
                                      approved: approved,
                                      selectedLengthM: selectedLengthM,
                                    ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 16),
                          AnalysisStepHeader(
                            step: 2,
                            title: 'Tahvil Önerileri',
                            subtitle:
                                'Farklı çaplarda yakın boylar — opsiyonel fire azaltma',
                            complete: batch.tahvilGroups.any((g) => g.approved),
                          ),
                          if (batch.tahvilGroups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Bu liste için tahvil önerisi yok.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          else
                            ...batch.tahvilGroups.map(
                              (group) => _TahvilCard(
                                group: group,
                                onApprove: (approved) => ref
                                    .read(cuttingBendingBatchesProvider.notifier)
                                    .approveTahvil(group.id, approved: approved),
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 16),
                          AnalysisStepHeader(
                            step: 3,
                            title: 'Revize Parça Listesi',
                            subtitle:
                                'Boy eşleştirme onaylarına göre güncellenmiş liste',
                            complete: isLengthMatchingComplete(batch.lengthMatches),
                          ),
                          batch.revisedPieceLines.isEmpty
                              ? const ModuleEmptyState(
                                  type: EmptyStateType.noSearchResult,
                                  inline: true,
                                )
                              : _PieceListTable(pieces: batch.revisedPieceLines),
                        ],
                      ),
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
                    CollapsibleAnalysisSection(
                      sectionId: AnalysisSectionIds.tahvilCalculator,
                      title: 'Araç · Tahvil Hesaplayıcı',
                      subtitle:
                          'Manuel tahvil denemesi — πr² kesit kuralları',
                      child: const TahvilCalculatorSection(hideHeader: true),
                    ),
                  ]),
                ),
              ),
            ],
          ],
        ),
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

  Future<void> _confirmDeleteLabel(
    BuildContext context,
    WidgetRef ref,
    RebarMetrajTextDetail detail,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etiketi sil'),
        content: const Text(
          'Bu etiketi listeden kaldırmak parça listesini ve tahvil önerilerini yeniden hesaplar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(cuttingBendingBatchesProvider.notifier).removeLabelDetail(detail);
  }
}

class _BatchHeader extends StatelessWidget {
  const _BatchHeader({
    required this.batch,
    required this.onImportFromPreProduction,
  });

  final CuttingBendingBatch batch;
  final VoidCallback onImportFromPreProduction;

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
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                  Text('Veri kaynağı', style: AppTypography.labelMedium),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onImportFromPreProduction,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Ön İmalattan Veri Al'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      foregroundColor: AppColors.electricBlueLight,
                      side: BorderSide(
                        color: AppColors.electricBlue.withValues(alpha: 0.45),
                      ),
                    ),
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

class _LengthMatchToleranceField extends StatefulWidget {
  const _LengthMatchToleranceField({
    required this.toleranceCm,
    required this.onApply,
  });

  final double toleranceCm;
  final ValueChanged<double> onApply;

  @override
  State<_LengthMatchToleranceField> createState() =>
      _LengthMatchToleranceFieldState();
}

class _LengthMatchToleranceFieldState extends State<_LengthMatchToleranceField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.toleranceCm));
  }

  @override
  void didUpdateWidget(covariant _LengthMatchToleranceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toleranceCm != widget.toleranceCm) {
      final current = double.tryParse(
        _controller.text.trim().replaceAll(',', '.'),
      );
      if (current == null || (current - widget.toleranceCm).abs() > 1e-9) {
        _controller.text = _format(widget.toleranceCm);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  void _apply() {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || parsed <= 0) return;
    widget.onApply(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Yakın boy toleransı (cm)',
              hintText: 'Örn: 30',
              isDense: true,
            ),
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _apply,
          child: const Text('Uygula'),
        ),
      ],
    );
  }
}

class _LengthMatchCard extends StatefulWidget {
  const _LengthMatchCard({
    required this.group,
    required this.onApprove,
  });

  final LengthMatchGroup group;
  final void Function(bool approved, double? selectedLengthM) onApprove;

  @override
  State<_LengthMatchCard> createState() => _LengthMatchCardState();
}

class _LengthMatchCardState extends State<_LengthMatchCard> {
  double? _selectedLengthM;

  @override
  void initState() {
    super.initState();
    _selectedLengthM = _initialSelection(widget.group);
  }

  @override
  void didUpdateWidget(covariant _LengthMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id ||
        oldWidget.group.approved != widget.group.approved) {
      _selectedLengthM = _initialSelection(widget.group);
    }
  }

  double? _initialSelection(LengthMatchGroup group) {
    if (group.selectedLengthM != null) return group.selectedLengthM;
    if (group.members.isEmpty) return null;
    return group.members
        .reduce((a, b) => a.quantity >= b.quantity ? a : b)
        .lengthM;
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final color = AppColors.diameterColor(group.diameter);

    if (group.approved && group.selectedLengthM != null) {
      final matchedLength = group.selectedLengthM!;
      return Container(
        margin: const EdgeInsets.only(bottom: AnalysisScreen._innerCardGap),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: AppRadii.md,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(
              'Ø${group.diameter}',
              style: AppTypography.titleMedium.copyWith(color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${matchedLength.toStringAsFixed(2)} m × '
                '${AppFormat.integer(group.totalQuantity)} adet',
                style: AppTypography.bodyMedium,
              ),
            ),
            FilterChip(
              label: const Text('Onaylı'),
              selected: true,
              onSelected: (selected) {
                if (!selected) widget.onApprove(false, null);
              },
              selectedColor: AppColors.success.withValues(alpha: 0.2),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AnalysisScreen._innerCardGap),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ø${group.diameter}',
                style: AppTypography.titleMedium.copyWith(color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${group.minLengthM.toStringAsFixed(2)}–${group.maxLengthM.toStringAsFixed(2)} m · '
                  '${group.totalQuantity} adet',
                  style: AppTypography.bodySmall,
                ),
              ),
              FilterChip(
                label: const Text('Onayla'),
                selected: false,
                onSelected: (selected) {
                  if (!selected || _selectedLengthM == null) return;
                  widget.onApprove(true, _selectedLengthM);
                },
                selectedColor: AppColors.success.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Eşleştirilecek boyu seçin',
            style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ...group.members.map(
            (member) => InkWell(
              onTap: () => setState(() {
                _selectedLengthM = member.lengthM;
              }),
              borderRadius: AppRadii.sm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Radio<double>(
                      value: member.lengthM,
                      groupValue: _selectedLengthM,
                      onChanged: (value) => setState(() {
                        _selectedLengthM = value;
                      }),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(
                      '${member.lengthM.toStringAsFixed(2)} m × ${member.quantity} adet',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TahvilCard extends StatelessWidget {
  const _TahvilCard({
    required this.group,
    required this.onApprove,
  });

  final TahvilSuggestion group;
  final ValueChanged<bool> onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AnalysisScreen._innerCardGap),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: group.approved
            ? AppColors.warning.withValues(alpha: 0.08)
            : AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: group.approved
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Boy ${group.minLengthM.toStringAsFixed(2)}–${group.maxLengthM.toStringAsFixed(2)} m · '
                  'Ø${group.diameters.join(', Ø')}',
                  style: AppTypography.titleMedium,
                ),
              ),
              FilterChip(
                label: Text(group.approved ? 'Onaylı' : 'Tahvil Onayla'),
                selected: group.approved,
                onSelected: (selected) => onApprove(selected),
                selectedColor: AppColors.warning.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...group.members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· Ø${member.diameter} ${member.lengthM.toStringAsFixed(2)} m × ${member.quantity} adet',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.diameterColor(member.diameter),
                ),
              ),
            ),
          ),
          if (group.equivalents.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Tahvil hesabı (πr² · d² × adet)', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            ...group.equivalents.map(
              (eq) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ø${eq.fromDiameter} ${AppFormat.integer(eq.fromQuantity)} ad → '
                            'Ø${eq.toDiameter} tahvil: ${AppFormat.integer(eq.equivalentQuantity)} ad',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.diameterColor(eq.toDiameter),
                            ),
                          ),
                        ),
                        if (eq.isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Önerilen',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (eq.resultingSpacingCm != null)
                      Text(
                        'Tahvil aralığı: ${eq.resultingSpacingCm!.toStringAsFixed(1)} cm',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
