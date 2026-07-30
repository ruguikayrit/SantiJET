import 'package:flutter/material.dart';

import 'package:santijet_demir/core/format/app_format.dart';

import 'package:santijet_demir/core/theme/app_colors.dart';

import 'package:santijet_demir/core/theme/app_radii.dart';

import 'package:santijet_demir/core/theme/app_typography.dart';

import 'package:santijet_demir/core/widgets/app_table_header.dart';

import 'package:santijet_demir/domain/entities/field_count.dart';

import 'package:santijet_demir/features/field_count/field_count_calculator.dart';



class ReconciliationTable extends StatelessWidget {

  const ReconciliationTable({

    super.key,

    required this.rows,

    required this.totals,

    this.landscape = false,

  });



  final List<ReconciliationRow> rows;

  final ReconciliationTotals totals;

  final bool landscape;



  static const _cellStyle = TextStyle(

    fontSize: 10,

    fontWeight: FontWeight.w500,

    height: 1.15,

  );



  static const _totalStyle = TextStyle(

    fontSize: 10,

    fontWeight: FontWeight.w700,

    height: 1.15,

  );



  static const _columnCount = 9;

  /// Yatay: kısa başlıklar dar, uzun başlıklar geniş — tüm harfler görünsün.
  static const _landscapeFlex = <double>[
    1.15, // Çap / Son Toplamlar — tek satır etiket için geniş
    0.78, // Keşif
    0.88, // Sipariş
    1.05, // Teslim alınan
    1.22, // Planlanan kullanım
    1.18, // Gerçek kullanım
    1.12, // Planlanan stok
    1.55, // Gerçek stok (sayım)
    0.82, // Fire %
  ];

  /// Dikey kaydırma: sabit px — en uzun başlığa göre.
  static const _portraitWidths = <double>[
    72, // Çap / Son Toplamlar
    50, // Keşif
    56, // Sipariş
    64, // Teslim alınan
    74, // Planlanan kullanım
    72, // Gerçek kullanım
    68, // Planlanan stok
    92, // Gerçek stok (sayım)
    54, // Fire %
  ];

  @override
  Widget build(BuildContext context) {
    final table = Table(
      columnWidths:
          landscape ? _landscapeColumnWidths() : _portraitColumnWidths(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColors.border, width: 0.5),
      ),
      children: [
        _headerRow(),
        ...rows.map(_dataRow),
        _totalRow(),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.md,
        child: landscape
            ? table
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              ),
      ),
    );
  }

  Map<int, TableColumnWidth> _landscapeColumnWidths() {
    return {
      for (var i = 0; i < _columnCount; i++)
        i: FlexColumnWidth(_landscapeFlex[i]),
    };
  }

  Map<int, TableColumnWidth> _portraitColumnWidths() {
    return {
      for (var i = 0; i < _columnCount; i++)
        i: FixedColumnWidth(_portraitWidths[i]),
    };
  }

  TableRow _headerRow() {
    return TableRow(
      children: [
        _headerCell('Çap'),
        _headerCell('Keşif'),
        _headerCell('Sipariş'),
        _headerCell('Teslim', line2: 'alınan'),
        _headerCell('Planlanan', line2: 'kullanım'),
        _headerCell('Gerçek', line2: 'kullanım'),
        _headerCell('Planlanan', line2: 'stok'),
        _headerCell('Gerçek stok', line2: '(sayım)'),
        _headerCell('Fire', line2: '%'),
      ],
    );
  }



  TableRow _dataRow(ReconciliationRow row) {

    final statusColor = switch (row.status) {

      'normal' => AppColors.success,

      'warning' => AppColors.warning,

      _ => AppColors.critical,

    };



    return TableRow(

      decoration: BoxDecoration(

        color: statusColor.withValues(alpha: 0.04),

      ),

      children: [

        _diameterCell(row.diameter, statusColor),

        _valueCell(row.survey),

        _valueCell(row.ordered),

        _valueCell(row.delivered),

        _valueCell(row.plannedUsage),

        _valueCell(row.used),

        _valueCell(row.expectedStock),

        _valueCell(row.counted),

        _fireCell(

          fire: row.fire,

          firePercent: row.firePercent,

          hasBase: row.plannedUsage > 0,

        ),

      ],

    );

  }



  TableRow _totalRow() {

    return TableRow(

      decoration: BoxDecoration(

        color: AppColors.electricBlue.withValues(alpha: 0.08),

      ),

      children: [

        _totalLabelCell(),

        _textCell(_formatTonnage(totals.survey), style: _totalStyle),

        _textCell(_formatTonnage(totals.ordered), style: _totalStyle),

        _textCell(_formatTonnage(totals.delivered), style: _totalStyle),

        _textCell(_formatTonnage(totals.plannedUsage), style: _totalStyle),

        _textCell(_formatTonnage(totals.actualUsage), style: _totalStyle),

        _textCell(_formatTonnage(totals.plannedStock), style: _totalStyle),

        _textCell(_formatTonnage(totals.fieldCount), style: _totalStyle),

        _fireCell(

          fire: totals.fire,

          firePercent: totals.firePercent,

          hasBase: totals.plannedUsage > 0,

          emphasized: true,

        ),

      ],

    );

  }



  Widget _headerCell(
    String line1, {
    String? line2,
    TextAlign align = TextAlign.center,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: AppTableHeaderBadge(line1, line2: line2, align: align),
      ),
    );
  }

  Widget _totalLabelCell() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Son Toplamlar',
          style: AppTypography.bodySmall.merge(_totalStyle),
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }



  Widget _diameterCell(int diameter, Color statusColor) {

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),

      child: Row(

        mainAxisSize: MainAxisSize.min,

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Container(

            width: 2,

            height: 16,

            decoration: BoxDecoration(

              color: statusColor,

              borderRadius: AppRadii.xs,

            ),

          ),

          const SizedBox(width: 3),

          Text(

            'Ø$diameter',

            style: AppTypography.labelMedium.copyWith(

              fontSize: 10,

              fontWeight: FontWeight.w700,

              color: AppColors.diameterColor(diameter),

            ),

          ),

        ],

      ),

    );

  }



  Widget _valueCell(double value) => _textCell(_formatTonnage(value));



  Widget _textCell(
    String text, {
    TextStyle style = _cellStyle,
    TextAlign align = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),

      child: Text(

        text,

        style: AppTypography.bodySmall.merge(style),

        textAlign: align,

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

      ),

    );

  }



  Widget _fireCell({

    required double fire,

    required double firePercent,

    required bool hasBase,

    bool emphasized = false,

  }) {

    final percentStyle = AppTypography.bodySmall.copyWith(

      fontSize: 9,

      color: AppColors.textMuted,

      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,

    );



    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [

          _CompactSapmaTag(value: fire),

          if (hasBase)

            Text(

              _formatFirePercent(firePercent),

              style: percentStyle,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

            ),

        ],

      ),

    );

  }



  static String _formatTonnage(double value) => '${AppFormat.tonnage(value)}t';



  static String _formatFirePercent(double percent) {

    if (percent == 0) return '%0.0';

    final prefix = percent > 0 ? '+' : '';

    return '$prefix%${percent.toStringAsFixed(1)}';

  }

}



class _CompactSapmaTag extends StatelessWidget {

  const _CompactSapmaTag({required this.value});



  final double value;



  @override

  Widget build(BuildContext context) {

    final isFire = value > 0;
    final isZero = value == 0;
    final color = isZero
        ? AppColors.success
        : isFire
            ? (value > 10 ? AppColors.critical : AppColors.warning)
            : AppColors.info;



    final prefix = isZero ? '' : isFire ? '+' : '';

    final text = isZero ? '✓' : '$prefix${AppFormat.tonnage(value)}t';



    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.12),

        borderRadius: AppRadii.xs,

      ),

      child: Text(

        text,

        style: AppTypography.labelMedium.copyWith(

          fontSize: 9,

          color: color,

          fontWeight: FontWeight.w700,

          height: 1.05,

        ),

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

      ),

    );

  }

}


