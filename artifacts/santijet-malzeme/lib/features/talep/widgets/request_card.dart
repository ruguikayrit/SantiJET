import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/sj_status_badge.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/request_status.dart';
import '../providers/requests_list_provider.dart';

/// Demir `OrderCard` birebir — sol şerit, rozet, KPI, aksiyon.
class RequestCard extends ConsumerWidget {
  const RequestCard({super.key, required this.request});

  final MaterialRequest request;

  Future<void> _advanceStatus(BuildContext context, WidgetRef ref) async {
    if (request.status == RequestStatus.siparis) {
      context.go(AppRoutes.teslim);
      return;
    }

    final next = request.status.nextStatus;
    if (next == null) return;

    ref.read(requestsProvider.notifier).advanceStatus(request.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${request.title} → ${next.label}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          'Talebi iptal et',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${request.title} kapatılsın mı?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    ref.read(requestsProvider.notifier).cancel(request.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${request.title} iptal edildi'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = Color(request.status.colorValue);
    final dateStr = request.createdAt != null
        ? DateFormat('d MMM yyyy').format(request.createdAt!)
        : '—';
    final actionLabel = request.status.actionLabel;
    final showCancelButton = request.status.canCancel;
    final round = ref.watch(requestQuoteRoundProvider(request.id));
    final materials = request.lines
        .map((l) => l.materialName)
        .where((s) => s.isNotEmpty)
        .toList();
    final supplier = round == null || round.quotes.isEmpty
        ? 'Teklif bekleniyor'
        : round.quotes.map((q) => q.supplierName).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          request.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.cardTextPrimary,
                          ),
                        ),
                      ),
                      SJStatusBadge(
                        label: request.status.label,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    materials.isEmpty ? 'Kalem yok' : materials.join(' · '),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.cardTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${request.lines.length} kalem',
                        style: AppTypography.kpiValue.copyWith(
                          fontSize: 22,
                          color: AppColors.cardTextPrimary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          supplier,
                          textAlign: TextAlign.end,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.electricBlueLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (actionLabel.isNotEmpty || showCancelButton) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (actionLabel.isNotEmpty)
                            FilledButton(
                              onPressed: () => _advanceStatus(context, ref),
                              child: Text(actionLabel),
                            ),
                          if (showCancelButton) ...[
                            if (actionLabel.isNotEmpty)
                              const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => _cancelRequest(context, ref),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.critical,
                                side: const BorderSide(
                                  color: AppColors.critical,
                                ),
                              ),
                              child: const Text('İptal'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
