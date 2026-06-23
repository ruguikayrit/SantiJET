import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/entities/analiz_kalemi.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// ŞantiJET Design System galerisi — bileşenleri görsel olarak doğrulamak için.
///
/// Geliştirme/QA amaçlıdır; bileşenlerin açık/koyu temada doğru görünmesini
/// kontrol etmeyi sağlar.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  static final _ornekAnaliz = PozAnaliz(
    id: 'demo',
    pozNo: '15.225.1009',
    analizAdi: '19 cm kalınlığında teçhizatsız gazbeton duvar yapılması',
    olcuBirimi: 'm²',
    kategori: 'Duvar',
    discipline: AnalizDiscipline.insaat,
    yukleniciKarOrani: 25,
    birimFiyati: 1061.58,
    kalemler: const [
      AnalizKalemi(
        id: 'k1',
        tip: AnalizKalemTip.malzeme,
        pozNo: '10.013.1001',
        tanim: 'Gazbeton duvar bloğu',
        olcuBirimi: 'm³',
        miktar: 0.19,
        birimFiyati: 2850,
        tutar: 541.5,
      ),
      AnalizKalemi(
        id: 'k2',
        tip: AnalizKalemTip.iscilik,
        pozNo: '10.100.1001',
        tanim: 'Duvarcı ustası + yardımcı işçi',
        olcuBirimi: 'sa',
        miktar: 0.8,
        birimFiyati: 360,
        tutar: 288,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _section('ModuleTile (Faz 4)'),
          ModuleTile(
            title: 'İnşaat B.F.A.',
            subtitle: 'Birim Fiyat Analizleri',
            icon: Icons.layers,
            accentColor: AppColors.moduleInsaat,
            count: 1879,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          ModuleTile(
            title: 'Elektrik Tesisat B.F.A.',
            subtitle: 'Birim Fiyat Analizleri',
            icon: Icons.bolt,
            accentColor: AppColors.moduleElektrik,
            count: 5911,
            onTap: () {},
          ),
          _section('AnalizListItem (Faz 4)'),
          AnalizListItem(
            analiz: _ornekAnaliz,
            isFavorite: true,
            onTap: () {},
            onToggleFavorite: () {},
          ),
          _section('DisciplineBadge + FavoriteButton (Faz 4)'),
          Row(
            children: [
              const DisciplineBadge(discipline: AnalizDiscipline.insaat),
              const SizedBox(width: 8),
              const DisciplineBadge(discipline: AnalizDiscipline.mekanik),
              const SizedBox(width: 8),
              const DisciplineBadge(discipline: AnalizDiscipline.elektrik),
              const Spacer(),
              FavoriteButton(isFavorite: true, onToggle: () {}),
            ],
          ),
          _section('CostSummaryCard (Faz 4)'),
          CostSummaryCard(analiz: _ornekAnaliz),
          _section('KalemRow (Faz 4)'),
          SJCard(
            child: Column(
              children: [
                for (final k in _ornekAnaliz.kalemler) KalemRow(kalem: k),
              ],
            ),
          ),
          _section('MetrajInput (Faz 4)'),
          MetrajInput(
            birimFiyati: _ornekAnaliz.birimFiyati,
            olcuBirimi: _ornekAnaliz.olcuBirimi,
            initialMiktar: 100,
          ),
          _section('SJStatCard'),
          Row(
            children: [
              Expanded(
                child: SJStatCard(
                  label: 'İnşaat',
                  value: '1.879',
                  unit: 'analiz',
                  accentColor: AppColors.moduleInsaat,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SJStatCard(
                  label: 'Elektrik',
                  value: '5.911',
                  unit: 'analiz',
                  accentColor: AppColors.moduleElektrik,
                  trend: '+12%',
                  trendUp: true,
                ),
              ),
            ],
          ),
          _section('SJListItem'),
          SJListItem(
            title: '15.225.1009',
            subtitle: '19 cm gazbeton duvar yapılması',
            leadingIcon: Icons.layers,
            accentColor: AppColors.moduleInsaat,
            trailingText: '1.061 ₺',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          SJListItem(
            title: 'A Blok İnşaat Keşfi',
            subtitle: '12 poz · 21.06.2026',
            leadingIcon: Icons.description_outlined,
            accentColor: AppColors.moduleKesif,
            onTap: () {},
          ),
          _section('SJStatusBadge'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SJStatusBadge(label: 'İnşaat', color: AppColors.moduleInsaat),
              SJStatusBadge(label: 'Mekanik', color: AppColors.moduleMekanik),
              SJStatusBadge(label: 'Elektrik', color: AppColors.moduleElektrik),
              SJStatusBadge(
                label: 'Favori',
                color: AppColors.moduleFavori,
                icon: Icons.star,
              ),
            ],
          ),
          _section('SJSearchBar'),
          SJSearchBar(hint: 'Poz no veya analiz ara...', onFilterTap: () {}),
          _section('SJFilterChips'),
          SJFilterChips(
            labels: const ['Tümü', 'Beton', 'Duvar', 'Sıva', 'Boya'],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          _section('SJInput'),
          const SJInput(
            label: 'Analiz Adı',
            hint: 'ör. Gazbeton duvar',
            prefixIcon: Icons.edit_outlined,
          ),
          _section('SJButton'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SJButton(label: 'Birincil', onPressed: () {}),
              SJButton(
                label: 'İkincil',
                variant: SJButtonVariant.secondary,
                onPressed: () {},
              ),
              SJButton(
                label: 'Hayalet',
                variant: SJButtonVariant.ghost,
                onPressed: () {},
              ),
              SJButton(
                label: 'Sil',
                icon: Icons.delete_outline,
                variant: SJButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SJButton(
            label: 'Modal Aç',
            icon: Icons.open_in_new,
            expanded: true,
            onPressed: () => SJModal.showSheet(
              context: context,
              title: 'Örnek Alt Sayfa',
              child: const Text('ŞantiJET modal içeriği.'),
            ),
          ),
          _section('SJEmptyState'),
          SizedBox(
            height: 260,
            child: SJEmptyState(
              title: 'Henüz analiz yok',
              message: 'Katalogdan poz ekleyerek başlayın.',
              icon: Icons.inbox_outlined,
              actionLabel: 'Analiz Oluştur',
              onAction: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
}
