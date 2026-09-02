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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
    );
  }
}

/// Single decorated header cell for use inside `Table` widgets, `Row`s with
/// fixed-width columns, or anywhere a standalone blue header badge is needed.
///
/// Çift satır başlıklarda sabit yükseklik; tek satırda daha sıkı çerçeve.
/// Font boyutu değişmez.
class AppTableHeaderBadge extends StatelessWidget {
  const AppTableHeaderBadge(
    this.label, {
    super.key,
    this.line2,
    this.align = TextAlign.center,
    this.padding,
    this.fontSize,
  });

  final String label;
  final String? line2;
  final TextAlign align;
  final EdgeInsetsGeometry? padding;

  /// Varsayılan 12.5; daha küçük başlıklar için örn. 11.
  final double? fontSize;

  /// Çift satır (line2) başlık çerçeve yüksekliği.
  static const height = 48.0;

  /// Tek satır başlık çerçeve yüksekliği — Fire özeti vb.
  static const singleLineHeight = 30.0;

  /// Geriye dönük: eski [minHeight] kullanan çağrılar.
  static const minHeight = height;

  static const defaultFontSize = 12.5;

  double get _frameHeight => line2 != null ? height : singleLineHeight;

  TextStyle get _textStyle => AppTypography.labelMedium.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0.2,
        fontSize: fontSize ?? defaultFontSize,
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

    return SizedBox(
      height: _frameHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.electricBlueLight,
          borderRadius: AppRadii.xs,
          border: Border.all(color: AppColors.electricBlue),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: labelBlock,
            ),
          ),
        ),
      ),
    );
  }
}
