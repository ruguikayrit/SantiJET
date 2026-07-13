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
      fromQuantity: source.quantity,
      fromSpacingCm: source.spacingCm,
      lengthCm: source.lengthCm,
    );
  }

  TahvilManualResult? get _optimalResult {
    final allowed = _allResults.where((result) => result.isAllowed);
    return allowed.isEmpty ? null : allowed.first;
  }

  void _onInputChanged() => setState(() {});

  String _sourceSummary(TahvilManualInputRow source) {
    final parts = <String>['Ø${source.diameter}'];
    final effectiveQty = source.effectiveQuantity;
    if (!source.usesReferenceQuantity && source.quantity != null) {
      parts.add('${AppFormat.integer(source.quantity!)} ad');
    } else if (effectiveQty != null) {
      parts.add('${AppFormat.integer(effectiveQty)} ad (100 cm ref.)');
    }
    parts.add('${source.spacingCm!.toStringAsFixed(1)} cm aralık');
    if (source.hasLength) {
      parts.add('${source.lengthCm!.toStringAsFixed(0)} cm boy');
    }
    return parts.join(' · ');
  }

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
            'Çap ve aralık zorunlu. Adet boşsa 100 cm referans kullanılır. '
            'Boy girilirse tonaj mukayesesi gösterilir.',
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
            'Hesap için çap ve aralık alanlarını doldurun.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            'Kaynak: ${_sourceSummary(source)}',
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
            '• Kesit sapması: ≤%${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)}\n'
            '• Adet boş: ${tahvilReferenceSpanCm.toStringAsFixed(0)} cm referans',
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
    final effectiveQty = source.effectiveQuantity ?? 0;

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
                const _StatusBadge(
                  label: 'Optimum',
                  color: AppColors.success,
                )
              else if (isRejected)
                const _StatusBadge(
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
            source.usesReferenceQuantity
                ? 'Yeni adet (100 cm ref.): ${AppFormat.integer(result.equivalentQuantity)}'
                : 'Yeni adet: ${AppFormat.integer(result.equivalentQuantity)}',
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
          _CrossSectionComparison(
            source: source,
            result: result,
            effectiveQuantity: effectiveQty,
          ),
          if (result.fromTonnage != null && result.toTonnage != null) ...[
            const SizedBox(height: 8),
            _TonnageComparison(
              fromTonnage: result.fromTonnage!,
              toTonnage: result.toTonnage!,
              isRejected: isRejected,
            ),
          ],
        ],
      ),
    );
  }
}

class _TonnageComparison extends StatelessWidget {
  const _TonnageComparison({
    required this.fromTonnage,
    required this.toTonnage,
    required this.isRejected,
  });

  final double fromTonnage;
  final double toTonnage;
  final bool isRejected;

  @override
  Widget build(BuildContext context) {
    final delta = toTonnage - fromTonnage;
    final deltaLabel = delta >= 0
        ? '+${AppFormat.tonnage(delta)}t'
        : AppFormat.tonnage(delta);
    final accentColor = isRejected
        ? AppColors.textMuted
        : delta.abs() < 0.0001
            ? AppColors.success
            : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tonaj mukayesesi', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Önce: ${AppFormat.tonnage(fromTonnage)}t · '
          'Sonra: ${AppFormat.tonnage(toTonnage)}t · Fark: $deltaLabel',
          style: AppTypography.bodyMedium.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CrossSectionComparison extends StatelessWidget {
  const _CrossSectionComparison({
    required this.source,
    required this.result,
    required this.effectiveQuantity,
  });

  final TahvilManualInputRow source;
  final TahvilManualResult result;
  final int effectiveQuantity;

  @override
  Widget build(BuildContext context) {
    final comparison = formatCrossSectionComparison(
      fromDiameter: source.diameter!,
      fromQuantity: effectiveQuantity,
      toDiameter: result.toDiameter,
      toQuantity: result.equivalentQuantity,
    );
    final areaAllowed =
        isCrossSectionDeviationAllowed(result.areaDeviationPercent);
    final accentColor = areaAllowed ? AppColors.success : AppColors.critical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kesit mukayesesi', style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        Text(
          comparison,
          style: AppTypography.bodyMedium.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          areaAllowed
              ? 'Sapma %${result.areaDeviationPercent.toStringAsFixed(2)} '
                  '(≤%${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)} — uygun)'
              : 'Sapma %${result.areaDeviationPercent.toStringAsFixed(2)} '
                  '(>%${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)} — uygun değil)',
          style: AppTypography.bodySmall.copyWith(color: accentColor),
        ),
      ],
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
  final lengthController = TextEditingController();

  void dispose() {
    diameterController.dispose();
    quantityController.dispose();
    spacingController.dispose();
    lengthController.dispose();
  }

  TahvilManualInputRow toInput() {
    final diameter = int.tryParse(diameterController.text.trim());
    final quantityText = quantityController.text.trim();
    final quantity = quantityText.isEmpty ? null : int.tryParse(quantityText);
    final spacing = double.tryParse(
      spacingController.text.trim().replaceAll(',', '.'),
    );
    final lengthText = lengthController.text.trim();
    final length = lengthText.isEmpty
        ? null
        : double.tryParse(lengthText.replaceAll(',', '.'));
    return TahvilManualInputRow(
      diameter: diameter,
      quantity: quantity,
      spacingCm: spacing,
      lengthCm: length,
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('ÇAP (mm)', style: AppTypography.labelMedium)),
              Expanded(child: Text('ADET', style: AppTypography.labelMedium)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('ARALIK (cm)', style: AppTypography.labelMedium)),
              Expanded(child: Text('BOY (cm)', style: AppTypography.labelMedium)),
            ],
          ),
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
      child: Column(
        children: [
          Row(
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
                    hintText: 'isteğe bağlı',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: row.lengthController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'isteğe bağlı',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
