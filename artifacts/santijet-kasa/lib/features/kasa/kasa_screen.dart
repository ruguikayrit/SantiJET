import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/hareketler_store.dart';
import '../../domain/kasa_hareket.dart';
import '../../domain/money_format.dart';
import '../hareketler/hareket_tile.dart';

/// Ana kasa — 3 özet + son hareketler + FAB.
class KasaScreen extends ConsumerWidget {
  const KasaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ozet = ref.watch(kasaOzetProvider);
    final hareketler = ref.watch(hareketlerProvider);
    final son = hareketler.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.hareketForm),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(showWordmark: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  100,
                ),
                children: [
                  Text(
                    'Güncel kasa',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _OzetKart(
                          label: 'TOPLAM GELİR',
                          value: MoneyFormat.format(ozet.toplamGelir),
                          accent: AppColors.electricBlue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _OzetKart(
                          label: 'TOPLAM GİDER',
                          value: MoneyFormat.format(ozet.toplamGider),
                          accent: AppColors.critical,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OzetKart(
                    label: 'GÜNCEL KASA',
                    value: MoneyFormat.formatSigned(ozet.guncelKasa),
                    accent: ozet.isNegatif
                        ? AppColors.critical
                        : AppColors.success,
                    large: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text(
                        'Son hareketler',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.hareketler),
                        child: const Text('Tümü'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (son.isEmpty)
                    const SJEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Henüz hareket yok',
                      message: 'İş avansı veya harcama ekleyin.',
                    )
                  else
                    ...son.map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: HareketTile(
                          hareket: h,
                          onTap: () => context.push(
                            '${AppRoutes.hareketForm}?id=${h.id}',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OzetKart extends StatelessWidget {
  const _OzetKart({
    required this.label,
    required this.value,
    required this.accent,
    this.large = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.cardLabelMedium.copyWith(
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: (large
                    ? AppTypography.displaySmall
                    : AppTypography.headlineLarge)
                .copyWith(color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String formatHareketTarih(DateTime d) =>
    DateFormat('dd.MM.yyyy').format(d);

String hareketBaslik(KasaHareket h) {
  if (h.tedarikci.trim().isNotEmpty) return h.tedarikci;
  return h.aciklama;
}
