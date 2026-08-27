import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../domain/entities/project.dart';

/// Kayıtlı işe ait firma logosu — yoksa bina ikonu.
class ProjectCompanyLogo extends StatelessWidget {
  const ProjectCompanyLogo({
    required this.project,
    this.size = 40,
    this.iconSize = 20,
    super.key,
  });

  final Project? project;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.useDarkChrome
            ? AppColors.darkSurfaceHighlight
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.sm,
      ),
      child: Icon(
        Icons.apartment,
        size: iconSize,
        color: AppColors.useDarkChrome
            ? AppColors.electricBlueLight
            : AppColors.electricBlue,
      ),
    );

    if (project == null || !project!.hasLogo) return fallback;

    try {
      final bytes = base64Decode(project!.logoBase64);
      return ClipRRect(
        borderRadius: AppRadii.sm,
        child: ColoredBox(
          color: Colors.white,
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      );
    } catch (_) {
      return fallback;
    }
  }
}
