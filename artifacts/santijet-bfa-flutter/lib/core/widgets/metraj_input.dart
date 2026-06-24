import 'package:flutter/material.dart';

import '../../domain/calc/analiz_hesap.dart';
import '../design_system/sj_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_format.dart';

/// Metraj girişi — miktar girilince anlık tutar (miktar × birim fiyat) hesaplar.
class MetrajInput extends StatefulWidget {
  const MetrajInput({
    required this.birimFiyati,
    required this.olcuBirimi,
    this.initialMiktar = 1,
    this.onChanged,
    super.key,
  });

  final double birimFiyati;
  final String olcuBirimi;
  final double initialMiktar;
  final ValueChanged<double>? onChanged;

  @override
  State<MetrajInput> createState() => _MetrajInputState();
}

class _MetrajInputState extends State<MetrajInput> {
  late final TextEditingController _controller;
  late double _miktar;

  @override
  void initState() {
    super.initState();
    _miktar = widget.initialMiktar;
    _controller = TextEditingController(
      text: AppFormat.decimal(_miktar, fractionDigits: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0;
    setState(() => _miktar = value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tutar = AnalizHesap.satirTutar(_miktar, widget.birimFiyati);

    return SJCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Metraj (${widget.olcuBirimi})',
                    style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _onChanged,
                  style: theme.textTheme.titleLarge,
                  decoration: const InputDecoration(isDense: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Tutar', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(
                AppFormat.currency(tutar),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
