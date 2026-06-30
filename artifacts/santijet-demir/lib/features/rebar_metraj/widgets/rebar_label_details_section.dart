import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

/// Keşif Otomatik Metraj ve Kesme-Bükme sayfalarında ortak etiket listesi.
class RebarLabelDetailsSection extends StatefulWidget {
  const RebarLabelDetailsSection({
    super.key,
    this.details = const [],
    this.onDeleteDetail,
  });

  final List<RebarMetrajTextDetail> details;
  final void Function(RebarMetrajTextDetail detail)? onDeleteDetail;

  @override
  State<RebarLabelDetailsSection> createState() => _RebarLabelDetailsSectionState();
}

class _RebarLabelDetailsSectionState extends State<RebarLabelDetailsSection> {
  static const _initialCount = 3;
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final details = widget.details;
    if (details.isEmpty) return const SizedBox.shrink();

    final visible = _expanded ? details : details.take(_initialCount).toList();
    final hasMore = !_expanded && details.length > _initialCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analiz Edilen Demir Etiketleri', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${details.length} etiket (adet + çap + boy)',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 12),
        ...visible.map(
          (detail) => RebarLabelDetailCard(
            detail: detail,
            formatter: formatter,
            onDelete: widget.onDeleteDetail == null
                ? null
                : () => widget.onDeleteDetail!(detail),
          ),
        ),
        if (hasMore)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = true),
              icon: const Icon(Icons.expand_more),
              label: Text('Daha fazla göster (${details.length - _initialCount})'),
            ),
          )
        else if (_expanded && details.length > _initialCount)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = false),
              icon: const Icon(Icons.expand_less),
              label: const Text('Listeyi daralt'),
            ),
          ),
      ],
    );
  }
}

class RebarLabelDetailCard extends StatelessWidget {
  const RebarLabelDetailCard({
    super.key,
    required this.detail,
    required this.formatter,
    this.onDelete,
  });

  final RebarMetrajTextDetail detail;
  final NumberFormat formatter;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final borderColor = detail.included
        ? AppColors.success.withValues(alpha: 0.35)
        : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detail.entityType,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.critical,
                  tooltip: 'Listeden sil',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail.sourceText, style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          if (detail.included &&
              detail.diameter != null &&
              detail.lengthM != null)
            Text(
              '${detail.quantity} ad · '
              'Ø${detail.diameter} · '
              '${formatter.format(detail.lengthM)} m · '
              '${formatter.format(detail.weightKg)} kg',
              style: AppTypography.bodySmall,
            )
          else if (detail.skipReason != null)
            Text(
              detail.skipReason!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
