import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/features/prediction/providers/prediction_provider.dart';
import 'package:santijet_demir/features/prediction/widgets/prediction_dashboard_card.dart';

class PredictionScreen extends ConsumerStatefulWidget {
  const PredictionScreen({super.key});

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends ConsumerState<PredictionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      persistPredictionSnapshot(ref);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(predictionSnapshotProvider);
    final history = ref.watch(predictionHistoryProvider);
    final dateFmt = DateFormat('d MMM yyyy', 'tr_TR');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Demir Tahmin Motoru'),
        actions: [
          IconButton(
            tooltip: 'Eşikler',
            icon: const Icon(Icons.tune),
            onPressed: () => _openConfig(context, ref),
          ),
        ],
      ),
      body: snapshot == null
          ? const Center(child: Text('Proje seçilmedi'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _RiskBanner(snapshot: snapshot),
                const SizedBox(height: 12),
                if (!snapshot.canPredict) ...[
                  Text('Eksik veriler', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  for (final gap in snapshot.dataGaps)
                    _GapTile(gap: gap),
                ] else ...[
                  _SummaryBlock(snapshot: snapshot, dateFmt: dateFmt),
                  const SizedBox(height: 16),
                  Text('Çap bazlı tahmin', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  const AppTableHeaderRow(
                    cells: [
                      AppTableHeaderCell('ÇAP', flex: 2),
                      AppTableHeaderCell('STOK', flex: 2),
                      AppTableHeaderCell('t/gün', flex: 2),
                      AppTableHeaderCell('GÜN', flex: 2),
                      AppTableHeaderCell('RİSK', flex: 2),
                    ],
                  ),
                  for (final d in snapshot.diameters)
                    _DiameterRow(prediction: d),
                  const SizedBox(height: 16),
                  if (snapshot.warnings.isNotEmpty) ...[
                    Text('Uyarılar', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    for (final w in snapshot.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• ${w.message}',
                          style: AppTypography.bodySmall.copyWith(
                            color: predictionRiskColor(w.severity),
                          ),
                        ),
                      ),
                  ],
                  if (snapshot.narratives.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Yorum', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    for (final line in snapshot.narratives)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(line, style: AppTypography.bodyMedium),
                      ),
                  ],
                ],
                const SizedBox(height: 20),
                Text('Veri kaynakları', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('İş Programı'),
                      onPressed: () => context.push(AppRoutes.workSchedule),
                    ),
                    ActionChip(
                      label: const Text('Puantaj'),
                      onPressed: () => context.push(AppRoutes.workforce),
                    ),
                    ActionChip(
                      label: const Text('Saha Sayımı'),
                      onPressed: () => context.push(AppRoutes.newCount),
                    ),
                    ActionChip(
                      label: const Text('Keşif'),
                      onPressed: () => context.push(AppRoutes.survey),
                    ),
                    ActionChip(
                      label: const Text('Siparişler'),
                      onPressed: () => context.push(AppRoutes.orders),
                    ),
                  ],
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Tahmin geçmişi', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  for (final entry in history.take(10))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dateFmt.format(entry.snapshot.createdAt)),
                      subtitle: Text(
                        entry.snapshot.canPredict
                            ? '${predictionRiskLabel(entry.snapshot.overallRisk)} · '
                                '${AppFormat.tonnage(entry.snapshot.actualDailyConsumption ?? 0)} t/gün'
                            : 'Eksik veri',
                      ),
                    ),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _openConfig(BuildContext context, WidgetRef ref) async {
    final config = ref.read(predictionConfigProvider);
    final critical = TextEditingController(
      text: config.criticalDays.toStringAsFixed(0),
    );
    final purchase = TextEditingController(
      text: config.purchaseSoonDays.toStringAsFixed(0),
    );
    final safety = TextEditingController(
      text: config.safetyStockDays.toStringAsFixed(0),
    );
    final deviation = TextEditingController(
      text: config.deviationWarningPercent.toStringAsFixed(0),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tahmin eşikleri', style: AppTypography.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: critical,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Kritik kalan gün (kırmızı)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: purchase,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Sipariş yakında gün (turuncu)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: safety,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Güvenlik stoğu (gün)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: deviation,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Plan sapma uyarı eşiği (%)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await ref.read(predictionConfigProvider.notifier).update(
                        config.copyWith(
                          criticalDays:
                              double.tryParse(critical.text) ?? config.criticalDays,
                          purchaseSoonDays: double.tryParse(purchase.text) ??
                              config.purchaseSoonDays,
                          safetyStockDays:
                              double.tryParse(safety.text) ?? config.safetyStockDays,
                          deviationWarningPercent:
                              double.tryParse(deviation.text) ??
                                  config.deviationWarningPercent,
                        ),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showAppSnackBar(
                      const SnackBar(content: Text('Eşikler kaydedildi')),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RiskBanner extends StatelessWidget {
  const _RiskBanner({required this.snapshot});

  final PredictionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final risk = snapshot.canPredict
        ? snapshot.overallRisk
        : PredictionRiskLevel.unknown;
    final color = predictionRiskColor(risk);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.md,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        predictionRiskLabel(risk),
        style: AppTypography.titleLarge.copyWith(color: color),
      ),
    );
  }
}

class _GapTile extends StatelessWidget {
  const _GapTile({required this.gap});

  final PredictionDataGap gap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(gap.message, style: AppTypography.bodyMedium),
      trailing: TextButton(
        onPressed: () => context.push(gap.route),
        child: Text(gap.actionLabel),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.snapshot, required this.dateFmt});

  final PredictionSnapshot snapshot;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _kv(
            'Günlük tüketim',
            snapshot.actualDailyConsumption != null
                ? '${AppFormat.tonnage(snapshot.actualDailyConsumption!)} t/gün'
                : '—',
          ),
          _kv(
            'Planlı tüketim',
            snapshot.plannedDailyConsumption != null
                ? '${AppFormat.tonnage(snapshot.plannedDailyConsumption!)} t/gün'
                : '—',
          ),
          _kv(
            'Tükenme tarihi',
            snapshot.predictedDepletionDate != null
                ? dateFmt.format(snapshot.predictedDepletionDate!)
                : '—',
          ),
          _kv(
            'Gerekli sipariş',
            snapshot.purchase != null
                ? '${AppFormat.tonnage(snapshot.purchase!.totalRequired)} t'
                : '—',
          ),
          if (snapshot.purchase?.requiredPurchaseDate != null)
            _kv(
              'Sipariş tarihi',
              dateFmt.format(snapshot.purchase!.requiredPurchaseDate!),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: AppTypography.bodySmall)),
          Text(v, style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}

class _DiameterRow extends StatelessWidget {
  const _DiameterRow({required this.prediction});

  final DiameterPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final rate = prediction.actualDailyConsumption > 0
        ? prediction.actualDailyConsumption
        : prediction.plannedDailyConsumption;
    final color = predictionRiskColor(prediction.risk);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Ø${prediction.diameter}',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.diameterColor(prediction.diameter),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppFormat.tonnage(prediction.currentStock),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppFormat.tonnage(rate),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              prediction.daysRemaining?.toStringAsFixed(1) ?? '—',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              predictionRiskLabel(prediction.risk),
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
