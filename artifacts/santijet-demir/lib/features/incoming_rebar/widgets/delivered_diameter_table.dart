import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

/// Referans ölçek: başlık 11, hücre 12, satır yüksekliği sıkı, bar 5 px.
class DeliveredDiameterTable extends StatelessWidget {
  const DeliveredDiameterTable({
    super.key,
    required this.rows,
    this.asPercent = false,
  });

  final List<DeliveredDiameterRow> rows;
  final bool asPercent;

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
          _Header(unit: asPercent ? '%' : ''),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Text(
                'Bu dönemde çap kaydı yok',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B95A5),
                ),
              ),
            )
          else
            for (final row in rows)
              _DataRow(
                diameter: row.diameter,
                ordered: _cell(row.ordered, totalOrdered),
                delivered: _cell(row.delivered, row.ordered),
                remaining: _cell(_remaining(row), row.ordered),
                percent: _percent(row.delivered, row.ordered),
                barColor: _percent(row.delivered, row.ordered) >= 100
                    ? AppColors.success
                    : AppColors.diameterColor(row.diameter),
              ),
          _DataRow(
            label: 'TOPLAM',
            ordered: _cell(totalOrdered, totalOrdered),
            delivered: _cell(totalDelivered, totalOrdered),
            remaining: _cell(totalRemaining, totalOrdered),
            percent: _percent(totalDelivered, totalOrdered),
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

  String _cell(double value, double base) {
    if (!asPercent) return AppFormat.tonnage(value);
    if (base <= 0) return '0';
    return (value / base * 100).round().toString();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unit});

  final String unit;

  String _title(String label) => unit.isEmpty ? label : '$label\n($unit)';

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0xFF8B95A5),
      height: 1.1,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Row(
        children: [
          const Expanded(flex: 22, child: Text('ÇAP', style: style)),
          Expanded(flex: 18, child: Text(_title('SİPARİŞ'), style: style, textAlign: TextAlign.center)),
          Expanded(flex: 18, child: Text(_title('TESLİM'), style: style, textAlign: TextAlign.center)),
          Expanded(flex: 16, child: Text(_title('KALAN'), style: style, textAlign: TextAlign.center)),
          const Expanded(flex: 26, child: Text('DURUM', style: style, textAlign: TextAlign.right)),
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
    required this.delivered,
    required this.remaining,
    required this.percent,
    required this.barColor,
    this.emphasized = false,
  });

  final int? diameter;
  final String? label;
  final String ordered;
  final String delivered;
  final String remaining;
  final int percent;
  final Color barColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 12,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
      color: const Color(0xFF1C2430),
      height: 1.1,
    );
    final shown = percent < 0 ? 0 : percent;
    final barValue = (shown / 100).clamp(0.0, 1.0);

    return Container(
      color: emphasized ? const Color(0xFFF7F9FC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            flex: 18,
            child: Text(ordered, style: valueStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 18,
            child: Text(delivered, style: valueStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 16,
            child: Text(remaining, style: valueStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 26,
            child: Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: barValue,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE6EBF2),
                      color: barColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 32,
                  child: Text(
                    '%$shown',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
