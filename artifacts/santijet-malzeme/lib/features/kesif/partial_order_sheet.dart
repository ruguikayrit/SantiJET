import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/kesif/material_need_calculator.dart';

/// Talebe ekle — kalan ihtiyaç üzerinden % veya manuel miktar.
class PartialOrderSheet extends StatefulWidget {
  const PartialOrderSheet({super.key, required this.balances});

  final List<MaterialNeedBalance> balances;

  @override
  State<PartialOrderSheet> createState() => _PartialOrderSheetState();
}

class _PartialOrderLine {
  _PartialOrderLine(this.balance)
      : percent = balance.isFullyOrdered ? -1 : 100,
        qtyCtrl = TextEditingController(
          text: balance.isFullyOrdered
              ? '0'
              : _fmt(balance.remainingQty),
        );

  final MaterialNeedBalance balance;
  int percent;
  final TextEditingController qtyCtrl;

  MaterialNeed get need => balance.need;
  double get remainingQty => balance.remainingQty;

  double get orderQty {
    final v = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
    if (v == null) return 0;
    if (remainingQty <= 0) return 0;
    return v.clamp(0, remainingQty);
  }

  void applyPercent(int p) {
    if (remainingQty <= 0) return;
    percent = p;
    qtyCtrl.text = _fmt(remainingQty * p / 100);
  }

  void syncPercentFromQty() {
    if (remainingQty <= 0) {
      percent = -1;
      return;
    }
    final v = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
    if (v == null) {
      percent = -1;
      return;
    }
    final p = ((v / remainingQty) * 100).round();
    percent = const [25, 50, 75, 100].contains(p) ? p : -1;
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    if ((v * 10).roundToDouble() == v * 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  void dispose() => qtyCtrl.dispose();
}

class _PartialOrderSheetState extends State<PartialOrderSheet> {
  late final List<_PartialOrderLine> _lines;

  static const _presets = [25, 50, 75, 100];

  @override
  void initState() {
    super.initState();
    _lines = [for (final b in widget.balances) _PartialOrderLine(b)];
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.8;
    final hasOrderable = _lines.any((l) => l.remainingQty > 0);

    return SizedBox(
      height: maxH,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sipariş oranı',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Yüzde, kalan ihtiyaca uygulanır. Daha önce talep edilen '
              'miktar düşülür.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _lineCard(_lines[index]),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: hasOrderable
                  ? () {
                      final result = <String, double>{};
                      for (final l in _lines) {
                        final q = l.orderQty;
                        if (q > 0) result[l.need.id] = q;
                      }
                      if (result.isEmpty) return;
                      Navigator.pop(context, result);
                    }
                  : null,
              child: const Text('Talebe ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineCard(_PartialOrderLine line) {
    final n = line.need;
    final b = line.balance;
    final done = b.isFullyOrdered;
    final unit = n.materialUnit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n.materialName,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.cardTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            n.pozNo,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.cardTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          _metaRow('Tam ihtiyaç', '${_PartialOrderLine._fmt(b.fullQty)} $unit'),
          _metaRow(
            'Daha önce talep',
            '${_PartialOrderLine._fmt(b.orderedQty)} $unit',
          ),
          _metaRow(
            'Kalan',
            '${_PartialOrderLine._fmt(b.remainingQty)} $unit',
            emphasize: true,
          ),
          if (done) ...[
            const SizedBox(height: 8),
            Text(
              'Bu malzemenin tamamı daha önce talep edildi.',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.electricBlueLight,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Kalanın yüzde kaçı sipariş edilsin?',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.cardTextMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  ChoiceChip(
                    label: Text('%$p'),
                    selected: line.percent == p,
                    onSelected: (_) {
                      setState(() => line.applyPercent(p));
                    },
                    selectedColor:
                        AppColors.electricBlue.withValues(alpha: 0.22),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: line.percent == p
                          ? AppColors.electricBlueLight
                          : AppColors.cardTextMuted,
                    ),
                    side: BorderSide(
                      color: line.percent == p
                          ? AppColors.electricBlue
                          : AppColors.cardBorder,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: line.qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.cardTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Bu talepteki miktar ($unit)',
                helperText:
                    'En fazla ${_PartialOrderLine._fmt(b.remainingQty)} $unit',
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: AppColors.cardTextMuted,
                ),
              ),
              onChanged: (_) {
                setState(() => line.syncPercentFromQty());
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.cardTextMuted,
              ),
            ),
          ),
          Text(
            value,
            style: (emphasize
                    ? AppTypography.labelLarge
                    : AppTypography.bodySmall)
                .copyWith(
              color: emphasize
                  ? AppColors.electricBlueLight
                  : AppColors.cardTextPrimary,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
