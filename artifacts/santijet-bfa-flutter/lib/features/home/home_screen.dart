import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/module_tile.dart';

/// Ana sayfa — Faz 6'da ŞantiJET Demir seviyesine yükseltilecektir
/// (marka alanı, güçlü arama, son görüntülenenler, favoriler).
/// Faz 5'te kalıcı alt navigasyon kabuğu (shell) içinde ilk sekme olarak çalışır.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppInfo.legalName)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(AppInfo.displayName, style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Faz 5 — Navigasyon (kalıcı alt menü + geçişler)',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Modüller', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ModuleTile(
              title: 'İnşaat B.F.A.',
              subtitle: 'Birim Fiyat Analizleri',
              icon: Icons.layers,
              accentColor: AppColors.moduleInsaat,
              onTap: () => context.push('${AppRoutes.pozlar}?modul=insaat'),
            ),
            const SizedBox(height: AppSpacing.xs),
            ModuleTile(
              title: 'Mekanik Tesisat B.F.A.',
              subtitle: 'Birim Fiyat Analizleri',
              icon: Icons.plumbing,
              accentColor: AppColors.moduleMekanik,
              onTap: () => context.push('${AppRoutes.pozlar}?modul=mekanik'),
            ),
            const SizedBox(height: AppSpacing.xs),
            ModuleTile(
              title: 'Elektrik Tesisat B.F.A.',
              subtitle: 'Birim Fiyat Analizleri',
              icon: Icons.bolt,
              accentColor: AppColors.moduleElektrik,
              onTap: () => context.push('${AppRoutes.pozlar}?modul=elektrik'),
            ),
            const SizedBox(height: AppSpacing.xs),
            ModuleTile(
              title: 'Favoriler',
              subtitle: 'Kaydettiğiniz analizler',
              icon: Icons.star,
              accentColor: AppColors.moduleFavori,
              onTap: () => context.push('${AppRoutes.pozlar}?modul=favoriler'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Hızlı Erişim', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SJCard(
              onTap: () => context.push(AppRoutes.karsilastir),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: AppColors.moduleMekanik),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Analiz Karşılaştır',
                        style: theme.textTheme.titleMedium),
                  ),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SJCard(
              onTap: () => context.push(AppRoutes.tasarimSistemi),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined,
                      color: AppColors.electricBlueLight),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Design System (Faz 3–4)',
                        style: theme.textTheme.titleMedium),
                  ),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
