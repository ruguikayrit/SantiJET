import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

/// Describes a single header cell rendered by [AppTableHeaderRow].
class AppTableHeaderCell {
  const AppTableHeaderCell(
    this.label, {
    this.line2,
    this.flex = 1,
    this.align = TextAlign.center,
  });

  final String label;
  final String? line2;
  final int flex;
  final TextAlign align;
}

/// Shared blue table header row — matches the "Çap Karşılaştırma" design:
/// electric-blue outlined cells with a light-blue fill, black bold labels.
class AppTableHeaderRow extends StatelessWidget {
  const AppTableHeaderRow({
    super.key,
    required this.cells,
    this.padding = const EdgeInsets.fromLTRB(14, 10, 14, 10),
    this.gap = 4,
    this.trailing,
  });

  final List<AppTableHeaderCell> cells;
  final EdgeInsetsGeometry padding;
  final double gap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                flex: cells[i].flex,
                child: AppTableHeaderBadge(
                  cells[i].label,
                  line2: cells[i].line2,
                  align: cells[i].align,
                ),
              ),
            ],
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Single decorated header cell for use inside `Table` widgets, `Row`s with
/// fixed-width columns, or anywhere a standalone blue header badge is needed.
///
/// Etiket metni çerçeve içinde her iki yönde (yatay + dikey) ortalanır.
class AppTableHeaderBadge extends StatelessWidget {
  const AppTableHeaderBadge(
    this.label, {
    super.key,
    this.line2,
    this.align = TextAlign.center,
    this.padding,
  });

  final String label;
  final String? line2;
  final TextAlign align;
  final EdgeInsetsGeometry? padding;

  /// Tek/çift satır başlıklar için ortak minimum çerçeve yüksekliği.
  static const minHeight = 36.0;

  static TextStyle get _textStyle => AppTypography.labelSmall.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        // 1.0 → satır üst/alt boşluğu simetrik; optik dikey ortalama bozulmaz.
        height: 1.0,
        fontSize: (AppTypography.labelSmall.fontSize ?? 11) * 0.95,
      );

  @override
  Widget build(BuildContext context) {
    final labelBlock = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: _textStyle,
          textAlign: align,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
        ),
        if (line2 != null) ...[
          const SizedBox(height: 2),
          Text(
            line2!,
            style: _textStyle,
            textAlign: align,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final fillHeight = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        // Dikey padding yok — Align.center gerçek geometrik ortayı verir.
        final edgePadding = padding ??
            const EdgeInsets.symmetric(horizontal: 4);

        final framed = DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.electricBlueLight,
            borderRadius: AppRadii.xs,
            border: Border.all(color: AppColors.electricBlue),
          ),
          child: Padding(
            padding: edgePadding,
            child: Align(
              alignment: Alignment.center,
              child: labelBlock,
            ),
          ),
        );

        if (fillHeight) {
          return SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: framed,
          );
        }

        return SizedBox(
          width: double.infinity,
          height: minHeight,
          child: framed,
        );
      },
    );
  }
}
