import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

/// Açıklama cümlelerini alt alta gösteren yardımcı metin.
class AppDescriptionLines extends StatelessWidget {
  const AppDescriptionLines(
    this.lines, {
    super.key,
    this.style,
    this.spacing = 2,
    this.textAlign = TextAlign.start,
  });

  final List<String> lines;
  final TextStyle? style;
  final double spacing;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        AppTypography.bodySmall.copyWith(color: AppColors.textMuted);
    final visible = lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final crossAxis = switch (textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          SizedBox(
            width: textAlign == TextAlign.center ? double.infinity : null,
            child: Text(
              visible[i],
              style: effectiveStyle,
              textAlign: textAlign,
            ),
          ),
        ],
      ],
    );
  }
}
