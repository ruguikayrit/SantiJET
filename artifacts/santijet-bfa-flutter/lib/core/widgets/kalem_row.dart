import 'package:flutter/material.dart';

import '../../domain/entities/analiz_kalemi.dart';
import '../../domain/enums/app_enums.dart';
import '../theme/app_colors.dart';
import '../utils/app_format.dart';

/// Analiz kalemi satırı — malzeme/işçilik/ekipman kalemini tablo satırı olarak
/// gösterir (poz no + tanım + miktar × birim fiyat = tutar).
class KalemRow extends StatelessWidget {
  const KalemRow({required this.kalem, super.key});

  final AnalizKalemi kalem;

  static Color tipColor(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => AppColors.moduleInsaat,
        AnalizKalemTip.iscilik => AppColors.electricBlueLight,
        AnalizKalemTip.ekipman => AppColors.partial,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: tipColor(kalem.tip),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kalem.tanim,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${kalem.pozNo} · ${AppFormat.decimal(kalem.miktar, fractionDigits: 4)} '
                  '${kalem.olcuBirimi} × ${AppFormat.currency(kalem.birimFiyati)}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppFormat.currency(kalem.tutar),
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
