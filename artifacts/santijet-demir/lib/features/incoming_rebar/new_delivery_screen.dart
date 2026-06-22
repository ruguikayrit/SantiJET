import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/mock/mock_deliveries.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

class NewDeliveryScreen extends ConsumerStatefulWidget {
  const NewDeliveryScreen({super.key});

  @override
  ConsumerState<NewDeliveryScreen> createState() => _NewDeliveryScreenState();
}

class _NewDeliveryScreenState extends ConsumerState<NewDeliveryScreen> {
  final _orderController = TextEditingController(text: 'SIP-2025-0048');
  final _irsaliyeController = TextEditingController();
  final _plateController = TextEditingController();
  final _diameterControllers = {
    16: TextEditingController(text: '28'),
    20: TextEditingController(text: '20'),
    22: TextEditingController(text: '0'),
  };

  @override
  void dispose() {
    _orderController.dispose();
    _irsaliyeController.dispose();
    _plateController.dispose();
    for (final c in _diameterControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalOrdered {
    final diameters = matchedOrderInfo['diameters'] as Map<int, double>;
    return diameters.values.fold(0.0, (s, v) => s + v);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(newDeliveryDraftProvider);
    final notifier = ref.read(newDeliveryDraftProvider.notifier);
    const suppliers = ['Çolakoğlu', 'Kardemir', 'İsdemir', 'Erdemir'];
    final selectedSupplier = draft.supplier ?? 'Çolakoğlu';
    final totalDelivered = draft.totalDelivered;
    final diff = totalDelivered - _totalOrdered;
    final fulfillment = _totalOrdered > 0 ? totalDelivered / _totalOrdered * 100 : 0;
    final isPartial = fulfillment > 0 && fulfillment < 99;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Yeni Teslimat')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (isPartial)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: AppRadii.md,
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kısmi teslim tespit edildi — %${fulfillment.toStringAsFixed(0)} karşılama',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          Text('Firma', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ...suppliers.map((s) {
            final selected = selectedSupplier == s;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RadioListTile<String>(
                title: Text(s, style: AppTypography.titleMedium),
                value: s,
                groupValue: selectedSupplier,
                onChanged: (v) => notifier.setSupplier(v!),
                activeColor: AppColors.electricBlue,
                tileColor: selected
                    ? AppColors.electricBlue.withValues(alpha: 0.08)
                    : AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.md,
                  side: BorderSide(
                    color: selected ? AppColors.electricBlue : AppColors.border,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text('Sipariş No', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _orderController,
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.check_circle, color: AppColors.success),
              helperText: 'Eşleşen sipariş: ${matchedOrderInfo['totalOrdered']}t — ${matchedOrderInfo['supplier']}',
            ),
          ),
          const SizedBox(height: 16),
          Text('İrsaliye No', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _irsaliyeController,
            decoration: const InputDecoration(hintText: 'IR-2025-XXXX'),
          ),
          const SizedBox(height: 16),
          Text('Plaka No', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _plateController,
            decoration: const InputDecoration(hintText: '34 ABC 123'),
          ),
          const SizedBox(height: 20),
          Text('Çap Girişi', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          _CapEntryTable(
            controllers: _diameterControllers,
            onDeliveryChanged: (diameter, value) {
              notifier.setDiameterEntry(diameter, double.tryParse(value) ?? 0);
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow('Toplam Sipariş', '${_totalOrdered.toStringAsFixed(1)}t'),
                _SummaryRow('Toplam Teslim', '${totalDelivered.toStringAsFixed(1)}t'),
                _SummaryRow(
                  'Fark',
                  '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}t',
                  highlight: diff.abs() > 0,
                ),
                _SummaryRow(
                  'Karşılama',
                  '%${fulfillment.toStringAsFixed(0)}',
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              notifier.reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Teslimat kaydedildi'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop();
            },
            child: const Text('Teslimatı Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _CapEntryTable extends StatelessWidget {
  const _CapEntryTable({
    required this.controllers,
    required this.onDeliveryChanged,
  });

  final Map<int, TextEditingController> controllers;
  final void Function(int diameter, String value) onDeliveryChanged;

  @override
  Widget build(BuildContext context) {
    final ordered = matchedOrderInfo['diameters'] as Map<int, double>;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(child: Text('ÇAP', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                Expanded(child: Text('SİPARİŞ', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                Expanded(child: Text('TESLİM', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          ...controllers.entries.map((e) {
            final color = AppColors.diameterColor(e.key);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Ø${e.key}', style: AppTypography.titleMedium.copyWith(color: color)),
                  ),
                  Expanded(
                    child: Text(
                      '${ordered[e.key]?.toStringAsFixed(0) ?? '-'}t',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      keyboardType: TextInputType.number,
                      style: AppTypography.titleMedium,
                      onChanged: (value) => onDeliveryChanged(e.key, value),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        suffixText: 't',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            value,
            style: highlight
                ? AppTypography.titleMedium.copyWith(color: AppColors.electricBlueLight)
                : AppTypography.titleMedium,
          ),
        ],
      ),
    );
  }
}
