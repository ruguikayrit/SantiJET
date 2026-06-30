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
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/rebar_label_details_section.dart';

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
                    onDeleteBatch: () => _confirmDeleteBatch(context, ref, batch),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    RebarLabelDetailsSection(
                      details: batch.labelDetails,
                      onDeleteDetail: (detail) =>
                          _confirmDeleteLabel(context, ref, detail),
                    ),
                    const SizedBox(height: 20),
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
                      'Aynı çapta birbirine yakın boylar (±${(lengthMatchToleranceM * 100).toStringAsFixed(0)} cm) — '
                      'onaylamadan önce eşleştirilecek boyu seçin',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (batch.lengthMatches.isEmpty)
                      const ModuleEmptyState(type: EmptyStateType.noSearchResult, inline: true)
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
                    Text('Tahvil Önerileri', style: AppTypography.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'πr² kesit alanı, ±${tahvilMaxDiameterDiffMm} mm çap, '
                      '≤${tahvilMaxSpacingCm.toStringAsFixed(0)} cm aralık kurallarına göre',
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

  Future<void> _confirmDeleteBatch(
    BuildContext context,
    WidgetRef ref,
    CuttingBendingBatch batch,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listeyi sil'),
        content: Text(
          '"${batch.title}" kesme-bükme listesini silmek istediğinize emin misiniz?',
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
    await ref.read(cuttingBendingBatchesProvider.notifier).deleteBatch(batch.id);
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
    required this.batches,
    required this.onSelectBatch,
    required this.onDeleteBatch,
  });

  final CuttingBendingBatch batch;
  final List<CuttingBendingBatch> batches;
  final ValueChanged<String> onSelectBatch;
  final VoidCallback onDeleteBatch;

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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.surveyMetraj),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Keşif / Otomatik Metrajdan Veri Al'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onDeleteBatch,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.critical,
                tooltip: 'Listeyi sil',
              ),
            ],
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

  bool _sameLength(double a, double b) => (a - b).abs() < 1e-6;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final color = AppColors.diameterColor(group.diameter);
    final approved = group.approved;
    final matchedLength = approved ? group.selectedLengthM : _selectedLengthM;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: approved
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: approved
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
                  approved && matchedLength != null
                      ? 'Eşleşen boy: ${matchedLength.toStringAsFixed(2)} m · '
                          '${group.totalQuantity} adet'
                      : '${group.minLengthM.toStringAsFixed(2)}–${group.maxLengthM.toStringAsFixed(2)} m · '
                          '${group.totalQuantity} adet',
                  style: AppTypography.bodySmall,
                ),
              ),
              FilterChip(
                label: Text(approved ? 'Onaylı' : 'Onayla'),
                selected: approved,
                onSelected: (selected) {
                  if (selected && _selectedLengthM == null) return;
                  widget.onApprove(selected, selected ? _selectedLengthM : null);
                },
                selectedColor: AppColors.success.withValues(alpha: 0.2),
              ),
            ],
          ),
          if (!approved) ...[
            const SizedBox(height: 6),
            Text(
              'Eşleştirilecek boyu seçin',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          ...group.members.map(
            (member) {
              final isSelected = matchedLength != null &&
                  _sameLength(member.lengthM, matchedLength);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: approved
                    ? Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            size: 16,
                            color: isSelected
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${member.lengthM.toStringAsFixed(2)} m × ${member.quantity} adet',
                            style: AppTypography.bodySmall.copyWith(
                              color: isSelected ? AppColors.success : null,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      )
                    : InkWell(
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
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Text(
                                '${member.lengthM.toStringAsFixed(2)} m × ${member.quantity} adet',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
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
