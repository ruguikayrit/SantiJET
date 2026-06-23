import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_empty_state.dart';
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

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — sonraki fazda etkinleşecek.')),
    );
  }

  void _clone(BuildContext context, WidgetRef ref) {
    final copy = ref.read(userAnalizProvider.notifier).clone(analiz);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${copy.pozNo} kopyalandı.')),
    );
    context.pushReplacement('/pozlar/${copy.id}');
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
                if (v == 'copy') {
                  _clone(context, ref);
                  return;
                }
                _soon(context, 'Düzenle');
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'copy', child: Text('Kopyala')),
                PopupMenuItem(value: 'edit', child: Text('Düzenle')),
              ],
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              _headerCard(theme, discipline),
              const SizedBox(height: AppSpacing.sm),
              if (analiz.pozTarifi.trim().isNotEmpty) ...[
                _infoCard(theme, 'Poz Tarifi', analiz.pozTarifi),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text('Metraj & Maliyet', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              MetrajInput(
                birimFiyati: birimFiyati,
                olcuBirimi: analiz.olcuBirimi,
              ),
              const SizedBox(height: AppSpacing.xs),
              CostSummaryCard(analiz: analiz),
              if (analiz.kalemler.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Analiz Kalemleri', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                ..._kalemSections(theme),
              ],
              if (analiz.yapimSartlari.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _infoCard(theme, 'Yapım Şartları', analiz.yapimSartlari),
              ],
              if ((analiz.notlar ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _infoCard(theme, 'Notlar', analiz.notlar!),
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

  Widget _headerCard(ThemeData theme, AnalizDiscipline discipline) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(analiz.analizAdi, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DisciplineBadge(discipline: discipline),
              _chip(theme, Icons.category_outlined, analiz.kategori),
              _chip(theme, Icons.straighten, 'Birim: ${analiz.olcuBirimi}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, IconData icon, String label) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _infoCard(ThemeData theme, String title, String body) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  List<Widget> _kalemSections(ThemeData theme) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  Text(AppFormat.currency(toplam),
                      style: theme.textTheme.titleMedium),
                ],
              ),
              const Divider(height: AppSpacing.md),
              for (final k in items) KalemRow(kalem: k),
            ],
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
            onPressed: () => _soon(context, 'PDF dışa aktarma'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SJButton(
            label: 'Excel',
            icon: Icons.table_chart_outlined,
            variant: SJButtonVariant.secondary,
            onPressed: () => _soon(context, 'Excel dışa aktarma'),
          ),
        ),
      ],
    );
  }
}
