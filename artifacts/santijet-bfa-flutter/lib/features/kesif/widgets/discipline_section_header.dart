import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/enums/app_enums.dart';

/// İnşaat / Elektrik / Mekanik bölüm başlığı (isteğe bağlı açılır-kapanır).
class DisciplineSectionHeader extends StatelessWidget {
  const DisciplineSectionHeader({
    required this.discipline,
    this.count,
    this.trailing,
    this.expanded,
    this.onToggle,
    super.key,
  });

  final AnalizDiscipline discipline;
  final int? count;
  final Widget? trailing;
  /// null ise sabit başlık; true/false ise chevron ile açılır-kapanır.
  final bool? expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = count == null
        ? discipline.isBasligi
        : '${discipline.isBasligi} ($count)';
    final canToggle = expanded != null && onToggle != null;

    final row = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          if (canToggle) ...[
            Icon(
              expanded! ? Icons.expand_more : Icons.chevron_right,
              color: AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (!canToggle) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: row,
      ),
    );
  }
}
