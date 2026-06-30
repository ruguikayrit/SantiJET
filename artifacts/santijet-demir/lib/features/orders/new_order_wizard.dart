import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/features/orders/order_imalat_balance.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/orders/providers/supplier_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class NewOrderWizardScreen extends ConsumerStatefulWidget {
  const NewOrderWizardScreen({super.key});

  @override
  ConsumerState<NewOrderWizardScreen> createState() =>
      _NewOrderWizardScreenState();
}

class _NewOrderWizardScreenState extends ConsumerState<NewOrderWizardScreen> {
  int _step = 0;
  final _pageController = PageController();

  static const _stepTitles = [
    'İmalat Seçimi',
    'Oran Belirleme',
    'Çap Hesabı',
    'Tedarikçi Seçimi',
    'Özet & Onay',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 4) {
      if (_step == 1) {
        ref.read(newOrderDraftProvider.notifier).syncDiameterLinesFromTotal();
      }
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    final draft = ref.read(newOrderDraftProvider);
    final created = await ref.read(ordersProvider.notifier).createOrder(draft);
    ref.read(newOrderDraftProvider.notifier).reset();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created == null
              ? 'Sipariş kaydedilemedi'
              : 'Sipariş oluşturuldu — Onay Bek. sekmesinde',
        ),
        backgroundColor:
            created == null ? AppColors.warning : AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(newOrderDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Sipariş', style: AppTypography.titleLarge),
            Text(
              'Adım ${_step + 1}/5 — ${_stepTitles[_step]}',
              style: AppTypography.labelMedium,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: List.generate(5, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.electricBlue
                          : AppColors.border,
                      borderRadius: AppRadii.full,
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1ImalatSelection(draft: draft),
                _Step2RatioSelector(draft: draft),
                _Step3DiameterTable(draft: draft),
                _Step4SupplierSelection(draft: draft),
                _Step5Summary(draft: draft),
              ],
            ),
          ),
          _buildBottomBar(draft),
        ],
      ),
    );
  }

  Widget _buildBottomBar(NewOrderDraft draft) {
    final canProceed = switch (_step) {
      0 => draft.selectedImalats.isNotEmpty,
      3 => draft.selectedSupplier != null,
      _ => true,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step == 4)
            Expanded(
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Siparişi Oluştur'),
              ),
            )
          else
            Expanded(
              child: FilledButton(
                onPressed: canProceed ? _next : null,
                child: Text(_step == 3 ? 'Özete Geç' : 'Devam'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step1ImalatSelection extends ConsumerWidget {
  const _Step1ImalatSelection({required this.draft});

  final NewOrderDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(newOrderDraftProvider.notifier);
    final survey = ref.watch(surveyProjectProvider);
    final balances = ref.watch(imalatOrderBalanceProvider);
    final balanceByName = {for (final b in balances) b.name: b};
    final options = survey.imalats
        .map((i) => balanceByName[i.name] ?? ImalatOrderBalance(
              name: i.name,
              surveyTotal: i.planned,
              orderedSoFar: 0,
            ))
        .toList();
    final total = draft.selectedImalats.values.fold(0.0, (s, v) => s + v);
    final totalRemaining =
        options.fold(0.0, (sum, balance) => sum + balance.remaining);

    if (options.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İmalat türlerini seçin', style: AppTypography.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Toplam keşif, daha önce sipariş edilen ve kalan miktarlar birlikte gösterilir.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ModuleEmptyState(
              type: EmptyStateType.noSurvey,
              actionLabel: 'Keşif Oluştur',
              onAction: () => context.push(AppRoutes.survey),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('İmalat türlerini seçin', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Toplam keşif, daha önce sipariş edilen ve kalan miktarlar birlikte gösterilir.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 16),
        ...options.map((balance) {
          final name = balance.name;
          final selected = draft.selectedImalats.containsKey(name);
          final canSelect = balance.hasRemaining;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canSelect
                    ? () => notifier.toggleImalat(name, balance.remaining)
                    : null,
                borderRadius: AppRadii.md,
                child: Opacity(
                  opacity: canSelect ? 1 : 0.55,
                  child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.electricBlue.withValues(alpha: 0.1)
                        : AppColors.surfaceElevated,
                    borderRadius: AppRadii.md,
                    border: Border.all(
                      color: selected ? AppColors.electricBlue : AppColors.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: selected
                            ? AppColors.electricBlue
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppTypography.titleMedium),
                            const SizedBox(height: 6),
                            Text(
                              'Toplam ${balance.surveyTotal.toStringAsFixed(0)}t · '
                              'Sipariş ${balance.orderedSoFar.toStringAsFixed(0)}t · '
                              'Kalan ${balance.remaining.toStringAsFixed(0)}t',
                              style: AppTypography.bodySmall.copyWith(
                                color: canSelect
                                    ? AppColors.electricBlueLight
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Seçilen Kalan', style: AppTypography.titleMedium),
                    Text(
                      '${total.toStringAsFixed(0)}t',
                      style: AppTypography.kpiValue.copyWith(
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Toplam Kalan', style: AppTypography.bodyMedium),
                    Text(
                      '${totalRemaining.toStringAsFixed(0)}t',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Step2RatioSelector extends ConsumerWidget {
  const _Step2RatioSelector({required this.draft});

  final NewOrderDraft draft;

  static const _quickRatios = [25, 50, 75, 100];

  Future<void> _showManualRatioDialog(
    BuildContext context,
    WidgetRef ref,
    String imalatName,
    int currentRatio,
  ) async {
    final controller = TextEditingController(text: currentRatio.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Manuel Oran', style: AppTypography.titleLarge),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sipariş oranı (%)',
            hintText: '1 – 100',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 1 || value > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('1 ile 100 arasında bir oran girin')),
                );
                return;
              }
              Navigator.pop(ctx, value);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(newOrderDraftProvider.notifier).setImalatRatio(imalatName, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(newOrderDraftProvider.notifier);
    final balances = ref.watch(imalatOrderBalanceProvider);
    final balanceByName = {for (final b in balances) b.name: b};
    final imalats = draft.selectedImalats.entries.toList();
    final totalRemaining =
        imalats.fold(0.0, (sum, entry) => sum + entry.value);
    final totalSurvey = imalats.fold(0.0, (sum, entry) {
      final balance = balanceByName[entry.key];
      return sum + (balance?.surveyTotal ?? entry.value);
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Sipariş oranı', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Oran, kalan tonaj üzerinden hesaplanır. Önceki siparişler düşüldükten sonra kalan miktarın yüzde kaçı sipariş edilecek?',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 16),
        ...imalats.map((entry) {
          final name = entry.key;
          final remainingTonnage = entry.value;
          final balance = balanceByName[name];
          final ratio = draft.imalatRatios[name] ?? 100;
          final orderTonnage = draft.imalatOrderTonnage(name);
          final isManualRatio = !_quickRatios.contains(ratio);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.md,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(name, style: AppTypography.titleMedium),
                  if (balance != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Toplam ${balance.surveyTotal.toStringAsFixed(0)}t · '
                      'Sipariş ${balance.orderedSoFar.toStringAsFixed(0)}t · '
                      'Kalan ${balance.remaining.toStringAsFixed(0)}t',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Kalan ${remainingTonnage.toStringAsFixed(0)}t',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.electricBlueLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _quickRatios.map((r) {
                      final selected = ratio == r;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: r < 100 ? 6 : 0),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => notifier.setImalatRatio(name, r),
                              borderRadius: AppRadii.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.electricBlue.withValues(alpha: 0.15)
                                      : AppColors.surfaceHighlight,
                                  borderRadius: AppRadii.sm,
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.electricBlue
                                        : AppColors.border,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '%$r',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: selected
                                          ? AppColors.electricBlueLight
                                          : AppColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showManualRatioDialog(
                          context,
                          ref,
                          name,
                          ratio,
                        ),
                        style: isManualRatio
                            ? OutlinedButton.styleFrom(
                                foregroundColor: AppColors.electricBlueLight,
                                side: const BorderSide(color: AppColors.electricBlue),
                                backgroundColor:
                                    AppColors.electricBlue.withValues(alpha: 0.1),
                              )
                            : null,
                        icon: const Icon(Icons.tune, size: 16),
                        label: Text(
                          isManualRatio ? 'Manuel Oran · %$ratio' : 'Manuel Oran',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sipariş: ${orderTonnage.toStringAsFixed(1)}t',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.electricBlueLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _SummaryRow(
                'Keşif Toplamı',
                '${totalSurvey.toStringAsFixed(0)}t',
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                'Kalan Toplam',
                '${totalRemaining.toStringAsFixed(0)}t',
              ),
              const Divider(height: 24, color: AppColors.border),
              _SummaryRow(
                'Toplam Sipariş Tonajı',
                '${draft.totalTonnage.toStringAsFixed(1)}t',
                highlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step3DiameterTable extends ConsumerWidget {
  const _Step3DiameterTable({required this.draft});

  final NewOrderDraft draft;

  Future<void> _showEditAmountDialog(
    BuildContext context,
    WidgetRef ref,
    DiameterOrderLine line,
    double calculatedAmount,
  ) async {
    final controller = TextEditingController(
      text: line.orderAmount.toStringAsFixed(1),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Ø${line.diameter} Sipariş Düzeltmesi', style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hesaplanan: ${calculatedAmount.toStringAsFixed(1)}t',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Sipariş miktarı (ton)',
                hintText: 'Örn: 286',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final normalized = controller.text.trim().replaceAll(',', '.');
              final value = double.tryParse(normalized);
              if (value == null || value < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir tonaj girin')),
                );
                return;
              }
              Navigator.pop(ctx, value);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      ref
          .read(newOrderDraftProvider.notifier)
          .setDiameterOrderAmount(line.diameter, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(newOrderDraftProvider.notifier);
    final calculatedLines = calculateDiameterLinesFromSurvey(
      totalTonnage: draft.totalTonnage,
      surveyPlannedByDiameter: draft.surveyPlannedByDiameter,
    );
    final calculatedByDiameter = {
      for (final line in calculatedLines) line.diameter: line.orderAmount,
    };
    final lines = draft.diameterLines;
    final hasAdjustments = lines.any((line) {
      final calculated = calculatedByDiameter[line.diameter] ?? line.orderAmount;
      return (line.orderAmount - calculated).abs() > 0.05;
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Çap bazlı hesap', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Sipariş miktarlarını son düzeltme için dokunarak güncelleyin.',
          style: AppTypography.bodySmall,
        ),
        if (hasAdjustments) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: notifier.resetDiameterAdjustments,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Hesaplanana Dön'),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
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
                    Expanded(flex: 2, child: Text('ÇAP', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                    Expanded(flex: 3, child: Text('MEVCUT', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                    Expanded(flex: 3, child: Text('SİPARİŞ', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
              ...lines.map((line) {
                final color = AppColors.diameterColor(line.diameter);
                final calculated = calculatedByDiameter[line.diameter] ?? line.orderAmount;
                final isAdjusted = (line.orderAmount - calculated).abs() > 0.05;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showEditAmountDialog(
                      context,
                      ref,
                      line,
                      calculated,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: AppRadii.xs,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Ø${line.diameter}', style: AppTypography.titleMedium),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${line.currentStock.toStringAsFixed(1)}t',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${line.orderAmount.toStringAsFixed(1)}t',
                                        style: AppTypography.titleMedium.copyWith(
                                          color: isAdjusted
                                              ? AppColors.warning
                                              : color,
                                        ),
                                      ),
                                      if (isAdjusted)
                                        Text(
                                          'Hesap: ${calculated.toStringAsFixed(1)}t',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: AppRadii.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam Sipariş', style: AppTypography.titleMedium),
              Text(
                '${draft.finalOrderTonnage.toStringAsFixed(1)}t',
                style: AppTypography.kpiValue.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step4SupplierSelection extends ConsumerWidget {
  const _Step4SupplierSelection({required this.draft});

  final NewOrderDraft draft;

  Future<void> _showCreateSupplierDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final deliveryCtrl = TextEditingController(text: '7');

    final created = await showDialog<SupplierOption>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Tedarikçi Oluştur', style: AppTypography.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tedarikçi adı'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Birim fiyat (TL/ton)',
                  hintText: 'Örn: 18500',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deliveryCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Teslimat süresi (gün)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(
                priceCtrl.text.trim().replaceAll(',', '.'),
              );
              final delivery = int.tryParse(deliveryCtrl.text.trim());

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tedarikçi adı girin')),
                );
                return;
              }
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir birim fiyat girin')),
                );
                return;
              }
              if (delivery == null || delivery < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir teslimat süresi girin')),
                );
                return;
              }

              final supplier = await ref
                  .read(supplierOptionsProvider.notifier)
                  .addSupplier(
                    name: name,
                    pricePerTon: price,
                    deliveryDays: delivery,
                  );
              if (ctx.mounted) Navigator.pop(ctx, supplier);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
    deliveryCtrl.dispose();

    if (created != null) {
      ref.read(newOrderDraftProvider.notifier).selectSupplier(created);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(newOrderDraftProvider.notifier);
    final suppliers = ref.watch(supplierOptionsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Tedarikçi seçin', style: AppTypography.headlineMedium),
        const SizedBox(height: 16),
        if (suppliers.isEmpty)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Henüz tanımlı tedarikçi yok.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateSupplierDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Tedarikçi Oluştur'),
              ),
            ],
          )
        else ...[
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showCreateSupplierDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tedarikçi Oluştur'),
            ),
          ),
          const SizedBox(height: 12),
          ...suppliers.map((supplier) {
          final selected = draft.selectedSupplier?.name == supplier.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => notifier.selectSupplier(supplier),
                borderRadius: AppRadii.md,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.electricBlue.withValues(alpha: 0.1)
                        : AppColors.surfaceElevated,
                    borderRadius: AppRadii.md,
                    border: Border.all(
                      color:
                          selected ? AppColors.electricBlue : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(supplier.name, style: AppTypography.titleLarge),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                supplier.rating.toStringAsFixed(1),
                                style: AppTypography.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _SupplierMetric(
                            label: 'Birim Fiyat',
                            value: '${AppFormat.currency(supplier.pricePerTon)}/t',
                          ),
                          const SizedBox(width: 24),
                          _SupplierMetric(
                            label: 'Teslimat',
                            value: '${supplier.deliveryDays} gün',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tahmini: ${AppFormat.currency(supplier.pricePerTon * draft.finalOrderTonnage)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.electricBlueLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        ],
      ],
    );
  }
}

class _Step5Summary extends StatelessWidget {
  const _Step5Summary({required this.draft});

  final NewOrderDraft draft;

  @override
  Widget build(BuildContext context) {
    final supplier = draft.selectedSupplier!;
    final totalCost = supplier.pricePerTon * draft.finalOrderTonnage;
    final lines = draft.diameterLines;
    final autoTotalTonnage = calculateDiameterLinesFromSurvey(
      totalTonnage: draft.totalTonnage,
      surveyPlannedByDiameter: draft.surveyPlannedByDiameter,
    ).fold(0.0, (sum, line) => sum + line.orderAmount);
    final adjustedTotalTonnage = draft.finalOrderTonnage;
    final hasAdjustment = (adjustedTotalTonnage - autoTotalTonnage).abs() > 0.05;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Sipariş özeti', style: AppTypography.headlineMedium),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImalatSummarySection(draft: draft),
              const SizedBox(height: 12),
              _SummaryRow(
                'Otomatik Hesap Toplam',
                '${autoTotalTonnage.toStringAsFixed(1)}t',
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                'Düzeltilmiş Toplam',
                '${adjustedTotalTonnage.toStringAsFixed(1)}t',
                highlight: hasAdjustment,
              ),
              const SizedBox(height: 8),
              _SummaryRow('Tedarikçi', supplier.name),
              const Divider(height: 24, color: AppColors.border),
              _SummaryRow(
                'Tahmini Tutar',
                AppFormat.currency(totalCost),
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Çap dağılımı', style: AppTypography.titleLarge),
        const SizedBox(height: 8),
        ...lines.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ø${l.diameter}', style: AppTypography.bodyMedium),
                  Text(
                    '${l.orderAmount.toStringAsFixed(1)}t',
                    style: AppTypography.titleMedium,
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _ImalatSummarySection extends StatelessWidget {
  const _ImalatSummarySection({required this.draft});

  final NewOrderDraft draft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İmalatlar', style: AppTypography.bodyMedium),
        const SizedBox(height: 8),
        ...draft.selectedImalats.keys.map((name) {
          final ratio = draft.imalatRatios[name] ?? 100;
          final tonnage = draft.imalatOrderTonnage(name);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(name, style: AppTypography.labelMedium),
                ),
                Text(
                  '%$ratio → ${tonnage.toStringAsFixed(1)}t',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
    final valueStyle = highlight
        ? AppTypography.kpiValue.copyWith(
            fontSize: 22,
            color: AppColors.electricBlueLight,
          )
        : AppTypography.titleMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(label, style: AppTypography.bodyMedium),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _SupplierMetric extends StatelessWidget {
  const _SupplierMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        Text(value, style: AppTypography.titleMedium),
      ],
    );
  }
}
