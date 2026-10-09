import 'package:santijet_demir/core/format/app_format.dart';
import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/orders/order_imalat_balance.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
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

  List<String> get _stepTitles {
    return [
      'İmalat Seçimi',
      'Oran Belirleme',
      'Çap Hesabı',
      'Özet',
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
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

    final isIndividual = ref.read(authProvider).user?.membershipType !=
        MembershipType.corporate;
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(
        content: Text(
          created == null
              ? 'Sipariş kaydedilemedi'
              : isIndividual
                  ? 'Sipariş oluşturuldu — Verildi'
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
              'Adım ${_step + 1}/${_stepTitles.length} — ${_stepTitles[_step]}',
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
              children: List.generate(4, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
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
      _ => true,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step == 3)
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
                child: Text(_step == 2 ? 'Özete Geç' : 'Devam'),
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
                              'Toplam ${AppFormat.tonnage(balance.surveyTotal)}t · '
                              'Sipariş ${AppFormat.tonnage(balance.orderedSoFar)}t · '
                              'Kalan ${AppFormat.tonnage(balance.remaining)}t',
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
                      '${AppFormat.tonnage(total)}t',
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
                      '${AppFormat.tonnage(totalRemaining)}t',
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
                ScaffoldMessenger.of(context).showAppSnackBar(
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
                      'Toplam ${AppFormat.tonnage(balance.surveyTotal)}t · '
                      'Sipariş ${AppFormat.tonnage(balance.orderedSoFar)}t · '
                      'Kalan ${AppFormat.tonnage(balance.remaining)}t',
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
                        'Kalan ${AppFormat.tonnage(remainingTonnage)}t',
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
                        'Sipariş: ${AppFormat.tonnage(orderTonnage)}t',
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
                '${AppFormat.tonnage(totalSurvey)}t',
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                'Kalan Toplam',
                '${AppFormat.tonnage(totalRemaining)}t',
              ),
              Divider(height: 24, color: AppColors.border),
              _SummaryRow(
                'Toplam Sipariş',
                '${AppFormat.tonnage(draft.totalTonnage)}t',
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
              'Hesaplanan: ${AppFormat.tonnage(calculatedAmount)}t',
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
                ScaffoldMessenger.of(context).showAppSnackBar(
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
              const AppTableHeaderRow(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                cells: [
                  AppTableHeaderCell('ÇAP', flex: 2),
                  AppTableHeaderCell('MEVCUT', flex: 3),
                  AppTableHeaderCell('SİPARİŞ', flex: 3),
                ],
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
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                              '${AppFormat.tonnage(line.currentStock)}t',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${AppFormat.tonnage(line.orderAmount)}t',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: isAdjusted
                                            ? AppColors.warning
                                            : color,
                                      ),
                                    ),
                                    if (isAdjusted)
                                      Text(
                                        'Hesap: ${AppFormat.tonnage(calculated)}t',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 4),
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
                '${AppFormat.tonnage(draft.finalOrderTonnage)}t',
                style: AppTypography.kpiValue.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step5Summary extends StatelessWidget {
  const _Step5Summary({required this.draft});

  final NewOrderDraft draft;

  @override
  Widget build(BuildContext context) {
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
                '${AppFormat.tonnage(autoTotalTonnage)}t',
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                'Düzeltilmiş Toplam',
                '${AppFormat.tonnage(adjustedTotalTonnage)}t',
                highlight: hasAdjustment,
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
                    '${AppFormat.tonnage(l.orderAmount)}t',
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
                  '%$ratio → ${AppFormat.tonnage(tonnage)}t',
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

