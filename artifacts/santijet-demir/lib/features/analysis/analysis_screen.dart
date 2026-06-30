import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

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
              child: SantijetHeader(subtitle: 'KESME - BÜKME', showNotification: false),
            ),
            if (batch == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.content_cut, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text('Liste boş', style: AppTypography.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Keşif → Ön İmalat veya Otomatik Metraj\'dan\n'
                          '"Kesme-Bükme\'ye Gönder" ile parça listesi oluşturun.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.surveyMetrajRecords),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Keşif / Ön İmalat'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
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
                    batches: state.batches,
                    onSelectBatch: (id) =>
                        ref.read(cuttingBendingBatchesProvider.notifier).setActiveBatch(id),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('Parça Listesi', style: AppTypography.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Çap + boy bazında gruplanmış adetler',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    _PieceListTable(pieces: batch.pieceLines),
                    const SizedBox(height: 20),
                    Text('Boy Eşleştirme', style: AppTypography.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Aynı çapta birbirine yakın boylar (±${(cuttingBendingLengthToleranceM * 100).toStringAsFixed(0)} cm)',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (batch.lengthMatches.isEmpty)
                      const ModuleEmptyState(type: EmptyStateType.noSearchResult, inline: true)
                    else
                      ...batch.lengthMatches.map(
                        (group) => _LengthMatchCard(
                          group: group,
                          onApprove: (approved) => ref
                              .read(cuttingBendingBatchesProvider.notifier)
                              .approveLengthMatch(group.id, approved: approved),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text('Tahvil Önerileri', style: AppTypography.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Farklı çapta, birbirine yakın veya eşit boydaki demirler',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (batch.tahvilGroups.isEmpty)
                      const ModuleEmptyState(type: EmptyStateType.noSearchResult, inline: true)
                    else
                      ...batch.tahvilGroups.map(
                        (group) => _TahvilCard(
                          group: group,
                          onApprove: (approved) => ref
                              .read(cuttingBendingBatchesProvider.notifier)
                              .approveTahvil(group.id, approved: approved),
                        ),
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
}

class _BatchHeader extends StatelessWidget {
  const _BatchHeader({
    required this.batch,
    required this.batches,
    required this.onSelectBatch,
  });

  final CuttingBendingBatch batch;
  final List<CuttingBendingBatch> batches;
  final ValueChanged<String> onSelectBatch;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final totalPieces = batch.pieceLines.fold(0, (sum, p) => sum + p.quantity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(batch.title, style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${dateFormat.format(batch.createdAt)} · $totalPieces adet · '
            '${batch.pieceLines.length} satır',
            style: AppTypography.bodySmall,
          ),
          if (batches.length > 1) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: batch.id,
              decoration: const InputDecoration(
                labelText: 'Liste',
                isDense: true,
              ),
              items: batches
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.title, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onSelectBatch(value);
              },
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.surveyMetrajRecords),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Keşif / Ön İmalat\'tan Gönder'),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
      ),
    );
  }
}

class _LengthMatchCard extends StatelessWidget {
  const _LengthMatchCard({
    required this.group,
    required this.onApprove,
  });

  final LengthMatchGroup group;
  final ValueChanged<bool> onApprove;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.diameterColor(group.diameter);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: group.approved
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: group.approved
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
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
                label: Text(group.approved ? 'Onaylı' : 'Onayla'),
                selected: group.approved,
                onSelected: (selected) => onApprove(selected),
                selectedColor: AppColors.success.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...group.members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '· ${member.lengthM.toStringAsFixed(2)} m × ${member.quantity} adet',
                style: AppTypography.bodySmall,
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
      margin: const EdgeInsets.only(bottom: 8),
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
