import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/element_header_parser.dart';
import 'package:santijet_demir/data/services/metraj_cetvel_summary.dart';
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
                    '(S1[100/160] 182 ADET, K1[30/50] 12 ADET) ile '
                    'eşleştirilemedi.'
                : 'Çizimde eleman başlığı veya demir etiketi bulunamadı.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Her detay bloğunda eleman kodu, ebat ve benzer adet satırı olmalı.',
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

    final summary = summarizeCetvel(cetvel);
    final grouped = _groupByType(cetvel);
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
    final lengthFormat = NumberFormat('#,##0.##', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hideHeader) ...[
          Text('Demir Metraj Cetveli', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${summary.elementCount} eleman · ${summary.rowCount} satır · '
            'benzer katsayısı uygulandı',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        _GrandSummaryCard(
          summary: summary,
          numberFormat: numberFormat,
          lengthFormat: lengthFormat,
        ),
        const SizedBox(height: 16),
        ...grouped.entries.map(
          (entry) => _TypeGroupSection(
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

class _GrandSummaryCard extends StatelessWidget {
  const _GrandSummaryCard({
    required this.summary,
    required this.numberFormat,
    required this.lengthFormat,
  });

  final MetrajCetvelSummary summary;
  final NumberFormat numberFormat;
  final NumberFormat lengthFormat;

  @override
  Widget build(BuildContext context) {
    final diameters = summary.tonnageByDiameter.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Toplam',
                  value: '${numberFormat.format(summary.totalTonnage)} t',
                  accent: AppColors.electricBlueLight,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'İnce (Ø8–12)',
                  value: '${numberFormat.format(summary.thinTonnage)} t',
                  accent: AppColors.info,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Kalın (Ø≥14)',
                  value: '${numberFormat.format(summary.thickTonnage)} t',
                  accent: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Toplam boy: ${lengthFormat.format(summary.totalLengthM)} m',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          if (diameters.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: diameters.map((diameter) {
                final tonnage = summary.tonnageByDiameter[diameter] ?? 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: AppRadii.full,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Ø$diameter · ${numberFormat.format(tonnage)} t',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.diameterColor(diameter),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(color: accent),
        ),
      ],
    );
  }
}

class _TypeGroupSection extends StatelessWidget {
  const _TypeGroupSection({
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(type.label, style: AppTypography.titleMedium),
              const Spacer(),
              Text(
                '${entries.length} eleman · ${numberFormat.format(typeTonnage)} t',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.map(
            (entry) => _ElementCetvelCard(
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

class _ElementCetvelCard extends StatelessWidget {
  const _ElementCetvelCard({
    required this.entry,
    required this.numberFormat,
    required this.lengthFormat,
  });

  final MetrajCetvelEntry entry;
  final NumberFormat numberFormat;
  final NumberFormat lengthFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.electricBlue.withValues(alpha: 0.06),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: AppTypography.titleMedium),
                      Text(
                        'Benzer × ${entry.benzerCount} · '
                        '1 ad ${numberFormat.format(entry.unitTonnage)} t',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${numberFormat.format(entry.totalTonnage)} t',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const _CetvelTableHeader(),
          ...entry.rows.asMap().entries.map(
                (indexed) => _CetvelDataRow(
                  index: indexed.key + 1,
                  row: indexed.value,
                  numberFormat: numberFormat,
                  lengthFormat: lengthFormat,
                  striped: indexed.key.isOdd,
                ),
              ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
              color: AppColors.canvas,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Eleman toplamı',
                    style: AppTypography.labelMedium,
                  ),
                ),
                Text(
                  '${entry.totalBarCount} ad · '
                  '${lengthFormat.format(entry.totalLengthM)} m',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(width: 12),
                Text(
                  '${numberFormat.format(entry.totalTonnage)} t',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.electricBlueLight,
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

class _CetvelTableHeader extends StatelessWidget {
  const _CetvelTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          _Col('#', 24, bold: true),
          _Col('Demir', 72, bold: true, flex: 2),
          _Col('Ø', 28, bold: true),
          _Col('Adet', 36, bold: true, align: TextAlign.end),
          _Col('Boy', 40, bold: true, align: TextAlign.end),
          _Col('Top.', 36, bold: true, align: TextAlign.end),
          _Col('kg', 48, bold: true, align: TextAlign.end),
        ],
      ),
    );
  }
}

class _CetvelDataRow extends StatelessWidget {
  const _CetvelDataRow({
    required this.index,
    required this.row,
    required this.numberFormat,
    required this.lengthFormat,
    required this.striped,
  });

  final int index;
  final MetrajCetvelRow row;
  final NumberFormat numberFormat;
  final NumberFormat lengthFormat;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: striped
          ? AppColors.canvas.withValues(alpha: 0.45)
          : Colors.transparent,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Col('$index', 24),
          _Col(row.role.label, 72, flex: 2),
          _Col(
            '${row.diameter}',
            28,
            color: AppColors.diameterColor(row.diameter),
            bold: true,
          ),
          _Col('${row.unitQuantity}', 36, align: TextAlign.end),
          _Col(lengthFormat.format(row.lengthM), 40, align: TextAlign.end),
          _Col('${row.totalQuantity}', 36, align: TextAlign.end),
          _Col(
            numberFormat.format(row.totalWeightKg),
            48,
            align: TextAlign.end,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col(
    this.text,
    this.width, {
    this.flex,
    this.bold = false,
    this.align = TextAlign.start,
    this.color,
  });

  final String text;
  final double width;
  final int? flex;
  final bool bold;
  final TextAlign align;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = (bold ? AppTypography.labelMedium : AppTypography.bodySmall)
        .copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color ?? AppColors.textSecondary,
    );

    if (flex != null) {
      return Expanded(
        flex: flex!,
        child: Text(
          text,
          style: style,
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Text(
        text,
        style: style,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
