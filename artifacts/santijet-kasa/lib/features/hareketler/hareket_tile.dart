import 'package:flutter/material.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/kasa_hareket.dart';
import '../../domain/money_format.dart';
import '../kasa/kasa_screen.dart';

/// Tek hareket satırı — liste / ana ekran.
class HareketTile extends StatelessWidget {
  const HareketTile({
    required this.hareket,
    this.onTap,
    super.key,
  });

  final KasaHareket hareket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isGelir = hareket.isGelir;
    final amount = isGelir
        ? MoneyFormat.format(hareket.gelir!)
        : MoneyFormat.format(hareket.gider ?? 0);
    final amountColor = isGelir ? AppColors.electricBlue : AppColors.critical;

    return SJCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGelir ? Icons.south_west : Icons.north_east,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hareketBaslik(hareket),
                  style: AppTypography.cardTitleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hareket.aciklama,
                  style: AppTypography.cardBodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    formatHareketTarih(hareket.tarih),
                    if (hareket.santiye.isNotEmpty) hareket.santiye,
                    if (hareket.odemeSekli.isNotEmpty) hareket.odemeSekli,
                  ].join(' · '),
                  style: AppTypography.cardLabelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isGelir ? '+$amount' : '-$amount',
            style: AppTypography.titleMedium.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}
