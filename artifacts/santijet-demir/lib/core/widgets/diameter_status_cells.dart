import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ana sayfa «Çap Bazlı Durum» satırı — aynı hücre düzeni.
class DiameterStatusCellItem {
  const DiameterStatusCellItem({
    required this.diameter,
    required this.bottomLabel,
    required this.sortValue,
  });

  final int diameter;
  final String bottomLabel;
  final double sortValue;
}

class DiameterStatusCells extends StatelessWidget {
  const DiameterStatusCells({
    super.key,
    required this.items,
    this.onDiameterTap,
    this.highlightLowest = true,
  });

  final List<DiameterStatusCellItem> items;
  final ValueChanged<int>? onDiameterTap;
  final bool highlightLowest;

  static const _ink = Color(0xFF0F2744);
  static const _blue = Color(0xFF2563EB);

  static Color diameterDot(int diameter) {
    return switch (diameter) {
      8 => const Color(0xFF3B82F6),
      10 => const Color(0xFFA855F7),
      12 => const Color(0xFFEF4444),
      14 => const Color(0xFFF97316),
      16 => const Color(0xFFEAB308),
      20 => const Color(0xFF8B5CF6),
      22 => const Color(0xFFDC2626),
      28 => const Color(0xFF0EA5E9),
      _ => _blue,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final highlightDiameter = highlightLowest ? _lowestDiameter(items) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cells = [
          for (final item in items)
            DiameterStatusCell(
              diameter: item.diameter,
              bottomLabel: item.bottomLabel,
              highlighted: item.diameter == highlightDiameter,
              onTap: onDiameterTap == null
                  ? null
                  : () => onDiameterTap!(item.diameter),
            ),
        ];
        if (items.length <= 5) {
          return Row(
            children: [
              for (final cell in cells) Expanded(child: cell),
            ],
          );
        }
        final cellWidth = constraints.maxWidth / 5;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cell in cells)
                SizedBox(width: cellWidth, child: cell),
            ],
          ),
        );
      },
    );
  }

  static int? _lowestDiameter(List<DiameterStatusCellItem> items) {
    if (items.length < 2) return null;
    final min = items.map((s) => s.sortValue).reduce((a, b) => a < b ? a : b);
    final max = items.map((s) => s.sortValue).reduce((a, b) => a > b ? a : b);
    if (min == max) return null;
    return items.firstWhere((s) => s.sortValue == min).diameter;
  }
}

class DiameterStatusCell extends StatelessWidget {
  const DiameterStatusCell({
    super.key,
    required this.diameter,
    required this.bottomLabel,
    required this.highlighted,
    this.onTap,
  });

  final int diameter;
  final String bottomLabel;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = DiameterStatusCells.diameterDot(diameter);
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: highlighted ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Ø$diameter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: DiameterStatusCells._ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bottomLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
