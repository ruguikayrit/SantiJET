import 'package:flutter/material.dart';

import '../theme/app_radii.dart';

/// ŞantiJET Design System — arama çubuğu.
///
/// ŞantiJET Demir `AppSearchBar` deseni: arama alanı + opsiyonel filtre butonu.
/// Temizleme (clear) ikonu, controller ve değişim geri çağrısı destekler.
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
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: hasText && onClear != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
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
            icon: const Icon(Icons.tune),
            style: IconButton.styleFrom(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
            ),
          ),
        ],
      ],
    );
  }
}
