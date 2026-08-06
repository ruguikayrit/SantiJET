import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/catalogs/professions.dart';
import '../../domain/catalogs/task_categories.dart';

/// Ayarlar → Meslek listesi (ekle / düzenle / sil).
class ProfessionsScreen extends ConsumerWidget {
  const ProfessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CatalogManageScreen(
      title: 'Meslekler',
      emptyMessage: 'Henüz meslek yok. Yeni meslek ekleyin.',
      itemNoun: 'meslek',
      items: ref.watch(professionsProvider),
      onAdd: (name) => ref.read(professionsProvider.notifier).add(name),
      onRename: (oldName, newName) =>
          ref.read(professionsProvider.notifier).rename(oldName, newName),
      onRemove: (name) => ref.read(professionsProvider.notifier).remove(name),
      onReset: () => ref
          .read(professionsProvider.notifier)
          .resetToDefaults(ProfessionCatalog.defaultProfessions),
    );
  }
}

/// Ayarlar → Ekip listesi (ekle / düzenle / sil).
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CatalogManageScreen(
      title: 'Ekipler',
      emptyMessage: 'Henüz ekip yok. Yeni ekip ekleyin.',
      itemNoun: 'ekip',
      items: ref.watch(teamsProvider),
      onAdd: (name) => ref.read(teamsProvider.notifier).add(name),
      onRename: (oldName, newName) =>
          ref.read(teamsProvider.notifier).rename(oldName, newName),
      onRemove: (name) => ref.read(teamsProvider.notifier).remove(name),
      onReset: () => ref
          .read(teamsProvider.notifier)
          .resetToDefaults(ProfessionCatalog.defaultTradeGroups),
    );
  }
}

/// Ayarlar / Görevler → Görev kategorileri (ekle / düzenle / sil).
class TaskCategoriesScreen extends ConsumerWidget {
  const TaskCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    return _CatalogManageScreen(
      title: 'Görev kategorileri',
      emptyMessage: 'Henüz kategori yok. Yeni kategori ekleyin.',
      itemNoun: 'kategori',
      items: ref.watch(taskCategoriesProvider),
      usageCount: (name) =>
          tasks.where((t) => t.category.trim() == name).length,
      onAdd: (name) => ref.read(taskCategoriesProvider.notifier).add(name),
      onRename: (oldName, newName) {
        final ok =
            ref.read(taskCategoriesProvider.notifier).rename(oldName, newName);
        if (ok) {
          ref.read(tasksProvider.notifier).reassignCategory(oldName, newName);
        }
        return ok;
      },
      onRemove: (name) {
        ref.read(taskCategoriesProvider.notifier).remove(name);
        ref.read(tasksProvider.notifier).clearCategory(name);
      },
      onReset: () {
        final defaults = TaskCategoryCatalog.defaults;
        final removed = ref
            .read(taskCategoriesProvider)
            .where((c) => !defaults.contains(c))
            .toList();
        ref
            .read(taskCategoriesProvider.notifier)
            .resetToDefaults(defaults);
        for (final name in removed) {
          ref.read(tasksProvider.notifier).clearCategory(name);
        }
      },
    );
  }
}

class _CatalogManageScreen extends StatelessWidget {
  const _CatalogManageScreen({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.onAdd,
    required this.onRename,
    required this.onRemove,
    required this.onReset,
    this.usageCount,
    this.itemNoun = 'öğe',
  });

  final String title;
  final String emptyMessage;
  final String itemNoun;
  final List<String> items;
  final bool Function(String name) onAdd;
  final bool Function(String oldName, String newName) onRename;
  final void Function(String name) onRemove;
  final VoidCallback onReset;
  final int Function(String name)? usageCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.yonetim);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Varsayılanlara dön',
            icon: const Icon(Icons.restore),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Varsayılan liste'),
                  content: Text(
                    '$title listesi varsayılanlara sıfırlansın mı? '
                    'Manuel ekledikleriniz silinir.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sıfırla'),
                    ),
                  ],
                ),
              );
              if (ok == true) onReset();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
      ),
      body: items.isEmpty
          ? SJEmptyState(
              title: 'Liste boş',
              message: emptyMessage,
              icon: Icons.list_alt_outlined,
              actionLabel: 'Ekle',
              onAction: () => _openEditor(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.afterHeader,
                AppSpacing.md,
                88,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, i) {
                final name = items[i];
                final used = usageCount?.call(name) ?? 0;
                return SJCard(
                  onTap: () => _openEditor(context, existing: name),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.xs,
                  ),
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (usageCount != null)
                                    Text(
                                      used == 0
                                          ? 'Görevde kullanılmıyor'
                                          : '$used görevde',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'Düzenle',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  _openEditor(context, existing: name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Sil',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('$itemNoun sil'),
                                    content: Text(
                                      used > 0
                                          ? '"$name" silinsin mi?\n'
                                              '$used görevdeki $itemNoun temizlenecek.'
                                          : '"$name" silinsin mi?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Vazgeç'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) onRemove(name);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(BuildContext context, {String? existing}) async {
    final controller = TextEditingController(text: existing ?? '');
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Yeni $itemNoun' : '$itemNoun düzenle',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: itemNoun[0].toUpperCase() + itemNoun.substring(1),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
                },
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  final v = controller.text.trim();
                  if (v.isEmpty) return;
                  Navigator.pop(ctx, v);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (saved == null || saved.isEmpty) return;

    if (existing == null) {
      final ok = onAdd(saved);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            content: Text(
              'Bu ad zaten listede var.',
              style: TextStyle(
                color: AppColors.readableOn(AppColors.warning),
              ),
            ),
          ),
        );
      }
    } else if (saved != existing) {
      final ok = onRename(existing, saved);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            content: Text(
              'Bu ad zaten listede var.',
              style: TextStyle(
                color: AppColors.readableOn(AppColors.warning),
              ),
            ),
          ),
        );
      }
    }
  }
}
