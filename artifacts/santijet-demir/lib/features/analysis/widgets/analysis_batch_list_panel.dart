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
    required this.analysisScopeIds,
    required this.onScopeChanged,
    required this.onDeleteSelected,
    required this.onImportFromPreProduction,
  });

  final List<CuttingBendingBatch> batches;
  final Set<String> analysisScopeIds;
  final ValueChanged<Set<String>> onScopeChanged;
  final Future<void> Function(Set<String> batchIds) onDeleteSelected;
  final VoidCallback onImportFromPreProduction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final allSelected =
        batches.isNotEmpty && analysisScopeIds.length == batches.length;
    final scopeCount = analysisScopeIds.length;

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
                foregroundColor: AppColors.success,
                side: BorderSide(
                  color: AppColors.success.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
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
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              scopeCount == batches.length
                  ? 'Tüm dosyalar analizde — minimum fire için en doğru seçim.'
                  : scopeCount == 0
                      ? 'Analize almak için en az bir dosya seçin.'
                      : '$scopeCount dosya analizde — tüm dosyaları seçerek fireyi daha da düşürebilirsiniz.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
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
                    onScopeChanged(
                      allSelected ? {} : batches.map((batch) => batch.id).toSet(),
                    );
                  },
                ),
                if (analysisScopeIds.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.critical,
                    ),
                    label: Text(
                      'Seçilenleri sil (${analysisScopeIds.length})',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.critical,
                      ),
                    ),
                    backgroundColor: AppColors.critical.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: AppColors.critical.withValues(alpha: 0.35),
                    ),
                    onPressed: () => onDeleteSelected(analysisScopeIds),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...batches.map(
            (batch) {
              final inScope = analysisScopeIds.contains(batch.id);
              final totalPieces =
                  batch.pieceLines.fold(0, (sum, piece) => sum + piece.quantity);

              return Material(
                color: inScope
                    ? AppColors.electricBlue.withValues(alpha: 0.06)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: inScope,
                        onChanged: (selected) {
                          final next = Set<String>.from(analysisScopeIds);
                          if (selected == true) {
                            next.add(batch.id);
                          } else {
                            next.remove(batch.id);
                          }
                          onScopeChanged(next);
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final next = Set<String>.from(analysisScopeIds);
                            if (inScope) {
                              next.remove(batch.id);
                            } else {
                              next.add(batch.id);
                            }
                            onScopeChanged(next);
                          },
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
                                      color: inScope
                                          ? AppColors.electricBlue
                                              .withValues(alpha: 0.45)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    size: 18,
                                    color: inScope
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
                                                fontWeight: inScope
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (inScope) ...[
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
                                                allSelected ? 'Analizde' : 'Seçili',
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
