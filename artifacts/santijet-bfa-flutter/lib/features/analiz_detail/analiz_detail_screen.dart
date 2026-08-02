import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/cost_summary_card.dart';
import '../../core/widgets/discipline_badge.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/kalem_row.dart';
import '../../core/widgets/metraj_input.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/user_analiz_provider.dart';
import '../../data/services/analiz_excel_export_service.dart';
import '../../data/services/analiz_pdf_export_service.dart';
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Analiz detay sayfası — uygulamanın en kritik ekranı.
///
/// Poz bilgisi, metraj + anlık maliyet, kalem tablosu, poz tarifi/şartları,
/// favori. PDF/Excel (Faz 10–11) ve kopyala/düzenle (Faz 9) butonları hazırdır.
class AnalizDetailScreen extends ConsumerWidget {
  const AnalizDetailScreen({required this.analizId, super.key});

  final String analizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _scaffoldError('$e'),
          data: (catalog) {
            final analiz = catalog.byIdOrNull(analizId);
            if (analiz == null) {
              return _scaffoldError('Analiz bulunamadı (id: $analizId)');
            }
            return _Detail(analiz: analiz);
          },
        ),
      ),
    );
  }

  Widget _scaffoldError(String message) => SJEmptyState(
        title: 'Açılamadı',
        message: message,
        icon: Icons.error_outline,
      );
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.analiz});

  final PozAnaliz analiz;

  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('PDF hazırlanıyor...')),
    );
    try {
      await analizPdfExportService.share(analiz);
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF paylaşım için hazırlandı.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Excel hazırlanıyor...')),
    );
    try {
      await analizExcelExportService.share(analiz);
      messenger.showSnackBar(
        const SnackBar(content: Text('Excel paylaşım için hazırlandı.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Excel oluşturulamadı: $e')),
      );
    }
  }

  void _clone(BuildContext context, WidgetRef ref) {
    final copy = ref.read(userAnalizProvider.notifier).clone(analiz);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${copy.pozNo} kopyalandı.')),
    );
    context.pushReplacement(AppRoutes.pozDetay(copy.id));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (analiz.kaynakTip == KaynakTip.sistem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resmi analizler silinemez.')),
      );
      return;
    }
    final ok = await SJModal.confirm(
      context: context,
      title: 'Analizi Sil',
      message: '"${analiz.pozNo}" silinsin mi?',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    ref.read(userAnalizProvider.notifier).delete(analiz.id);
    if (ref.read(favoritesProvider).contains(analiz.id)) {
      ref.read(favoritesProvider.notifier).toggle(analiz.id);
    }
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analiz silindi.')),
    );
  }

  void _edit(BuildContext context) {
    if (analiz.kaynakTip == KaynakTip.sistem) {
      context.push(AppRoutes.analizDuzenle(analiz.id));
      return;
    }
    context.push(AppRoutes.analizDuzenle(analiz.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(analiz.id);
    final discipline = analiz.discipline ?? AnalizDiscipline.insaat;
    final hesap = AnalizHesap.hesapla(analiz);
    final birimFiyati =
        hesap.birimFiyati > 0 ? hesap.birimFiyati : analiz.birimFiyati;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(analiz.pozNo),
          actions: [
            FavoriteButton(
              isFavorite: isFav,
              onToggle: () =>
                  ref.read(favoritesProvider.notifier).toggle(analiz.id),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'copy':
                    _clone(context, ref);
                  case 'edit':
                    _edit(context);
                  case 'delete':
                    _delete(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'copy', child: Text('Kopyala')),
                const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                if (analiz.kaynakTip != KaynakTip.sistem)
                  const PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              _headerCard(discipline),
              const SizedBox(height: AppSpacing.sm),
              if (analiz.pozTarifi.trim().isNotEmpty) ...[
                _infoCard('Poz Tarifi', analiz.pozTarifi),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                'Metraj & Maliyet',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              MetrajInput(
                birimFiyati: birimFiyati,
                olcuBirimi: analiz.olcuBirimi,
              ),
              const SizedBox(height: AppSpacing.xs),
              CostSummaryCard(analiz: analiz),
              if (analiz.kalemler.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Analiz Kalemleri',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ..._kalemSections(),
              ],
              if (analiz.yapimSartlari.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _infoCard('Yapım Şartları', analiz.yapimSartlari),
              ],
              if ((analiz.notlar ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _infoCard('Notlar', analiz.notlar!),
              ],
              const SizedBox(height: AppSpacing.lg),
              _exportRow(context),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCard(AnalizDiscipline discipline) {
    return SJCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                analiz.analizAdi,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.cardTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DisciplineBadge(discipline: discipline),
                  _chip(Icons.category_outlined, analiz.kategori),
                  _chip(Icons.straighten, 'Birim: ${analiz.olcuBirimi}'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.cardTextMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.cardTextMuted,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoCard(String title, String body) {
    return SJCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.cardTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppColors.cardTextSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _kalemSections() {
    const order = [
      (AnalizKalemTip.malzeme, 'Malzeme Kalemleri'),
      (AnalizKalemTip.iscilik, 'İşçilik Kalemleri'),
      (AnalizKalemTip.ekipman, 'Ekipman Kalemleri'),
    ];

    final sections = <Widget>[];
    for (final (tip, label) in order) {
      final items = analiz.kalemler.where((k) => k.tip == tip).toList();
      if (items.isEmpty) continue;
      final toplam = items.fold<double>(0, (s, k) => s + k.tutar);
      sections.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: SJCard(
          accentColor: KalemRow.tipColor(tip),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.cardTextPrimary,
                        ),
                      ),
                      Text(
                        AppFormat.currency(toplam),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.cardTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.md),
                  for (final k in items) KalemRow(kalem: k),
                ],
              );
            },
          ),
        ),
      ));
    }
    return sections;
  }

  Widget _exportRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SJButton(
            label: 'PDF',
            icon: Icons.picture_as_pdf_outlined,
            variant: SJButtonVariant.secondary,
            onPressed: () => _exportPdf(context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SJButton(
            label: 'Excel',
            icon: Icons.table_chart_outlined,
            variant: SJButtonVariant.secondary,
            onPressed: () => _exportExcel(context),
          ),
        ),
      ],
    );
  }
}
