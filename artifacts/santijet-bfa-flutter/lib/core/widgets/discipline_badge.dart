import 'package:flutter/material.dart';

import '../../domain/enums/app_enums.dart';
import '../design_system/sj_status_badge.dart';
import '../theme/app_colors.dart';

/// Disiplin rozeti — disipline göre renk + etiket.
class DisciplineBadge extends StatelessWidget {
  const DisciplineBadge({required this.discipline, super.key});

  final AnalizDiscipline discipline;

  @override
  Widget build(BuildContext context) {
    return SJStatusBadge(
      label: discipline.label,
      color: AppColors.disciplineColor(discipline.name),
    );
  }
}
