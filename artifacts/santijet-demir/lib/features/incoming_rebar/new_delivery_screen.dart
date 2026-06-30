import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

class NewDeliveryScreen extends ConsumerStatefulWidget {
  const NewDeliveryScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<NewDeliveryScreen> createState() => _NewDeliveryScreenState();
}

class _NewDeliveryScreenState extends ConsumerState<NewDeliveryScreen> {
  final _irsaliyeController = TextEditingController();
  final _plateController = TextEditingController();
  final _diameterControllers = <int, TextEditingController>{};
  bool _initialized = false;

  @override
  void dispose() {
    _irsaliyeController.dispose();
    _plateController.dispose();
    for (final controller in _diameterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(NewDeliveryDraft draft) {
    for (final entry in draft.orderedDiameters.entries) {
      _diameterControllers.putIfAbsent(
        entry.key,
        () => TextEditingController(
          text: (draft.diameterEntries[entry.key] ?? 0) == 0
              ? ''
              : (draft.diameterEntries[entry.key] ?? 0).toStringAsFixed(1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(newDeliveryDraftProvider);
    final notifier = ref.read(newDeliveryDraftProvider.notifier);

    if (!_initialized && widget.orderId != null) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final draftNotifier = ref.read(newDeliveryDraftProvider.notifier);
        draftNotifier.reset();
        draftNotifier.loadFromOrder(widget.orderId!);
      });
    }

    if (draft.orderId != null && _diameterControllers.isEmpty) {
      _syncControllers(draft);
    }

    if (draft.orderId == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Yeni Teslimat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Teslimat kaydı için önce yoldaki bir sevkiyat seçilmelidir.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final totalOrdered = draft.totalOrdered;
    final totalDelivered = draft.totalDelivered;
    final diff = totalDelivered - totalOrdered;
    final fulfillment =
        totalOrdered > 0 ? totalDelivered / totalOrdered * 100 : 0;
    final isPartial = fulfillment > 0 && fulfillment < 99;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Yeni Teslimat')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bağlı Sipariş', style: AppTypography.labelMedium),
                const SizedBox(height: 6),
                Text(draft.orderNo, style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text(
                  draft.supplier ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ],
            ),
          ),
          if (isPartial) ...[
            const SizedBox(height: 16),
            Container(
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
          ],
          const SizedBox(height: 16),
          Text('İrsaliye No', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _irsaliyeController,
            decoration: const InputDecoration(
              hintText: 'IR-2025-XXXX',
              helperText: 'İrsaliyedeki numarayı girin',
            ),
            onChanged: notifier.setIrsaliyeNo,
          ),
          const SizedBox(height: 16),
          Text('Plaka No', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _plateController,
            decoration: const InputDecoration(hintText: '34 ABC 123'),
            onChanged: notifier.setPlateNo,
          ),
          const SizedBox(height: 20),
          Text('İrsaliye Çap Girişi', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Sipariş miktarları referans olarak gösterilir; irsaliyedeki teslim miktarlarını girin.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          _CapEntryTable(
            orderedDiameters: draft.orderedDiameters,
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
                _SummaryRow('Toplam Sipariş', '${totalOrdered.toStringAsFixed(1)}t'),
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
            onPressed: () => _saveDelivery(context),
            child: const Text('Teslimatı Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDelivery(BuildContext context) async {
    final draft = ref.read(newDeliveryDraftProvider);
    final result =
        await ref.read(deliveriesProvider.notifier).saveDelivery(draft);
    if (!context.mounted) return;

    final message = switch (result) {
      DeliverySaveResult.success =>
        '${draft.orderNo} teslimatı kaydedildi',
      DeliverySaveResult.missingOrder => 'Sevkiyat seçilmedi',
      DeliverySaveResult.invalidOrderStatus =>
        'Sipariş yolda değil, teslimat kaydedilemez',
      DeliverySaveResult.missingIrsaliye => 'İrsaliye numarası zorunludur',
      DeliverySaveResult.missingDeliveredAmount =>
        'En az bir çap için teslim miktarı girin',
      DeliverySaveResult.orderNotFound => 'Sipariş bulunamadı',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result == DeliverySaveResult.success
            ? AppColors.success
            : AppColors.critical,
      ),
    );

    if (result == DeliverySaveResult.success) {
      ref.read(newDeliveryDraftProvider.notifier).reset();
      context.go('/incoming-rebar');
    }
  }
}

class _CapEntryTable extends StatelessWidget {
  const _CapEntryTable({
    required this.orderedDiameters,
    required this.controllers,
    required this.onDeliveryChanged,
  });

  final Map<int, double> orderedDiameters;
  final Map<int, TextEditingController> controllers;
  final void Function(int diameter, String value) onDeliveryChanged;

  @override
  Widget build(BuildContext context) {
    final diameters = orderedDiameters.keys.toList()..sort();

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
                Expanded(
                  child: Text(
                    'ÇAP',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    'SİPARİŞ',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    'TESLİM',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          ...diameters.map((diameter) {
            final color = AppColors.diameterColor(diameter);
            final controller = controllers[diameter] ?? TextEditingController();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ø$diameter',
                      style: AppTypography.titleMedium.copyWith(color: color),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(orderedDiameters[diameter] ?? 0).toStringAsFixed(1)}t',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: AppTypography.titleMedium,
                      onChanged: (value) => onDeliveryChanged(diameter, value),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        suffixText: 't',
                        hintText: '0',
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
