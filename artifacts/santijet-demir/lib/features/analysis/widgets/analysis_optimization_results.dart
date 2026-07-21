import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/analysis/widgets/analysis_fire_summary.dart';
import 'package:santijet_demir/features/analysis/widgets/paginated_list_section.dart';

class AnalysisOptimizationResultsSection extends ConsumerWidget {
  const AnalysisOptimizationResultsSection({super.key, required this.batch});

  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategy = batch.optimizationStrategy;
    final lengthChanges = ref.watch(analysisLengthMatchChangesProvider);
    final approvedTahvil =
        batch.tahvilGroups.where((group) => group.approved).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (strategy != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.08),
              borderRadius: AppRadii.sm,
              border: Border.all(
                color: AppColors.electricBlue.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.electricBlueLight,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uygulanan strateji: ${strategy.label}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.electricBlueLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (strategy?.appliesLengthMatch ?? false) ...[
          AnalysisStepHeader(
            step: 1,
            title: 'Uzunluk Eşleştirme',
            subtitle:
                'Aynı çapta ${CuttingBendingBatch.lengthMatchToleranceDescription} — otomatik',
            complete: batch.lengthMatches.isNotEmpty ||
                lengthChanges.isEmpty,
          ),
          if (lengthChanges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Uzunluk eşleştirme gerektiren satır bulunamadı.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            )
          else ...[
            Text(
              'Düzenlenen demirler (önce → sonra)',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(height: 8),
            PaginatedListSection<LengthMatchChange>(
              items: lengthChanges,
              header: const _LengthMatchChangesTableHeader(),
              itemBuilder: (context, change, index) =>
                  _LengthMatchChangeRow(change: change),
            ),
          ],
          const SizedBox(height: 20),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
        ],
        if (strategy?.appliesTahvil ?? false) ...[
          AnalysisStepHeader(
            step: strategy?.appliesLengthMatch ?? false ? 2 : 1,
            title: 'Tahvil',
            subtitle: 'Tahvil kurallarına uygun otomatik dönüşüm',
            complete: approvedTahvil.isNotEmpty,
          ),
          if (approvedTahvil.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Bu liste için uygulanabilir tahvil bulunamadı.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            ...approvedTahvil.map(
              (group) => _ReadOnlyTahvilCard(group: group),
            ),
          const SizedBox(height: 20),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
        ],
        AnalysisStepHeader(
          step: _reviseStep(strategy),
          title: 'Revize Parça Listesi',
          subtitle: 'Seçilen stratejiye göre güncellenmiş kesim listesi',
          complete: batch.revisedPieceLines.isNotEmpty,
        ),
        batch.revisedPieceLines.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Revize liste oluşturulamadı.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              )
            : _ReadOnlyPieceListTable(pieces: batch.revisedPieceLines),
      ],
    );
  }

  int _reviseStep(FireReductionStrategy? strategy) {
    if (strategy == null) return 1;
    var step = 1;
    if (strategy.appliesLengthMatch) step++;
    if (strategy.appliesTahvil) step++;
    return step;
  }
}

class _LengthMatchChangesTableHeader extends StatelessWidget {
  const _LengthMatchChangesTableHeader();

  @override
  Widget build(BuildContext context) {
    return const AppTableHeaderRow(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      cells: [
        AppTableHeaderCell('ÇAP'),
        AppTableHeaderCell('ÖNCE (m)', flex: 2),
        AppTableHeaderCell('SONRA (m)', flex: 2),
        AppTableHeaderCell('ADET'),
      ],
    );
  }
}

class _LengthMatchChangeRow extends StatelessWidget {
  const _LengthMatchChangeRow({required this.change});

  final LengthMatchChange change;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.diameterColor(change.diameter);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Ø${change.diameter}',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(color: color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              change.beforeLengthM.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  change.afterLengthM.toStringAsFixed(2),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              AppFormat.integer(change.quantity),
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyTahvilCard extends StatelessWidget {
  const _ReadOnlyTahvilCard({required this.group});

  final TahvilSuggestion group;

  @override
  Widget build(BuildContext context) {
    final best = pickBestTahvilEquivalentForGroup(group);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uzunluk ${group.minLengthM.toStringAsFixed(2)}–${group.maxLengthM.toStringAsFixed(2)} m · '
            'Ø${group.diameters.join(', Ø')}',
            style: AppTypography.titleMedium,
          ),
          if (best != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ø${best.fromDiameter} ${AppFormat.integer(best.fromQuantity)} ad → '
              'Ø${best.toDiameter} ${AppFormat.integer(best.equivalentQuantity)} ad',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.diameterColor(best.toDiameter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyPieceListTable extends StatelessWidget {
  const _ReadOnlyPieceListTable({required this.pieces});

  final List<RebarPieceLine> pieces;

  @override
  Widget build(BuildContext context) {
    return PaginatedListSection<RebarPieceLine>(
      items: pieces,
      header: const AppTableHeaderRow(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        cells: [
          AppTableHeaderCell('ÇAP'),
          AppTableHeaderCell('UZUNLUK (m)'),
          AppTableHeaderCell('ADET'),
        ],
      ),
      itemBuilder: (context, piece, index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Ø${piece.diameter}',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.diameterColor(piece.diameter),
                ),
              ),
            ),
            Expanded(
              child: Text(
                piece.lengthM.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
            ),
            Expanded(
              child: Text(
                AppFormat.integer(piece.quantity),
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
