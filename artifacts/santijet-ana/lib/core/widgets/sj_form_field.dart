import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';

class SjFormField extends ConsumerWidget {
  const SjFormField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeDefinitionProvider).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: colors.foreground),
        ),
        const SizedBox(height: AppSpacing.xxs),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: maxLines,
          style: AppTypography.bodyMedium.copyWith(color: colors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: BorderSide(color: colors.input),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: BorderSide(color: colors.input),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
