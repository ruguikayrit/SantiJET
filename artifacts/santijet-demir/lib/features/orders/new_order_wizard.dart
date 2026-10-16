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
import 'package:santijet_demir/features/orders/widgets/order_card.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';

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

  void _cancelWizard() {
    ref.read(newOrderDraftProvider.notifier).reset();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(newOrderDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DemirAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni Sipariş',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
            Text(
              'Adım ${_step + 1}/${_stepTitles.length} — ${_stepTitles[_step]}',
              style: AppTypography.labelMedium.copyWith(color: const Color(0xFFB7BDC7)),
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
          if (_step == 3) ...[
            TextButton(
              onPressed: _cancelWizard,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              child: const Text('İptal'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Siparişi Oluştur'),
              ),
            ),
          ] else
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
                              'Toplam ${AppFormat.tonnage(balance.surveyTotal)} · '
                              'Sipariş ${AppFormat.tonnage(balance.orderedSoFar)} · '
                              'Kalan ${AppFormat.tonnage(balance.remaining)}',
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
                      '${AppFormat.tonnage(total)}',
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
                      '${AppFormat.tonnage(totalRemaining)}',
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
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _ManualRatioDialog(initial: currentRatio.toString()),
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
                      'Toplam ${AppFormat.tonnage(balance.surveyTotal)} · '
                      'Sipariş ${AppFormat.tonnage(balance.orderedSoFar)} · '
                      'Kalan ${AppFormat.tonnage(balance.remaining)}',
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
                        'Kalan ${AppFormat.tonnage(remainingTonnage)}',
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
                        'Sipariş: ${AppFormat.tonnage(orderTonnage)}',
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
                '${AppFormat.tonnage(totalSurvey)}',
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                'Kalan Toplam',
                '${AppFormat.tonnage(totalRemaining)}',
              ),
              Divider(height: 24, color: AppColors.border),
              _SummaryRow(
                'Toplam Sipariş',
                '${AppFormat.tonnage(draft.totalTonnage)}',
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
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _OrderAmountDialog(
        title: 'Ø${line.diameter} Sipariş Düzeltmesi',
        initial: line.orderAmount.toStringAsFixed(1),
        calculatedAmount: calculatedAmount,
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
                              '${AppFormat.tonnage(line.currentStock)}',
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
                                      '${AppFormat.tonnage(line.orderAmount)}',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: isAdjusted
                                            ? AppColors.warning
                                            : color,
                                      ),
                                    ),
                                    if (isAdjusted)
                                      Text(
                                        'Hesap: ${AppFormat.tonnage(calculated)}',
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
                '${AppFormat.tonnage(draft.finalOrderTonnage)}',
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
    final sortedLines = [...lines]..sort((a, b) => a.diameter.compareTo(b.diameter));
    final autoTotalTonnage = calculateDiameterLinesFromSurvey(
      totalTonnage: draft.totalTonnage,
      surveyPlannedByDiameter: draft.surveyPlannedByDiameter,
    ).fold(0.0, (sum, line) => sum + line.orderAmount);
    final adjustedTotalTonnage = draft.finalOrderTonnage;
    final hasAdjustment = (adjustedTotalTonnage - autoTotalTonnage).abs() > 0.05;
    final imalatEntries = draft.selectedImalats.entries.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        _OrderSummaryHero(
          totalTonnage: adjustedTotalTonnage,
          imalatCount: imalatEntries.length,
          diameterCount: sortedLines.length,
          autoTotalTonnage: autoTotalTonnage,
          hasAdjustment: hasAdjustment,
        ),
        const SizedBox(height: 14),
        _OrderSummaryPanel(
          title: 'Seçilen imalatlar',
          icon: Icons.account_tree_outlined,
          child: Column(
            children: [
              const _OrderSummaryTableHead(
                labels: ['İmalat', 'Oran', 'Tonaj'],
                flexes: [4, 2, 3],
              ),
              for (var i = 0; i < imalatEntries.length; i++)
                _OrderSummaryImalatRow(
                  name: imalatEntries[i].key,
                  ratio: draft.imalatRatios[imalatEntries[i].key] ?? 100,
                  tonnage: draft.imalatOrderTonnage(imalatEntries[i].key),
                  showDivider: i < imalatEntries.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _OrderSummaryPanel(
          title: 'Çap dağılımı',
          icon: Icons.linear_scale_rounded,
          child: Column(
            children: [
              const _OrderSummaryTableHead(
                labels: ['Çap', 'Tonaj', 'Pay'],
                flexes: [3, 3, 2],
              ),
              for (var i = 0; i < sortedLines.length; i++)
                _OrderSummaryDiameterRow(
                  line: sortedLines[i],
                  totalTonnage: adjustedTotalTonnage,
                  showDivider: i < sortedLines.length - 1,
                ),
            ],
          ),
        ),
        if (sortedLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final line in sortedLines)
                OrderDiameterKpiChip(
                  diameter: line.diameter,
                  tons: line.orderAmount,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OrderSummaryHero extends StatelessWidget {
  const _OrderSummaryHero({
    required this.totalTonnage,
    required this.imalatCount,
    required this.diameterCount,
    required this.autoTotalTonnage,
    required this.hasAdjustment,
  });

  final double totalTonnage;
  final int imalatCount;
  final int diameterCount;
  final double autoTotalTonnage;
  final bool hasAdjustment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2744),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş özeti',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormat.tonnage(totalTonnage),
                style: AppTypography.kpiValue.copyWith(
                  fontSize: 34,
                  height: 1,
                  color: AppColors.electricBlue,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  't',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OrderSummaryMetaChip(
                icon: Icons.account_tree_outlined,
                label: '$imalatCount imalat',
              ),
              _OrderSummaryMetaChip(
                icon: Icons.straighten_rounded,
                label: '$diameterCount çap',
              ),
            ],
          ),
          if (hasAdjustment) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Çap düzeltmesi uygulandı · Otomatik ${AppFormat.tonnage(autoTotalTonnage)} t',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderSummaryMetaChip extends StatelessWidget {
  const _OrderSummaryMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadii.full,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryPanel extends StatelessWidget {
  const _OrderSummaryPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.electricBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          child,
        ],
      ),
    );
  }
}

class _OrderSummaryTableHead extends StatelessWidget {
  const _OrderSummaryTableHead({
    required this.labels,
    required this.flexes,
  });

  final List<String> labels;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHighlight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: flexes[i],
              child: Text(
                labels[i].toUpperCase(),
                textAlign: i == 0 ? TextAlign.start : TextAlign.end,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderSummaryImalatRow extends StatelessWidget {
  const _OrderSummaryImalatRow({
    required this.name,
    required this.ratio,
    required this.tonnage,
    required this.showDivider,
  });

  final String name;
  final int ratio;
  final double tonnage;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.1),
                      borderRadius: AppRadii.full,
                    ),
                    child: Text(
                      '%$ratio',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppFormat.tonnage(tonnage),
                  textAlign: TextAlign.end,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 1),
      ],
    );
  }
}

class _OrderSummaryDiameterRow extends StatelessWidget {
  const _OrderSummaryDiameterRow({
    required this.line,
    required this.totalTonnage,
    required this.showDivider,
  });

  final DiameterOrderLine line;
  final double totalTonnage;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.diameterColor(line.diameter);
    final share = totalTonnage > 0 ? line.orderAmount / totalTonnage * 100 : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: AppRadii.xs,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ø${line.diameter}',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      AppFormat.tonnage(line.orderAmount),
                      textAlign: TextAlign.end,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '%${share.round()}',
                      textAlign: TextAlign.end,
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: AppRadii.full,
                child: LinearProgressIndicator(
                  value: (share / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 1),
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

class _ManualRatioDialog extends StatefulWidget {
  const _ManualRatioDialog({required this.initial});

  final String initial;

  @override
  State<_ManualRatioDialog> createState() => _ManualRatioDialogState();
}

class _ManualRatioDialogState extends State<_ManualRatioDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 || value > 100) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('1 ile 100 arasında bir oran girin')),
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text('Manuel Oran', style: AppTypography.titleLarge),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Sipariş oranı (%)',
          hintText: '1 – 100',
          suffixText: '%',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        FilledButton(onPressed: _submit, child: const Text('Uygula')),
      ],
    );
  }
}

class _OrderAmountDialog extends StatefulWidget {
  const _OrderAmountDialog({
    required this.title,
    required this.initial,
    required this.calculatedAmount,
  });

  final String title;
  final String initial;
  final double calculatedAmount;

  @override
  State<_OrderAmountDialog> createState() => _OrderAmountDialogState();
}

class _OrderAmountDialogState extends State<_OrderAmountDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final normalized = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Geçerli bir tonaj girin')),
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text(widget.title, style: AppTypography.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hesaplanan: ${AppFormat.tonnage(widget.calculatedAmount)}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Sipariş miktarı (ton)',
              hintText: 'Örn: 286',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        FilledButton(onPressed: _submit, child: const Text('Kaydet')),
      ],
    );
  }
}

