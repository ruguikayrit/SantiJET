import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';

/// Ana sayfa — Faz 6'da ŞantiJET Demir seviyesine yükseltilecektir
/// (marka alanı, güçlü arama, son görüntülenenler, favoriler, modül kartları).
/// Faz 2'de tema + yönlendirme iskeleti doğrulanır.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final links = <(String, String)>[
      ('İnşaat B.F.A.', '${AppRoutes.pozlar}?modul=insaat'),
      ('Mekanik Tesisat B.F.A.', '${AppRoutes.pozlar}?modul=mekanik'),
      ('Elektrik Tesisat B.F.A.', '${AppRoutes.pozlar}?modul=elektrik'),
      ('Keşif', AppRoutes.kesif),
      ('Karşılaştır', AppRoutes.karsilastir),
      ('Ayarlar', AppRoutes.ayarlar),
      ('Design System (Faz 3–4)', AppRoutes.tasarimSistemi),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppInfo.legalName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(AppInfo.displayName, style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Faz 4 — Reusable Components (ŞantiJET Demir tasarım dili)',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (label, route) in links)
            Card(
              child: ListTile(
                title: Text(label, style: theme.textTheme.titleMedium),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(route),
              ),
            ),
        ],
      ),
    );
  }
}
