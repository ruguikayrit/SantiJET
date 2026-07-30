import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/project.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final activeId = ref.watch(activeProjectIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeler'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(AppRoutes.ayarlar)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Proje'),
      ),
      body: projects.isEmpty
          ? SJEmptyState(title: 'Henüz proje yok', message: 'BETON R1 kayıtları proje kapsamında tutulur.', icon: Icons.apartment_outlined, actionLabel: 'Proje Ekle', onAction: () => _edit(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = projects[index];
                final selected = (activeId ?? projects.first.id) == p.id;
                return SJCard(
                  selected: selected,
                  onTap: () => ref.read(activeProjectIdProvider.notifier).set(p.id),
                  child: Row(
                    children: [
                      Icon(selected ? Icons.check_circle : Icons.apartment_outlined, color: selected ? AppColors.electricBlueLight : null),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.company.isEmpty ? 'Firma adı yok' : p.company, style: Theme.of(context).textTheme.titleMedium),
                            Text(p.name.isEmpty ? 'İşin adı yok' : p.name),
                            Text(p.code.isEmpty ? 'İşin kodu yok' : p.code, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, ref, existing: p)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Projeyi sil'),
                              content: Text('${p.name} ve bağlı kayıtlar silinsin mi?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          ref.read(pourPlansProvider.notifier).deleteForProject(p.id);
                          ref.read(pourRecordsProvider.notifier).deleteForProject(p.id);
                          ref.read(ordersProvider.notifier).deleteForProject(p.id);
                          ref.read(qualityProvider.notifier).deleteForProject(p.id);
                          ref.read(projectsProvider.notifier).delete(p.id);
                          if (activeId == p.id) {
                            final rem = ref.read(projectsProvider);
                            ref.read(activeProjectIdProvider.notifier).set(rem.isEmpty ? null : rem.first.id);
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

  Future<void> _edit(BuildContext context, WidgetRef ref, {Project? existing}) async {
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
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Yeni proje' : 'Projeyi düzenle', style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Firma adı')),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'İşin adı')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'İşin kodu')),
              const SizedBox(height: 16),
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
    if (existing == null) {
      final created = ref.read(projectsProvider.notifier).add(
            name: nameCtrl.text.trim(),
            code: codeCtrl.text.trim(),
            company: companyCtrl.text.trim(),
          );
      ref.read(activeProjectIdProvider.notifier).set(created.id);
    } else {
      ref.read(projectsProvider.notifier).update(
            existing.copyWith(name: nameCtrl.text.trim(), code: codeCtrl.text.trim(), company: companyCtrl.text.trim()),
          );
    }
  }
}
