import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'sj_card.dart';

/// ŞantiJET Design System — liste satırı.
///
/// ŞantiJET Demir `AlertCard` deseni: sol vurgu/ikon + başlık + alt metin +
/// sağda değer/ok. Analiz ve keşif listelerinde kullanılır.
class SJListItem extends StatelessWidget {
  const SJListItem({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.accentColor,
    this.trailingText,
    this.trailing,
    this.onTap,
    this.selected = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? accentColor;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return SJCard(
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(leadingIcon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (trailingText != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                trailingText!,
                style: theme.textTheme.titleMedium?.copyWith(color: accent),
              ),
            )
          else if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
