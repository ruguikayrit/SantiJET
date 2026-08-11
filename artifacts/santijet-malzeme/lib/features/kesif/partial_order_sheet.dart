import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/kesif/material_need_calculator.dart';

/// Talebe ekle — % veya manuel miktar ile kısmi sipariş.
class PartialOrderSheet extends StatefulWidget {
  const PartialOrderSheet({super.key, required this.needs});

  final List<MaterialNeed> needs;

  @override
  State<PartialOrderSheet> createState() => _PartialOrderSheetState();
}

class _PartialOrderLine {
  _PartialOrderLine(this.need)
      : percent = 100,
        qtyCtrl = TextEditingController(text: _fmt(need.quantity));

  final MaterialNeed need;
  int percent;
  final TextEditingController qtyCtrl;

  double get fullQty => need.quantity;

  double get orderQty {
    final v = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
    if (v != null) return v.clamp(0, fullQty * 2);
    return fullQty * percent / 100;
  }

  void applyPercent(int p) {
    percent = p;
    final q = fullQty * p / 100;
    qtyCtrl.text = _fmt(q);
  }

  void syncPercentFromQty() {
    final v = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
    if (v == null || fullQty <= 0) {
      percent = -1;
      return;
    }
    final p = ((v / fullQty) * 100).round();
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
    _lines = [for (final n in widget.needs) _PartialOrderLine(n)];
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
              'Tam ihtiyacın yüzde kaçını sipariş edeceğinizi seçin '
              'veya miktarı elle girin.',
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
              onPressed: () {
                final result = <String, double>{
                  for (final l in _lines) l.need.id: l.orderQty,
                };
                Navigator.pop(context, result);
              },
              child: const Text('Talebe ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineCard(_PartialOrderLine line) {
    final n = line.need;
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
            'Tam ihtiyaç: ${_PartialOrderLine._fmt(n.quantity)} ${n.materialUnit}'
            ' · ${n.pozNo}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.cardTextMuted,
            ),
          ),
          const SizedBox(height: 10),
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
                  selectedColor: AppColors.electricBlue.withValues(alpha: 0.22),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.cardTextPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Sipariş miktarı (${n.materialUnit})',
              labelStyle: AppTypography.labelMedium.copyWith(
                color: AppColors.cardTextMuted,
              ),
            ),
            onChanged: (_) {
              setState(() => line.syncPercentFromQty());
            },
          ),
        ],
      ),
    );
  }
}
