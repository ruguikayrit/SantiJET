import 'package:flutter/material.dart';

import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/poz_analiz.dart';
import '../design_system/sj_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_format.dart';

/// Maliyet özeti kartı — malzeme+işçilik toplamı, yüklenici kârı, birim fiyat.
///
/// Değerler `AnalizHesap` ile anlık hesaplanır (RN `hesaplaAnalizToplam`).
class CostSummaryCard extends StatelessWidget {
  const CostSummaryCard({required this.analiz, super.key});

  final PozAnaliz analiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = AnalizHesap.hesapla(analiz);

    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            theme,
            'Malzeme + İşçilik + Ekipman',
            AppFormat.currency(h.malzemeIscilikToplami),
          ),
          const SizedBox(height: AppSpacing.xs),
          _row(
            theme,
            'Yüklenici Kârı (%${AppFormat.decimal(analiz.yukleniciKarOrani, fractionDigits: 0)})',
            AppFormat.currency(h.yukleniciKarTutari),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Birim Fiyat', style: theme.textTheme.titleMedium),
              Text(
                '${AppFormat.currency(h.birimFiyati)} / ${analiz.olcuBirimi}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
