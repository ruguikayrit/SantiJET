import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

/// ŞantiJET Design System — arama çubuğu (Demir `AppSearchBar` birebir).
class SJSearchBar extends StatelessWidget {
  const SJSearchBar({
    super.key,
    this.hint = 'Ara...',
    this.onChanged,
    this.onFilterTap,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textMuted,
                size: 20,
              ),
              isDense: true,
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onFilterTap,
            icon: Icon(Icons.tune, color: AppColors.textMuted),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
            ),
          ),
        ],
      ],
    );
  }
}
