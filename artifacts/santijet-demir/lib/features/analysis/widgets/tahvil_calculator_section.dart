import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_manual_calculator.dart';
import 'package:santijet_demir/domain/tahvil/tahvil_rules.dart';

class TahvilCalculatorSection extends StatefulWidget {
  const TahvilCalculatorSection({super.key, this.hideHeader = false});

  final bool hideHeader;

  @override
  State<TahvilCalculatorSection> createState() => _TahvilCalculatorSectionState();
}

class _TahvilCalculatorSectionState extends State<TahvilCalculatorSection> {
  final _inputRow = _EditableTahvilRow();

  @override
  void dispose() {
    _inputRow.dispose();
    super.dispose();
  }

  TahvilManualInputRow? get _sourceRow {
    final input = _inputRow.toInput();
    return input.isComplete ? input : null;
  }

  List<TahvilManualResult> get _allResults {
    final source = _sourceRow;
    if (source == null) return const [];
    return computeManualTahvilResults(
      fromDiameter: source.diameter!,
      fromQuantity: source.quantity!,
      fromSpacingCm: source.spacingCm,
    );
  }

  TahvilManualResult? get _optimalResult {
    final allowed = _allResults.where((result) => result.isAllowed);
    return allowed.isEmpty ? null : allowed.first;
  }

  void _onInputChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final source = _sourceRow;
    final allResults = _allResults;
    final optimal = _optimalResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.hideHeader) ...[
          Text('Otomatik Tahvil Hesabı', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Çap, adet ve aralık girin. Tüm hedef çaplar hesaplanır; '
            'uygun olanlar ve elenenler gerekçeleriyle gösterilir.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const _InputTableHeader(),
              _InputTableRow(row: _inputRow, onChanged: _onInputChanged),
            ],
          ),
        ),
        if (source == null) ...[
          const SizedBox(height: 12),
          Text(
            'Hesap için çap, adet ve aralık alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            'Kaynak: Ø${source.diameter} · ${AppFormat.integer(source.quantity!)} ad · '
            '${source.spacingCm!.toStringAsFixed(1)} cm aralık',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('Tahvil seçenekleri', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          const _TahvilRulesSummary(),
          const SizedBox(height: 8),
          if (allResults.isEmpty)
            Text(
              'Girilen değerler için tahvil hesabı yapılamadı.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
            )
          else
            ...allResults.map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TahvilResultCard(
                  source: source,
                  result: result,
                  isOptimal: optimal != null &&
                      result.isAllowed &&
                      result.toDiameter == optimal.toDiameter,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TahvilRulesSummary extends StatelessWidget {
  const _TahvilRulesSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kurallar', style: AppTypography.labelMedium),
          const SizedBox(height: 4),
          Text(
            '• Hedef çap: kaynak ±$tahvilMaxDiameterDiffMm mm\n'
            '• Yeni aralık: ≤${tahvilMaxSpacingCm.toStringAsFixed(0)} cm\n'
            '• Kesit sapması: ≤%${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TahvilResultCard extends StatelessWidget {
  const _TahvilResultCard({
    required this.source,
    required this.result,
    required this.isOptimal,
  });

  final TahvilManualInputRow source;
  final TahvilManualResult result;
  final bool isOptimal;

  @override
  Widget build(BuildContext context) {
    final targetColor = AppColors.diameterColor(result.toDiameter);
    final isRejected = !result.isAllowed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOptimal
            ? AppColors.success.withValues(alpha: 0.06)
            : isRejected
                ? AppColors.critical.withValues(alpha: 0.04)
                : AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: isOptimal
              ? AppColors.success.withValues(alpha: 0.35)
              : isRejected
                  ? AppColors.critical.withValues(alpha: 0.25)
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
                  'Ø${source.diameter} → Ø${result.toDiameter}',
                  style: AppTypography.titleMedium.copyWith(
                    color: isRejected
                        ? targetColor.withValues(alpha: 0.55)
                        : targetColor,
                  ),
                ),
              ),
              if (isOptimal)
                _StatusBadge(
                  label: 'Optimum',
                  color: AppColors.success,
                )
              else if (isRejected)
                _StatusBadge(
                  label: 'Uygun değil',
                  color: AppColors.critical,
                ),
            ],
          ),
          if (isRejected && result.rejectReason != null) ...[
            const SizedBox(height: 6),
            Text(
              result.rejectReason!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Yeni adet: ${AppFormat.integer(result.equivalentQuantity)}',
            style: AppTypography.bodyMedium.copyWith(
              color: isRejected ? AppColors.textMuted : null,
            ),
          ),
          if (result.resultingSpacingCm != null)
            Text(
              'Yeni aralık: ${result.resultingSpacingCm!.toStringAsFixed(1)} cm',
              style: AppTypography.bodyMedium.copyWith(
                color: isRejected ? AppColors.textMuted : null,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Kesit alanı sapması: %${result.areaDeviationPercent.toStringAsFixed(2)}',
            style: AppTypography.bodySmall.copyWith(
              color: isOptimal
                  ? AppColors.success
                  : isRejected
                      ? AppColors.textMuted
                      : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _EditableTahvilRow {
  final diameterController = TextEditingController();
  final quantityController = TextEditingController();
  final spacingController = TextEditingController();

  void dispose() {
    diameterController.dispose();
    quantityController.dispose();
    spacingController.dispose();
  }

  TahvilManualInputRow toInput() {
    final diameter = int.tryParse(diameterController.text.trim());
    final quantity = int.tryParse(quantityController.text.trim());
    final spacing = double.tryParse(
      spacingController.text.trim().replaceAll(',', '.'),
    );
    return TahvilManualInputRow(
      diameter: diameter,
      quantity: quantity,
      spacingCm: spacing,
    );
  }
}

class _InputTableHeader extends StatelessWidget {
  const _InputTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('ÇAP (mm)', style: AppTypography.labelMedium)),
          Expanded(child: Text('ADET', style: AppTypography.labelMedium)),
          Expanded(child: Text('ARALIK (cm)', style: AppTypography.labelMedium)),
        ],
      ),
    );
  }
}

class _InputTableRow extends StatelessWidget {
  const _InputTableRow({
    required this.row,
    required this.onChanged,
  });

  final _EditableTahvilRow row;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: row.diameterController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '16',
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: row.quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '120',
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: row.spacingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '15',
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
