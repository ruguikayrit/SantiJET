import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// ŞantiJET Design System galerisi — bileşenleri görsel olarak doğrulamak için.
///
/// Geliştirme/QA amaçlıdır; bileşenlerin açık/koyu temada doğru görünmesini
/// kontrol etmeyi sağlar.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
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
