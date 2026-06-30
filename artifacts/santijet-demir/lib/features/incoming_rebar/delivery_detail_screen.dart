import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

class DeliveryDetailScreen extends ConsumerWidget {
  const DeliveryDetailScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(deliveriesProvider);
    final delivery = deliveries.cast<DeliveryItem?>().firstWhere(
          (item) => item?.id == deliveryId,
          orElse: () => null,
        );

    if (delivery == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Teslimat')),
        body: const Center(child: Text('Teslimat bulunamadı')),
      );
    }

    final statusColor = Color(delivery.status.colorValue);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(delivery.orderNo, style: AppTypography.titleLarge),
            Text(delivery.supplier, style: AppTypography.labelMedium),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              StatusBadge(label: delivery.status.label, color: statusColor),
              const Spacer(),
              Text(
                DateFormat('d MMM yyyy').format(delivery.date),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('İrsaliye: ${delivery.irsaliyeNo}', style: AppTypography.bodyMedium),
          if (delivery.plateNo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Plaka: ${delivery.plateNo}', style: AppTypography.bodyMedium),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              KpiCard(
                label: 'Toplam Teslim',
                value: delivery.tonnage.toStringAsFixed(0),
                unit: 't',
                accentColor: AppColors.success,
              ),
              KpiCard(
                label: 'Karşılama',
                value: delivery.fulfillmentPercent.toStringAsFixed(0),
                unit: '%',
                accentColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Çap Karşılaştırma', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          _ComparisonTable(lines: delivery.diameterLines),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.lines});

  final List<DeliveryDiameterLine> lines;

  @override
  Widget build(BuildContext context) {
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
                _Header('ÇAP', flex: 2),
                _Header('SİPARİŞ', flex: 3),
                _Header('TESLİM', flex: 3),
                _Header('FARK', flex: 3),
              ],
            ),
          ),
          ...lines.map((line) => _ComparisonRow(line: line)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.line});

  final DeliveryDiameterLine line;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.diameterColor(line.diameter);
    final diff = line.difference;

    String diffText;
    Color diffColor;
    IconData? icon;

    if (line.isMatch) {
      diffText = '✓';
      diffColor = AppColors.success;
    } else if (line.isExcess) {
      diffText = '+${diff.toStringAsFixed(1)}t';
      diffColor = AppColors.info;
      icon = Icons.trending_up;
    } else {
      diffText = '${diff.toStringAsFixed(1)}t';
      diffColor = diff.abs() > 5 ? AppColors.critical : AppColors.warning;
      icon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Ø${line.diameter}',
                  style: AppTypography.titleMedium.copyWith(color: color),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text('${line.ordered.toStringAsFixed(1)}t', style: AppTypography.bodyMedium),
              ),
              Expanded(
                flex: 3,
                child: Text('${line.delivered.toStringAsFixed(1)}t', style: AppTypography.titleMedium),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    if (icon != null) Icon(icon, size: 14, color: diffColor),
                    Text(diffText, style: AppTypography.labelMedium.copyWith(color: diffColor, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadii.full,
            child: LinearProgressIndicator(
              value: line.ordered > 0 ? (line.delivered / line.ordered).clamp(0, 1.2) : 0,
              minHeight: 3,
              backgroundColor: AppColors.border,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
