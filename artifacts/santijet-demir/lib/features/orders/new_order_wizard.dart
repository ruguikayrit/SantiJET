import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/mock/mock_orders.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';

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

  void _submit({required bool draft}) {
    ref.read(newOrderDraftProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          draft ? 'Sipariş taslak olarak kaydedildi' : 'Sipariş onaylandı',
        ),
        backgroundColor: draft ? AppColors.warning : AppColors.success,
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
          if (_step == 4) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _submit(draft: true),
                child: const Text('Taslak Kaydet'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _submit(draft: false),
                child: const Text('Siparişi Onayla'),
              ),
            ),
          ] else
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
    final total = draft.selectedImalats.values.fold(0.0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('İmalat türlerini seçin', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Seçilen imalatların toplam tonajı sipariş hesabına dahil edilir.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 16),
        ...imalatOptions.map((option) {
          final selected = draft.selectedImalats.containsKey(option.$1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => notifier.toggleImalat(option.$1, option.$2),
                borderRadius: AppRadii.md,
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
                        child: Text(option.$1, style: AppTypography.titleMedium),
                      ),
                      Text(
                        '${option.$2.toStringAsFixed(0)}t',
                        style: AppTypography.titleMedium.copyWith(
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
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam Seçilen', style: AppTypography.titleMedium),
              Text(
                '${total.toStringAsFixed(0)}t',
                style: AppTypography.kpiValue.copyWith(
                  color: AppColors.electricBlueLight,
                ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(newOrderDraftProvider.notifier);
    const ratios = [25, 50, 75, 100];
    final baseTotal =
        draft.selectedImalats.values.fold(0.0, (s, v) => s + v);
    final calculated = baseTotal * draft.ratio / 100;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Sipariş oranı', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Keşif tonajının yüzde kaçı sipariş edilecek?',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 24),
        Row(
          children: ratios.map((r) {
            final selected = draft.ratio == r;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: r < 100 ? 8 : 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => notifier.setRatio(r),
                    borderRadius: AppRadii.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.electricBlue.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: AppRadii.md,
                        border: Border.all(
                          color:
                              selected ? AppColors.electricBlue : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '%$r',
                          style: AppTypography.headlineMedium.copyWith(
                            color: selected
                                ? AppColors.electricBlueLight
                                : AppColors.textSecondary,
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
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _SummaryRow('Keşif Toplamı', '${baseTotal.toStringAsFixed(0)}t'),
              const SizedBox(height: 8),
              _SummaryRow('Oran', '%${draft.ratio}'),
              const Divider(height: 24, color: AppColors.border),
              _SummaryRow(
                'Sipariş Tonajı',
                '${calculated.toStringAsFixed(1)}t',
                highlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step3DiameterTable extends StatelessWidget {
  const _Step3DiameterTable({required this.draft});

  final NewOrderDraft draft;

  @override
  Widget build(BuildContext context) {
    final lines = calculateDiameterLines(draft.totalTonnage);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Çap bazlı hesap', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Otomatik dağılım — mevcut stok ve sipariş miktarları',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 16),
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
                return Container(
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
                        child: Text(
                          '${line.orderAmount.toStringAsFixed(1)}t',
                          style: AppTypography.titleMedium.copyWith(color: color),
                        ),
                      ),
                    ],
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
                '${draft.totalTonnage.toStringAsFixed(1)}t',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(newOrderDraftProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Tedarikçi seçin', style: AppTypography.headlineMedium),
        const SizedBox(height: 16),
        ...supplierOptions.map((supplier) {
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
                        'Tahmini: ${AppFormat.currency(supplier.pricePerTon * draft.totalTonnage)}',
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
    );
  }
}

class _Step5Summary extends StatelessWidget {
  const _Step5Summary({required this.draft});

  final NewOrderDraft draft;

  @override
  Widget build(BuildContext context) {
    final supplier = draft.selectedSupplier!;
    final totalCost = supplier.pricePerTon * draft.totalTonnage;
    final lines = calculateDiameterLines(draft.totalTonnage);

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
              _ImalatSummarySection(
                imalats: draft.selectedImalats.keys.toList(),
              ),
              const SizedBox(height: 12),
              _SummaryRow('Oran', '%${draft.ratio}'),
              const SizedBox(height: 8),
              _SummaryRow('Toplam Tonaj', '${draft.totalTonnage.toStringAsFixed(1)}t'),
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
  const _ImalatSummarySection({required this.imalats});

  final List<String> imalats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İmalatlar', style: AppTypography.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: imalats.map((name) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                name,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
            );
          }).toList(),
        ),
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
