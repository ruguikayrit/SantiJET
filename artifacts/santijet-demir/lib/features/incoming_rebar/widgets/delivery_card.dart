import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';

const _months = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

class DeliveryCard extends StatefulWidget {
  const DeliveryCard({
    super.key,
    required this.delivery,
    this.projectName = '',
  });

  final DeliveryItem delivery;
  final String projectName;

  @override
  State<DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<DeliveryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final statusColor = Color(delivery.status.colorValue);
    final lines = delivery.diameterLines
        .where((line) => line.ordered > 0 || line.delivered > 0)
        .toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));
    final hour = delivery.date.hour.toString().padLeft(2, '0');
    final minute = delivery.date.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(
                        '${delivery.date.day}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C2430),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _months[delivery.date.month - 1],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C6B80),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '${delivery.date.year}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8B95A5),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.supplier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C2430),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'İrsaliye No: ${delivery.irsaliyeNo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8B95A5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormat.tonnage(delivery.tonnage),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C2430),
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: const Color(0xFF8B95A5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 52),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    delivery.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      height: 1.1,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 14, color: const Color(0xFF8B95A5)),
                const SizedBox(width: 4),
                Text(
                  '$hour:$minute',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C6B80),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            if (widget.projectName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 52),
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8B95A5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.projectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5C6B80),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_expanded) ...[
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Çap Karşılaştırma',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C2430),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(flex: 2, child: _Head('ÇAP')),
                        Expanded(flex: 3, child: _Head('SİPARİŞ', align: TextAlign.center)),
                        Expanded(flex: 3, child: _Head('TESLİM', align: TextAlign.center)),
                        Expanded(flex: 3, child: _Head('FARK', align: TextAlign.end)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (lines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Çap kaydı yok',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8B95A5),
                          ),
                        ),
                      )
                    else
                      for (final line in lines) _LineRow(line: line),
                  ],
                ),
              ),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.label, {this.align = TextAlign.start});

  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8B95A5),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final DeliveryDiameterLine line;

  @override
  Widget build(BuildContext context) {
    final diff = line.difference;
    final (diffText, diffColor) = switch (line) {
      _ when line.isMatch => ('✓', AppColors.success),
      _ when line.isExcess => ('+${AppFormat.tonnage(diff)}', const Color(0xFF8B5CF6)),
      _ => (AppFormat.tonnage(diff), AppColors.critical),
    };
    const valueStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1C2430),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.diameterColor(line.diameter),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Ø${line.diameter}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2430),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              AppFormat.tonnage(line.ordered),
              textAlign: TextAlign.center,
              style: valueStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              AppFormat.tonnage(line.delivered),
              textAlign: TextAlign.center,
              style: valueStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              diffText,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: diffColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompactDeliveryTile extends StatelessWidget {
  const CompactDeliveryTile({super.key, required this.delivery});

  final DeliveryItem delivery;

  @override
  Widget build(BuildContext context) {
    return DeliveryCard(delivery: delivery);
  }
}
