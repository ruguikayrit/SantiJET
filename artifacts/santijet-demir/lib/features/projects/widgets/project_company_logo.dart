import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';

/// Aktif iş kartı sol görseli — Saha ile aynı kutu / bina ikonu.
class ProjectCompanyLogo extends StatelessWidget {
  const ProjectCompanyLogo({
    this.size = 40,
    this.iconSize = 20,
    super.key,
  });

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.useDarkChrome
            ? AppColors.darkSurfaceHighlight
            : Theme.of(context).colorScheme.surfaceContainerHighest,
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
  }
}
