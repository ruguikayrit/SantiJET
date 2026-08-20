import 'package:flutter/material.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/rebar_weight.dart';
import '../../domain/tahvil_calculator.dart';

/// Demir birim ağırlık + 100 cm’de cm² donatı kesiti tabloları.
class TeknikScreen extends StatelessWidget {
  const TeknikScreen({super.key});

  static const _barLengthM = 12.0;

  /// Görsel referans tablosu: çubuk çapları (mm).
  static const _sectionDiametersMm = [
    6, 7, 8, 10, 12, 14, 16, 18, 20, 22, 24,
  ];

  /// Görsel referans tablosu: çubuk aralığı 7–20 cm, 0,5 cm adım.
  static final _sectionSpacingsCm = [
    for (var i = 0; i <= 26; i++) 7.0 + i * 0.5,
  ];

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
                    '100 cm’de cm² donatı kesiti',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Satır: çubuk aralığı (cm)  ·  Sütun: çubuk çapı (mm)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SJCard(
                    padding: EdgeInsets.zero,
                    child: _SectionAreaTable(
                      diametersMm: _sectionDiametersMm,
                      spacingsCm: _sectionSpacingsCm,
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

/// As (cm²) = π·d² / (4·s) — d mm, s cm; 100 cm şerit.
double asCm2Per100Cm({
  required int diameterMm,
  required double spacingCm,
}) {
  if (diameterMm <= 0 || spacingCm <= 0) return 0;
  return computeAsPerMeterMm2(diameterMm, spacingCm * 10) / 100;
}

/// Görseldeki matris: satır = aralık (cm), sütun = çap (mm).
/// Sol aralık sütunu yatay kaydırmada sabit kalır.
class _SectionAreaTable extends StatelessWidget {
  const _SectionAreaTable({
    required this.diametersMm,
    required this.spacingsCm,
  });

  final List<int> diametersMm;
  final List<double> spacingsCm;

  static const _spacingColW = 56.0;
  static const _valueColW = 52.0;
  static const _headerH = 44.0;
  static const _rowH = 34.0;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.cardLabelSmall.copyWith(
      color: AppColors.cardTextSecondary,
      fontWeight: FontWeight.w700,
    );
    final cornerStyle = AppTypography.cardLabelSmall.copyWith(
      color: AppColors.cardTextSecondary,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final valueStyle = AppTypography.cardLabelLarge.copyWith(
      color: AppColors.cardTextPrimary,
      fontWeight: FontWeight.w600,
    );
    final scrollWidth = diametersMm.length * _valueColW;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius:
                const BorderRadius.only(topLeft: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: SizedBox(
            width: _spacingColW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: _headerH,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardInsetSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text('Aralık\n(cm)', style: cornerStyle),
                ),
                for (var i = 0; i < spacingsCm.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.cardBorder,
                    ),
                  SizedBox(
                    height: _rowH,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _formatSpacingCm(spacingsCm[i]),
                          style: valueStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: scrollWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: _headerH,
                    decoration: BoxDecoration(
                      color: AppColors.cardInsetSurface,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final d in diametersMm)
                          SizedBox(
                            width: _valueColW,
                            child: Center(
                              child: Text('$d', style: headerStyle),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < spacingsCm.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.cardBorder,
                      ),
                    SizedBox(
                      height: _rowH,
                      child: Row(
                        children: [
                          for (final d in diametersMm)
                            SizedBox(
                              width: _valueColW,
                              child: Center(
                                child: Text(
                                  asCm2Per100Cm(
                                    diameterMm: d,
                                    spacingCm: spacingsCm[i],
                                  ).toStringAsFixed(2),
                                  style: valueStyle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatSpacingCm(double cm) {
    if ((cm - cm.roundToDouble()).abs() < 1e-9) {
      return '${cm.round()}';
    }
    return cm.toStringAsFixed(1);
  }
}
