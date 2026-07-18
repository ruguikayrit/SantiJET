import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';

/// İmalat tipine göre segment rengi (Kolon / Perde / Kiriş / Döşeme).
Color stockCutElementAccent(String? elementTypeCode) {
  return switch (elementTypeCode?.toUpperCase()) {
    'S' => AppColors.electricBlueLight,
    'P' => AppColors.partial,
    'K' => AppColors.info,
    'D' => AppColors.warning,
    _ => AppColors.textSecondary,
  };
}

String stockCutMemberToken(StockBarCutMember member) {
  final label = member.elementDisplayLabel;
  final length = '${member.lengthM.toStringAsFixed(2)} m';
  if (label.isEmpty) return length;
  return '$label · $length';
}

/// Çubuk kesim satırı — imalat etiketli formül + orantılı bar.
class StockBarCutVisualCard extends StatelessWidget {
  const StockBarCutVisualCard({
    super.key,
    required this.bar,
    required this.stockLengthM,
    required this.diameterColor,
    this.remainderLabelStyle = StockBarRemainderLabel.kalan,
  });

  final StockBarCut bar;
  final double stockLengthM;
  final Color diameterColor;
  final StockBarRemainderLabel remainderLabelStyle;

  @override
  Widget build(BuildContext context) {
    final isZeroWaste = bar.wasteLengthM <= 0.001;
    final parts = bar.members
        .expand(
          (member) => List.filled(member.count, stockCutMemberToken(member)),
        )
        .join(' + ');

    final remainderText = switch (remainderLabelStyle) {
      StockBarRemainderLabel.kalan => isZeroWaste
          ? 'Fire yok · ${stockLengthM.toStringAsFixed(0)} m stok tam kullanım'
          : 'Kalan: ${bar.wasteLengthM.toStringAsFixed(2)} m / '
              '${stockLengthM.toStringAsFixed(0)} m stok',
      StockBarRemainderLabel.fire =>
        'Fire: ${bar.wasteLengthM.toStringAsFixed(2)} m / '
            '${stockLengthM.toStringAsFixed(0)} m',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isZeroWaste
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: isZeroWaste
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çubuk ${bar.barIndex}',
            style: AppTypography.labelMedium.copyWith(color: diameterColor),
          ),
          const SizedBox(height: 8),
          _StockCutProportionalBar(
            bar: bar,
            stockLengthM: stockLengthM,
          ),
          const SizedBox(height: 8),
          Text(
            parts.isEmpty
                ? '—'
                : '$parts = ${bar.usedLengthM.toStringAsFixed(2)} m',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            remainderText,
            style: AppTypography.bodySmall.copyWith(
              color: isZeroWaste ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum StockBarRemainderLabel { kalan, fire }

class _StockCutProportionalBar extends StatelessWidget {
  const _StockCutProportionalBar({
    required this.bar,
    required this.stockLengthM,
  });

  final StockBarCut bar;
  final double stockLengthM;

  @override
  Widget build(BuildContext context) {
    final segments = <_BarSegment>[];
    for (final member in bar.members) {
      for (var i = 0; i < member.count; i++) {
        segments.add(
          _BarSegment(
            lengthM: member.lengthM,
            label: member.shortLabel.isNotEmpty
                ? member.shortLabel
                : member.elementTypeLabel ?? '',
            subtitle: '${member.lengthM.toStringAsFixed(2)}',
            color: stockCutElementAccent(member.elementTypeCode),
          ),
        );
      }
    }
    if (bar.wasteLengthM > 0.001) {
      segments.add(
        _BarSegment(
          lengthM: bar.wasteLengthM,
          label: 'Fire',
          subtitle: bar.wasteLengthM.toStringAsFixed(2),
          color: AppColors.textMuted.withValues(alpha: 0.45),
          isWaste: true,
        ),
      );
    }

    final total = stockLengthM <= 0 ? 1.0 : stockLengthM;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                flex: mathMax1((segment.lengthM / total * 1000).round()),
                child: Container(
                  margin: const EdgeInsets.only(right: 1),
                  decoration: BoxDecoration(
                    color: segment.color.withValues(
                      alpha: segment.isWaste ? 0.25 : 0.28,
                    ),
                    border: Border.all(
                      color: segment.color.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (segment.label.isNotEmpty)
                          Text(
                            segment.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelSmall.copyWith(
                              color: segment.isWaste
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              height: 1.1,
                            ),
                          ),
                        Text(
                          '${segment.subtitle} m',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarSegment {
  const _BarSegment({
    required this.lengthM,
    required this.label,
    required this.subtitle,
    required this.color,
    this.isWaste = false,
  });

  final double lengthM;
  final String label;
  final String subtitle;
  final Color color;
  final bool isWaste;
}

int mathMax1(int value) => value < 1 ? 1 : value;
