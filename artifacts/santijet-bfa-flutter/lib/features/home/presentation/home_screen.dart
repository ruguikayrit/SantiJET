import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/router/routes.dart';

/// Ana sayfa — Faz 6'da ŞantiJET Demir seviyesine yükseltilecektir
/// (marka alanı, güçlü arama, son görüntülenenler, favoriler, modül kartları).
/// Faz 1'de yalnızca yönlendirme iskeleti doğrulanır.
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
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppInfo.legalName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppInfo.displayName,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Faz 1 — Proje mimarisi iskeleti',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final (label, route) in links)
            Card(
              child: ListTile(
                title: Text(label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(route),
              ),
            ),
        ],
      ),
    );
  }
}
