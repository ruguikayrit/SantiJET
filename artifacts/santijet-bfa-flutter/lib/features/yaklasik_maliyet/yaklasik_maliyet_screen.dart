import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/services/kesif_export_service.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/enums/app_enums.dart';
import '../export/export_format_sheet.dart';
import '../kesif/widgets/discipline_section_header.dart';

/// Yaklaşık Maliyet — birim fiyatlar + tutar özeti (3 ana başlık).
class YaklasikMaliyetScreen extends ConsumerWidget {
  const YaklasikMaliyetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kesif = ref.watch(activeKesifProvider);
    final theme = Theme.of(context);

    if (kesif == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Yaklaşık Maliyet'),
          actions: [
            IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.ayarlar),
            ),
          ],
        ),
        body: SJEmptyState(
          title: 'Aktif proje yok',
          message: 'Yaklaşık maliyet için Projelerim’den bir proje seçin.',
          icon: Icons.account_balance_wallet_outlined,
          actionLabel: 'Projelerim',
          onAction: () => context.push(AppRoutes.projeler),
        ),
      );
    }

    final byUnit = kesif.toplamByOlcuBirimi.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final byDisc = kesif.satirlarByDiscipline;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Yaklaşık Maliyet'),
        actions: [
          IconButton(
            tooltip: 'Dışa Aktar',
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              final format = await ExportFormatSheet.pick(context);
              if (format == null || !context.mounted) return;
              if (format == ExportFormat.pdf) {
                await kesifExportService.sharePdf(kesif);
              } else {
                await kesifExportService.shareExcel(kesif);
              }
            },
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.ayarlar),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              kesif.ad,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SJStatCard(
              label: 'Genel Toplam',
              value: AppFormat.currency(kesif.toplam),
              unit: '',
              accentColor: AppColors.moduleKesif,
            ),
            if (byUnit.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ölçü birimi kırılımı',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SJCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in byUnit)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.cardTextSecondary,
                                ),
                              ),
                            ),
                            Text(
                              AppFormat.currency(e.value),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.cardTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Birim Fiyatlar',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Poz · tanım · birim fiyat · metraj · tutar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (kesif.satirlar.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: SJCard(
                  child: Text(
                    'Keşif listesinde poz yok. Poz ekledikçe birim fiyatlar burada listelenir.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ),
              )
            else
              for (final d in AnalizDiscipline.kesifSirasi) ...[
                if ((byDisc[d] ?? const []).isNotEmpty) ...[
                  DisciplineSectionHeader(
                    discipline: d,
                    count: byDisc[d]!.length,
                    trailing: Text(
                      AppFormat.currency(
                        byDisc[d]!.fold<double>(0, (s, r) => s + r.tutar),
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.moduleKesif,
                      ),
                    ),
                  ),
                  for (final satir in byDisc[d]!) ...[
                    _FiyatSatirCard(satir: satir),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _FiyatSatirCard extends StatelessWidget {
  const _FiyatSatirCard({required this.satir});

  final KesifSatiri satir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metraj = satir.hesaplananMetraj;
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            satir.pozNo,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.moduleKesif,
            ),
          ),
          Text(
            satir.analizAdi,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.cardTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'B.F. ${AppFormat.currency(satir.birimFiyati)} / ${satir.olcuBirimi}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.cardTextSecondary,
                  ),
                ),
              ),
              Text(
                '${AppFormat.decimal(metraj)} ${satir.olcuBirimi}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.cardTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                satir.fiyatKaynagi.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.cardTextMuted,
                ),
              ),
              const Spacer(),
              Text(
                AppFormat.currency(satir.tutar),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.cardTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
