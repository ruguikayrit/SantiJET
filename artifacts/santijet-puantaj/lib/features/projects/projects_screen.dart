import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../domain/entities/project.dart';

/// Proje listesi, aktif proje seçimi, ekleme / silme.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final activeId = ref.watch(activeProjectIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.ayarlar),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Proje'),
      ),
      body: projects.isEmpty
          ? SJEmptyState(
              title: 'Henüz proje yok',
              message: 'Puantaj kayıtları proje kapsamında tutulur.',
              icon: Icons.apartment_outlined,
              actionLabel: 'Proje Ekle',
              onAction: () => _openEditor(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                88,
              ),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final p = projects[index];
                final selected = (activeId ?? projects.first.id) == p.id;
                return SJCard(
                  selected: selected,
                  onTap: () {
                    ref.read(activeProjectIdProvider.notifier).set(p.id);
                  },
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check_circle : Icons.apartment_outlined,
                        color: selected
                            ? AppColors.electricBlue
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: theme.textTheme.titleMedium),
                            if (p.code.isNotEmpty || p.company.isNotEmpty)
                              Text(
                                [
                                  if (p.code.isNotEmpty) p.code,
                                  if (p.company.isNotEmpty) p.company,
                                ].join(' · '),
                                style: theme.textTheme.bodySmall,
                              ),
                            if (selected)
                              Text(
                                'Aktif proje',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.electricBlue,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _openEditor(context, ref, existing: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Projeyi sil'),
                              content: Text(
                                '${p.name} ile bu projeye ait personel, '
                                'puantaj ve imalat kayıtları silinsin mi?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Vazgeç'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Sil'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          ref
                              .read(attendanceProvider.notifier)
                              .deleteForProject(p.id);
                          ref
                              .read(personnelProvider.notifier)
                              .deleteForProject(p.id);
                          ref
                              .read(productionProvider.notifier)
                              .deleteForProject(p.id);
                          ref.read(projectsProvider.notifier).delete(p.id);
                          if (activeId == p.id) {
                            final remaining =
                                ref.read(projectsProvider);
                            ref
                                .read(activeProjectIdProvider.notifier)
                                .set(remaining.isEmpty
                                    ? null
                                    : remaining.first.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Project? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final companyCtrl = TextEditingController(text: existing?.company ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Yeni proje' : 'Projeyi düzenle',
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Proje adı'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Proje kodu'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(labelText: 'Firma'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true) return;
    final name = nameCtrl.text.trim();
    final code = codeCtrl.text.trim();
    final company = companyCtrl.text.trim();

    if (existing == null) {
      final created = ref.read(projectsProvider.notifier).add(
            name: name,
            code: code,
            company: company,
          );
      ref.read(activeProjectIdProvider.notifier).set(created.id);
    } else {
      ref.read(projectsProvider.notifier).update(
            existing.copyWith(name: name, code: code, company: company),
          );
    }
  }
}
