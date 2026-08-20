import 'package:flutter/material.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/rebar_weight.dart';
import '../../domain/tahvil_calculator.dart';

/// Demir birim ağırlık tablosu — kg/m = d² / 162.
class TeknikScreen extends StatelessWidget {
  const TeknikScreen({super.key});

  static const _barLengthM = 12.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Teknik'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    'Demir birim ağırlık',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formül: kg/m = d² / 162  ·  ρ ≈ 7,85 g/cm³',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SJCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _HeaderRow(),
                        for (var i = 0;
                            i < RebarWeight.standardDiameters.length;
                            i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.cardBorder,
                            ),
                          _WeightRow(
                            diameterMm: RebarWeight.standardDiameters[i],
                            barLengthM: _barLengthM,
                          ),
                        ],
                      ],
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

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = AppTypography.cardLabelMedium.copyWith(
      color: AppColors.cardTextSecondary,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardInsetSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Çap', style: style)),
          Expanded(
            flex: 3,
            child: Text('kg/m', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text('12 m', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: Text('As', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({
    required this.diameterMm,
    required this.barLengthM,
  });

  final int diameterMm;
  final double barLengthM;

  @override
  Widget build(BuildContext context) {
    final kgm = RebarWeight.kgPerMeter(diameterMm);
    final barKg = RebarWeight.weightKg(
      diameterMm: diameterMm,
      lengthM: barLengthM,
    );
    final asMm2 = crossSectionAreaMm2(diameterMm);
    final valueStyle = AppTypography.cardTitleMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Ø$diameterMm', style: valueStyle),
          ),
          Expanded(
            flex: 3,
            child: Text(
              kgm.toStringAsFixed(3),
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${barKg.toStringAsFixed(2)} kg',
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${asMm2.toStringAsFixed(1)} mm²',
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
