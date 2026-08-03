import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// ŞantiJET Design System — arama çubuğu.
///
/// Chrome yüzey + chrome mürekkep kullanır (hibrit kart yüzeyinden bağımsız).
class SJSearchBar extends StatelessWidget {
  const SJSearchBar({
    this.controller,
    this.hint = 'Ara...',
    this.onChanged,
    this.onClear,
    this.onFilterTap,
    super.key,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = (controller?.text ?? '').isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surface,
              isDense: true,
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: AppColors.textMuted,
              ),
              suffixIcon: hasText && onClear != null
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: onClear,
                    )
                  : null,
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onFilterTap,
            icon: Icon(Icons.tune, color: AppColors.textSecondary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
            ),
          ),
        ],
      ],
    );
  }
}
