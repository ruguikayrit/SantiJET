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

/// Aynı kesim deseni (barIndex hariç) için imza.
String stockBarCutPatternKey(StockBarCut bar) {
  final members = bar.members
      .map(
        (m) =>
            '${m.lengthM.toStringAsFixed(3)}x${m.count}|'
            '${m.elementTypeCode ?? ''}|${m.elementCode ?? ''}',
      )
      .join(';');
  return '${bar.usedLengthM.toStringAsFixed(3)}|'
      '${bar.wasteLengthM.toStringAsFixed(3)}|$members';
}

/// Ardışık çubuk indekslerini "1–35, 40, 42–44" biçiminde yazar.
String formatBarIndexRanges(Iterable<int> indexes) {
  final sorted = indexes.toList()..sort();
  if (sorted.isEmpty) return '';
  final parts = <String>[];
  var start = sorted.first;
  var prev = start;
  for (var i = 1; i < sorted.length; i++) {
    final value = sorted[i];
    if (value == prev + 1) {
      prev = value;
      continue;
    }
    parts.add(start == prev ? '$start' : '$start–$prev');
    start = value;
    prev = value;
  }
  parts.add(start == prev ? '$start' : '$start–$prev');
  return parts.join(', ');
}

class StockBarCutGroup {
  const StockBarCutGroup({
    required this.representative,
    required this.barIndexes,
  });

  final StockBarCut representative;
  final List<int> barIndexes;

  int get count => barIndexes.length;

  /// Örn. "Çubuk 1–35 · 35 adet" veya "Çubuk 7".
  String get titleLabel {
    final ranges = formatBarIndexRanges(barIndexes);
    if (count <= 1) return 'Çubuk $ranges';
    return 'Çubuk $ranges · $count adet';
  }
}

/// Aynı kesim yapan çubukları tek grupta toplar; gruplar min çubuk no’ya göre sıralanır.
List<StockBarCutGroup> groupIdenticalStockBarCuts(List<StockBarCut> bars) {
  if (bars.isEmpty) return const [];

  final buckets = <String, List<StockBarCut>>{};
  for (final bar in bars) {
    buckets.putIfAbsent(stockBarCutPatternKey(bar), () => <StockBarCut>[]).add(bar);
  }

  final groups = <StockBarCutGroup>[];
  for (final bucket in buckets.values) {
    bucket.sort((a, b) => a.barIndex.compareTo(b.barIndex));
    groups.add(
      StockBarCutGroup(
        representative: bucket.first,
        barIndexes: [for (final bar in bucket) bar.barIndex],
      ),
    );
  }
  groups.sort(
    (a, b) => a.barIndexes.first.compareTo(b.barIndexes.first),
  );
  return groups;
}

/// Çubuk kesim satırı — imalat etiketli formül + orantılı bar.
class StockBarCutVisualCard extends StatelessWidget {
  const StockBarCutVisualCard({
    super.key,
    required this.bar,
    required this.stockLengthM,
    required this.diameterColor,
    this.remainderLabelStyle = StockBarRemainderLabel.kalan,
    this.titleLabel,
  });

  factory StockBarCutVisualCard.fromGroup({
    Key? key,
    required StockBarCutGroup group,
    required double stockLengthM,
    required Color diameterColor,
    StockBarRemainderLabel remainderLabelStyle = StockBarRemainderLabel.kalan,
  }) {
    return StockBarCutVisualCard(
      key: key,
      bar: group.representative,
      stockLengthM: stockLengthM,
      diameterColor: diameterColor,
      remainderLabelStyle: remainderLabelStyle,
      titleLabel: group.titleLabel,
    );
  }

  final StockBarCut bar;
  final double stockLengthM;
  final Color diameterColor;
  final StockBarRemainderLabel remainderLabelStyle;
  final String? titleLabel;

  @override
  Widget build(BuildContext context) {
    final isZeroWaste = bar.wasteLengthM <= 0.001;
    final parts = bar.members
        .expand(
          (member) => List.filled(member.count, stockCutMemberToken(member)),
        )
        .join(' + ');

    final remainderLines = switch (remainderLabelStyle) {
      StockBarRemainderLabel.kalan => isZeroWaste
          ? [
              'Fire yok.',
              '${stockLengthM.toStringAsFixed(0)} m stok tam kullanım.',
            ]
          : [
              'Kalan: ${bar.wasteLengthM.toStringAsFixed(2)} m / '
                  '${stockLengthM.toStringAsFixed(0)} m stok',
            ],
      StockBarRemainderLabel.fire => [
          'Fire: ${bar.wasteLengthM.toStringAsFixed(2)} m / '
              '${stockLengthM.toStringAsFixed(0)} m',
        ],
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            titleLabel ?? 'Çubuk ${bar.barIndex}',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < remainderLines.length; i++) ...[
                if (i > 0) const SizedBox(height: 2),
                Text(
                  remainderLines[i],
                  style: AppTypography.bodySmall.copyWith(
                    color: isZeroWaste ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
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
          label: 'F',
          subtitle: '',
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
                    child: segment.isWaste
                        ? Center(
                            child: Text(
                              'F',
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (segment.label.isNotEmpty)
                                Text(
                                  segment.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textPrimary,
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
