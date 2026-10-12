import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

/// Referans ölçek: başlık 13, hücre 14, yüzde 12, satır yüksekliği sıkı.
class DeliveredDiameterTable extends StatelessWidget {
  const DeliveredDiameterTable({
    super.key,
    required this.rows,
  });

  final List<DeliveredDiameterRow> rows;

  @override
  Widget build(BuildContext context) {
    final totalOrdered = rows.fold(0.0, (sum, row) => sum + row.ordered);
    final totalDelivered = rows.fold(0.0, (sum, row) => sum + row.delivered);
    final totalRemaining = rows.fold(0.0, (sum, row) => sum + _remaining(row));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _Header(),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Text(
                'Bu dönemde çap kaydı yok',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B95A5),
                ),
              ),
            )
          else
            for (final row in rows)
              _DataRow(
                diameter: row.diameter,
                ordered: row.ordered,
                orderedPercent: _percent(row.ordered, totalOrdered),
                delivered: row.delivered,
                deliveredPercent: _percent(row.delivered, row.ordered),
                remaining: _remaining(row),
                remainingPercent: _percent(_remaining(row), row.ordered),
                barColor: _percent(row.delivered, row.ordered) >= 100
                    ? AppColors.success
                    : AppColors.diameterColor(row.diameter),
              ),
          _DataRow(
            label: 'TOPLAM',
            ordered: totalOrdered,
            orderedPercent: 100,
            delivered: totalDelivered,
            deliveredPercent: _percent(totalDelivered, totalOrdered),
            remaining: totalRemaining,
            remainingPercent: _percent(totalRemaining, totalOrdered),
            barColor: AppColors.electricBlueLight,
            emphasized: true,
          ),
        ],
      ),
    );
  }

  double _remaining(DeliveredDiameterRow row) =>
      (row.ordered - row.delivered).clamp(0, double.infinity);

  int _percent(double part, double whole) {
    if (whole <= 0) return 0;
    return (part / whole * 100).round();
  }

}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF8B95A5),
      height: 1.1,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Row(
        children: [
          const Expanded(flex: 22, child: Text('ÇAP', style: style)),
          const Expanded(flex: 26, child: Text('SİPARİŞ', style: style, textAlign: TextAlign.center)),
          const Expanded(flex: 26, child: Text('TESLİM', style: style, textAlign: TextAlign.center)),
          const Expanded(flex: 26, child: Text('KALAN', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    this.diameter,
    this.label,
    required this.ordered,
    required this.orderedPercent,
    required this.delivered,
    required this.deliveredPercent,
    required this.remaining,
    required this.remainingPercent,
    required this.barColor,
    this.emphasized = false,
  });

  final int? diameter;
  final String? label;
  final double ordered;
  final int orderedPercent;
  final double delivered;
  final int deliveredPercent;
  final double remaining;
  final int remainingPercent;
  final Color barColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 14,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
      color: const Color(0xFF1C2430),
      height: 1.1,
    );

    return Container(
      color: emphasized ? const Color(0xFFF7F9FC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: diameter == null
                ? Text(label ?? '', style: valueStyle)
                : Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.diameterColor(diameter!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Ø$diameter', style: valueStyle),
                    ],
                  ),
          ),
          Expanded(
            flex: 26,
            child: _AmountCell(
              value: ordered,
              percent: orderedPercent,
              valueStyle: valueStyle,
            ),
          ),
          Expanded(
            flex: 26,
            child: _AmountCell(
              value: delivered,
              percent: deliveredPercent,
              valueStyle: valueStyle,
              percentColor: barColor,
            ),
          ),
          Expanded(
            flex: 26,
            child: _AmountCell(
              value: remaining,
              percent: remainingPercent,
              valueStyle: valueStyle,
              percentColor: remaining > 0.05
                  ? const Color(0xFFF59E0B)
                  : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.value,
    required this.percent,
    required this.valueStyle,
    this.percentColor,
  });

  final double value;
  final int percent;
  final TextStyle valueStyle;
  final Color? percentColor;

  @override
  Widget build(BuildContext context) {
    final shown = percent.clamp(0, 999);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppFormat.tonnage(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '%$shown',
          style: TextStyle(
            color: percentColor ?? const Color(0xFF8B95A5),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
