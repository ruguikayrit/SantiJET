import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

class HealthRing extends StatelessWidget {
  const HealthRing({
    super.key,
    required this.score,
    this.size = 140,
    this.strokeWidth = 10,
  });

  final int score;
  final double size;
  final double strokeWidth;

  Color get _color {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HealthRingPainter(
          score: score,
          color: _color,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: AppTypography.kpiValue.copyWith(
                  fontSize: size * 0.28,
                  color: _color,
                ),
              ),
              Text(
                '/100',
                style: AppTypography.labelMedium,
              ),
              Text(
                'Sağlık',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  _HealthRingPainter({
    required this.score,
    required this.color,
    required this.strokeWidth,
  });

  final int score;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (score / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

class HorizontalBarChart extends StatelessWidget {
  const HorizontalBarChart({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.suffix = 't',
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.titleMedium),
              Text(
                '${value.toStringAsFixed(1)}$suffix',
                style: AppTypography.labelMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
