import 'package:flutter/material.dart';

import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';
import '../design_system/sj_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_format.dart';
import 'favorite_button.dart';

/// Analiz listesi satırı — poz no + analiz adı + disiplin + birim fiyat + favori.
class AnalizListItem extends StatelessWidget {
  const AnalizListItem({
    required this.analiz,
    this.isFavorite = false,
    this.onTap,
    this.onToggleFavorite,
    super.key,
  });

  final PozAnaliz analiz;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discipline = analiz.discipline ?? AnalizDiscipline.insaat;
    final accent = AppColors.disciplineColor(discipline.name);

    return SJCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      analiz.pozNo,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      analiz.olcuBirimi,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  analiz.analizAdi,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (analiz.birimFiyati > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppFormat.currency(analiz.birimFiyati),
                    style: theme.textTheme.titleMedium?.copyWith(color: accent),
                  ),
                ],
              ],
            ),
          ),
          if (onToggleFavorite != null)
            FavoriteButton(
              isFavorite: isFavorite,
              onToggle: onToggleFavorite!,
            ),
        ],
      ),
    );
  }
}
