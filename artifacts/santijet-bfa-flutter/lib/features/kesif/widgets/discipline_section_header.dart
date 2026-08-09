import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/enums/app_enums.dart';

/// İnşaat / Elektrik / Mekanik bölüm başlığı.
class DisciplineSectionHeader extends StatelessWidget {
  const DisciplineSectionHeader({
    required this.discipline,
    this.count,
    this.trailing,
    super.key,
  });

  final AnalizDiscipline discipline;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == null
                  ? discipline.isBasligi
                  : '${discipline.isBasligi} ($count)',
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
  }
}
