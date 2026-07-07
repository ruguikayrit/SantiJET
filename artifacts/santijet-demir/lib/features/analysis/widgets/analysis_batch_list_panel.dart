import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

class AnalysisBatchListPanel extends ConsumerWidget {
  const AnalysisBatchListPanel({
    super.key,
    required this.batches,
    required this.activeBatchId,
    required this.onSelectBatch,
    required this.onDeleteSelected,
    required this.onImportFromPreProduction,
  });

  final List<CuttingBendingBatch> batches;
  final String? activeBatchId;
  final ValueChanged<String> onSelectBatch;
  final Future<void> Function(Set<String> batchIds) onDeleteSelected;
  final VoidCallback onImportFromPreProduction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(selectedAnalysisBatchIdsProvider);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final allSelected =
        batches.isNotEmpty && selectedIds.length == batches.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: OutlinedButton.icon(
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'DWG analiz listesi',
                    style: AppTypography.titleMedium,
                  ),
                ),
                Text(
                  '${batches.length} dosya',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(
                    Icons.select_all,
                    size: 16,
                    color: AppColors.electricBlueLight,
                  ),
                  label: Text(
                    allSelected ? 'Seçimi kaldır' : 'Tümünü seç',
                    style: AppTypography.labelMedium,
                  ),
                  backgroundColor: AppColors.canvas,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () {
                    ref.read(selectedAnalysisBatchIdsProvider.notifier).state =
                        allSelected ? {} : batches.map((batch) => batch.id).toSet();
                  },
                ),
                if (selectedIds.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.critical,
                    ),
                    label: Text(
                      'Seçilenleri sil (${selectedIds.length})',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.critical,
                      ),
                    ),
                    backgroundColor: AppColors.critical.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: AppColors.critical.withValues(alpha: 0.35),
                    ),
                    onPressed: () => onDeleteSelected(selectedIds),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...batches.map(
            (batch) {
              final isActive = batch.id == activeBatchId;
              final isSelected = selectedIds.contains(batch.id);
              final totalPieces =
                  batch.pieceLines.fold(0, (sum, piece) => sum + piece.quantity);

              return Material(
                color: isActive
                    ? AppColors.electricBlue.withValues(alpha: 0.06)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (selected) {
                          final next = Set<String>.from(selectedIds);
                          if (selected == true) {
                            next.add(batch.id);
                          } else {
                            next.remove(batch.id);
                          }
                          ref
                              .read(selectedAnalysisBatchIdsProvider.notifier)
                              .state = next;
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => onSelectBatch(batch.id),
                          borderRadius: AppRadii.sm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.partial.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive
                                          ? AppColors.electricBlue
                                              .withValues(alpha: 0.45)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    size: 18,
                                    color: isActive
                                        ? AppColors.electricBlueLight
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              batch.title,
                                              style: AppTypography.bodyMedium.copyWith(
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.electricBlue
                                                    .withValues(alpha: 0.15),
                                                borderRadius: AppRadii.full,
                                              ),
                                              child: Text(
                                                'Aktif',
                                                style: AppTypography.labelSmall.copyWith(
                                                  color: AppColors.electricBlueLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${dateFormat.format(batch.createdAt)} · '
                                        '${AppFormat.integer(totalPieces)} ad · '
                                        '${batch.pieceLines.length} satır',
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
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
