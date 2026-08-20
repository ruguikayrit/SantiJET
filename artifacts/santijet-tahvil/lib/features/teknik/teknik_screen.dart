import 'package:flutter/material.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/rebar_weight.dart';
import '../../domain/tahvil_calculator.dart';
import '../../domain/tahvil_rules.dart';

/// Demir birim ağırlık + 100 cm’de donatı alanı (cm²) tabloları.
class TeknikScreen extends StatelessWidget {
  const TeknikScreen({super.key});

  static const _barLengthM = 12.0;

  /// Saha / proje pratğinde yaygın aralıklar (cm).
  static const _spacingsCm = [10.0, 12.5, 15.0, 20.0, 25.0];

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
                        _WeightHeaderRow(),
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '100 cm’de donatı alanı',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'As (cm²) — 100 cm şerit genişliğinde. '
                    'Aralık ≤ ${tahvilMaxSpacingCm.toStringAsFixed(0)} cm.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SJCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _AsPerMeterTable(
                        diameters: RebarWeight.standardDiameters,
                        spacingsCm: _spacingsCm,
                      ),
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

class _WeightHeaderRow extends StatelessWidget {
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
            child: Text('Kesit', style: style, textAlign: TextAlign.right),
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

/// As (cm²) = π·d² / (4·s)  — d mm, s cm; 100 cm şerit.
double asCm2Per100Cm({
  required int diameterMm,
  required double spacingCm,
}) {
  if (diameterMm <= 0 || spacingCm <= 0) return 0;
  return computeAsPerMeterMm2(diameterMm, spacingCm * 10) / 100;
}

class _AsPerMeterTable extends StatelessWidget {
  const _AsPerMeterTable({
    required this.diameters,
    required this.spacingsCm,
  });

  final List<int> diameters;
  final List<double> spacingsCm;

  static const _diameterColW = 56.0;
  static const _spacingColW = 64.0;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.cardLabelMedium.copyWith(
      color: AppColors.cardTextSecondary,
      fontWeight: FontWeight.w700,
    );
    final valueStyle = AppTypography.cardTitleMedium;
    final tableWidth =
        _diameterColW + spacingsCm.length * _spacingColW;

    return SizedBox(
      width: tableWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardInsetSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _diameterColW,
                  child: Text('Çap', style: headerStyle),
                ),
                for (final s in spacingsCm)
                  SizedBox(
                    width: _spacingColW,
                    child: Text(
                      _formatSpacingCm(s),
                      style: headerStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < diameters.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.cardBorder,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: _diameterColW,
                    child: Text('Ø${diameters[i]}', style: valueStyle),
                  ),
                  for (final s in spacingsCm)
                    SizedBox(
                      width: _spacingColW,
                      child: Text(
                        asCm2Per100Cm(
                          diameterMm: diameters[i],
                          spacingCm: s,
                        ).toStringAsFixed(2),
                        style: valueStyle,
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatSpacingCm(double cm) {
    if ((cm - cm.roundToDouble()).abs() < 1e-9) {
      return '${cm.round()}';
    }
    return cm.toStringAsFixed(1);
  }
}
