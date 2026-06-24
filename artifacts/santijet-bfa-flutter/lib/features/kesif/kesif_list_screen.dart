import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../data/providers/kesif_provider.dart';
import 'kesif_import_flow.dart';

/// Keşif listesi — React Native `kesif/index` karşılığı.
class KesifListScreen extends ConsumerWidget {
  const KesifListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(kesifProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşif'),
        actions: [
          IconButton(
            tooltip: 'Excel İçe Aktar',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => KesifImportFlow.run(
              context,
              ref,
              onImported: (id) => context.push(AppRoutes.kesifDetay(id)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        top: false,
        child: projects.isEmpty
            ? SJEmptyState(
                title: 'Henüz keşif yok',
                message: 'Yeni keşif oluşturup metraj cetveli hazırlayın.',
                icon: Icons.description_outlined,
                actionLabel: 'Yeni Keşif',
                onAction: () => _create(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: projects.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, i) {
                  final p = projects[i];
                  return SJListItem(
                    title: p.ad,
                    subtitle: '${p.satirlar.length} poz · '
                        '${DateTime.tryParse(p.guncellemeTarihi)?.toLocal().toString().split(' ').first ?? ''}',
                    leadingIcon: Icons.description_outlined,
                    accentColor: AppColors.moduleKesif,
                    trailingText: AppFormat.currency(p.toplam),
                    onTap: () => context.push(AppRoutes.kesifDetay(p.id)),
                    trailing: IconButton(
                      tooltip: 'Sil',
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error),
                      onPressed: () => _delete(context, ref, p.id, p.ad),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: 'Yeni Keşif');
    final name = await SJModal.showSheet<String>(
      context: context,
      title: 'Yeni Keşif',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SJInput(controller: controller, label: 'Proje Adı'),
          const SizedBox(height: AppSpacing.md),
          SJButton(
            label: 'Oluştur',
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final id = ref.read(kesifProvider.notifier).createProject(name);
    context.push(AppRoutes.kesifDetay(id));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String ad,
  ) async {
    final ok = await SJModal.confirm(
      context: context,
      title: 'Keşifi Sil',
      message: '"$ad" projesi silinsin mi?',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (ok) ref.read(kesifProvider.notifier).deleteProject(id);
  }
}
