import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/element_header_parser.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

class MetrajCetvelEmptyHint extends StatelessWidget {
  const MetrajCetvelEmptyHint({
    super.key,
    this.labelCount = 0,
  });

  final int labelCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metraj cetveli oluşmadı', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            labelCount > 0
                ? '$labelCount demir etiketi okundu ancak eleman başlıkları '
                    '(S1[100/160] 182 ADET, P1[40/240] 36 ADET) ile '
                    'eşleştirilemedi.'
                : 'Çizimde eleman başlığı veya demir etiketi bulunamadı.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'DWG\'de her perde/kolon detayının üstünde S/P/K/D başlığı ve '
            'benzer adet bilgisi olmalı. Dosyayı yeniden analiz edip tekrar kaydedin.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class MetrajCetvelSection extends StatelessWidget {
  const MetrajCetvelSection({
    super.key,
    required this.cetvel,
    this.hideHeader = false,
  });

  final List<MetrajCetvelEntry> cetvel;
  final bool hideHeader;

  @override
  Widget build(BuildContext context) {
    if (cetvel.isEmpty) return const SizedBox.shrink();

    final grouped = _groupByType(cetvel);
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
    final lengthFormat = NumberFormat('#,##0.##', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideHeader) ...[
          Text('Metraj Cetveli', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${cetvel.length} eleman · benzer katsayısı ile toplam hesap',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        ...grouped.entries.map(
          (entry) => _TypeGroup(
            type: entry.key,
            entries: entry.value,
            numberFormat: numberFormat,
            lengthFormat: lengthFormat,
          ),
        ),
      ],
    );
  }

  Map<StructuralElementType, List<MetrajCetvelEntry>> _groupByType(
    List<MetrajCetvelEntry> entries,
  ) {
    final grouped = <StructuralElementType, List<MetrajCetvelEntry>>{};
    for (final entry in entries) {
      final type = StructuralElementType.fromLetter(entry.elementTypeCode);
      grouped.putIfAbsent(type, () => []).add(entry);
    }
    return grouped;
  }
}

class _TypeGroup extends StatelessWidget {
  const _TypeGroup({
    required this.type,
    required this.entries,
    required this.numberFormat,
    required this.lengthFormat,
  });

  final StructuralElementType type;
  final List<MetrajCetvelEntry> entries;
  final NumberFormat numberFormat;
  final NumberFormat lengthFormat;

  @override
  Widget build(BuildContext context) {
    final typeTonnage =
        entries.fold(0.0, (sum, entry) => sum + entry.totalTonnage);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.label, style: AppTypography.titleMedium),
              const Spacer(),
              Text(
                '${numberFormat.format(typeTonnage)} t',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.map(
            (entry) => _ElementCard(
              entry: entry,
              numberFormat: numberFormat,
              lengthFormat: lengthFormat,
            ),
          ),
        ],
      ),
    );
  }
}

class _ElementCard extends StatefulWidget {
  const _ElementCard({
    required this.entry,
    required this.numberFormat,
    required this.lengthFormat,
  });

  final MetrajCetvelEntry entry;
  final NumberFormat numberFormat;
  final NumberFormat lengthFormat;

  @override
  State<_ElementCard> createState() => _ElementCardState();
}

class _ElementCardState extends State<_ElementCard> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final numberFormat = widget.numberFormat;
    final lengthFormat = widget.lengthFormat;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadii.md,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.title, style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Benzer × ${entry.benzerCount} adet · '
                          '1 adet ${numberFormat.format(entry.unitTonnage)} t → '
                          'toplam ${numberFormat.format(entry.totalTonnage)} t',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _CetvelTable(
                rows: entry.rows,
                numberFormat: numberFormat,
                lengthFormat: lengthFormat,
                benzerCount: entry.benzerCount,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CetvelTable extends StatelessWidget {
  const _CetvelTable({
    required this.rows,
    required this.numberFormat,
    required this.lengthFormat,
    required this.benzerCount,
  });

  final List<MetrajCetvelRow> rows;
  final NumberFormat numberFormat;
  final NumberFormat lengthFormat;
  final int benzerCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 520),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _HeaderCell('Tür', width: 88),
                  _HeaderCell('Çap', width: 44),
                  _HeaderCell('Boy (m)', width: 64),
                  _HeaderCell('1 adet', width: 52),
                  _HeaderCell('× Benzer', width: 64),
                  _HeaderCell('Toplam ad', width: 72),
                  _HeaderCell('Tonaj', width: 72),
                ],
              ),
            ),
            ...rows.map(
              (row) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    _DataCell(row.role.label, width: 88),
                    _DataCell(
                      'Ø${row.diameter}',
                      width: 44,
                      color: AppColors.diameterColor(row.diameter),
                    ),
                    _DataCell(
                      lengthFormat.format(row.lengthM),
                      width: 64,
                    ),
                    _DataCell('${row.unitQuantity}', width: 52),
                    _DataCell('×$benzerCount', width: 64),
                    _DataCell('${row.totalQuantity}', width: 72),
                    _DataCell(
                      '${numberFormat.format(row.totalTonnage)} t',
                      width: 72,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(this.text, {required this.width, this.color});

  final String text;
  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: color ?? AppColors.textSecondary,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
