import 'package:flutter/material.dart';

import '../core/design_system/sj_status_badge.dart';
import '../core/theme/app_colors.dart';
import '../domain/program_item.dart';

Color programStatusColor(ProgramStatus status) => switch (status) {
  ProgramStatus.completed => AppColors.success,
  ProgramStatus.delayed => AppColors.critical,
  ProgramStatus.inProgress => AppColors.electricBlue,
  ProgramStatus.planned => AppColors.textMuted,
};

class ProgramStatusBadge extends StatelessWidget {
  const ProgramStatusBadge({super.key, required this.status});
  final ProgramStatus status;

  @override
  Widget build(BuildContext context) =>
      SJStatusBadge(label: status.label, color: programStatusColor(status));
}
