import 'package:flutter/material.dart';

import '../design_system/sj_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Modül kartı — ana sayfadaki disiplin/bölüm girişleri.
///
/// İkon (renkli yuvarlak) + başlık + alt başlık + sayı rozeti. SJCard üzerine
/// kurulur; mürekkep kart kontrast temasından okunur.
class ModuleTile extends StatelessWidget {
  const ModuleTile({
    required this.title,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.count,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      onTap: onTap,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.cardTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.cardTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (count != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.cardTextMuted,
              ),
            ],
          );
        },
      ),
    );
  }
}
