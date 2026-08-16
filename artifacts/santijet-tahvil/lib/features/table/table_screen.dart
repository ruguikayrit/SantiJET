import 'package:flutter/material.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/rebar_weight.dart';
import '../../domain/tahvil_calculator.dart';

/// Hızlı bakış tablosu — 15 cm aralık ve 10 adet referans.
class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  static const _refSpacingCm = 15.0;
  static const _refQuantity = 10;

  int _source = 16;

  @override
  Widget build(BuildContext context) {
    final kgm = RebarWeight.kgPerMeter(_source);
    final asMm2 = crossSectionAreaMm2(_source);
    final spacingResults = computeSpacingTahvilResults(
      sourceDiameter: _source,
      sourceSpacingMm: _refSpacingCm * 10,
    );
    final qtyResults = computeSingleQuantityTahvilResults(
      sourceDiameter: _source,
      sourceQuantity: _refQuantity,
    );

    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Tablo'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    'Kaynak çapı seçin. Referans: $_refQuantity adet ve '
                    '${_refSpacingCm.toStringAsFixed(0)} cm aralık.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in RebarWeight.standardDiameters)
                        GestureDetector(
                          onTap: () => setState(() => _source = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: d == _source
                                  ? AppColors.electricBlue
                                  : AppColors.surface,
                              borderRadius: AppRadii.sm,
                              border: Border.all(
                                color: d == _source
                                    ? AppColors.electricBlue
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              'Ø$d',
                              style: AppTypography.labelLarge.copyWith(
                                color: d == _source
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _Kpi(
                          label: 'As',
                          value: asMm2.toStringAsFixed(1),
                          unit: 'mm²',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Kpi(
                          label: 'Ağırlık',
                          value: kgm.toStringAsFixed(3),
                          unit: 'kg/m',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Kpi(
                          label: '12 m',
                          value: (kgm * 12).toStringAsFixed(2),
                          unit: 'kg',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aralık tahvili · ${_refSpacingCm.toStringAsFixed(0)} cm',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final row in spacingResults)
                    _TableRow(
                      title:
                          'Ø$_source / ${formatCm(_refSpacingCm)} cm  →  '
                          'Ø${row.targetDiameter} / ${formatCm(row.resultingSpacingCm)} cm',
                      allowed: row.isAllowed,
                      reason: row.rejectReason,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Adet tahvili · $_refQuantity adet',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final row in qtyResults)
                    _TableRow(
                      title:
                          '$_refQuantity×Ø$_source  →  '
                          '${row.equivalentQuantity}×Ø${row.targetDiameter}',
                      allowed: row.isAllowed,
                      reason: row.rejectReason ??
                          'Sapma %${row.areaDeviationPercent.toStringAsFixed(1)}',
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

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.cardLabelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.onCard(AppTypography.kpiValue)),
          Text(unit, style: AppTypography.cardLabelMedium),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.title,
    required this.allowed,
    this.reason,
  });

  final String title;
  final bool allowed;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SJCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitleMedium),
                  if (!allowed && reason != null) ...[
                    const SizedBox(height: 2),
                    Text(reason!, style: AppTypography.cardBodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SJStatusBadge(
              label: allowed ? 'UYGUN' : 'HAYIR',
              color: allowed ? AppColors.success : AppColors.critical,
            ),
          ],
        ),
      ),
    );
  }
}
