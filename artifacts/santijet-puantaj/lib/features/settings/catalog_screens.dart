import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../data/providers/uninsured_teams_provider.dart';
import '../../data/providers/yevmiyeli_is_provider.dart';
import '../../domain/catalogs/professions.dart';
import '../../domain/catalogs/task_categories.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/uninsured_team_entry.dart';
import '../../domain/entities/yevmiyeli_is_kaydi.dart';

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
///
/// Personel, imalat, günlük ekip veya yevmiyeli kayıtta kullanılan ekipler
/// silinemez; yalnızca adı düzenlenebilir.
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  static int countUsage({
    required String name,
    required List<Person> people,
    required List<Production> productions,
    required List<UninsuredTeamEntry> uninsured,
    required List<YevmiyeliIsKaydi> yevmiyeli,
  }) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return 0;
    var n = 0;
    for (final p in people) {
      if (p.team.trim().toLowerCase() == key) n++;
    }
    for (final p in productions) {
      if (p.teamName.trim().toLowerCase() == key) n++;
    }
    for (final e in uninsured) {
      if (e.teamName.trim().toLowerCase() == key) n++;
    }
    for (final e in yevmiyeli) {
      if (e.team.trim().toLowerCase() == key) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(personnelProvider);
    final productions = ref.watch(productionProvider);
    final uninsured = ref.watch(uninsuredTeamsProvider);
    final yevmiyeli = ref.watch(yevmiyeliIsProvider);

    int usedOf(String name) => countUsage(
          name: name,
          people: people,
          productions: productions,
          uninsured: uninsured,
          yevmiyeli: yevmiyeli,
        );

    return _CatalogManageScreen(
      title: 'Ekipler',
      emptyMessage: 'Henüz ekip yok. Yeni ekip ekleyin.',
      itemNoun: 'ekip',
      items: ref.watch(teamsProvider),
      usageCount: usedOf,
      usageLabel: (name, used) => used == 0
          ? 'Kullanılmıyor — silinebilir'
          : '$used kayıtta kullanılıyor — yalnızca ad düzenlenebilir',
      blockDeleteWhenUsed: true,
      deleteBlockedMessage: (name) =>
          '"$name" ekibi personel, imalat, günlük ekip veya '
          'yevmiyeli kayıtta kullanıldığı için silinemez. '
          'İsterseniz yalnızca adını düzenleyebilirsiniz.',
      onAdd: (name) => ref.read(teamsProvider.notifier).add(name),
      onRename: (oldName, newName) {
        final ok = ref.read(teamsProvider.notifier).rename(oldName, newName);
        if (ok) {
          ref.read(personnelProvider.notifier).reassignTeam(oldName, newName);
          ref
              .read(productionProvider.notifier)
              .reassignTeamName(oldName, newName);
          ref
              .read(uninsuredTeamsProvider.notifier)
              .reassignTeamName(oldName, newName);
          ref.read(yevmiyeliIsProvider.notifier).reassignTeam(oldName, newName);
        }
        return ok;
      },
      onRemove: (name) {
        if (usedOf(name) > 0) return;
        ref.read(teamsProvider.notifier).remove(name);
      },
      onReset: () {
        final used = <String>{
          for (final name in ref.read(teamsProvider))
            if (usedOf(name) > 0) name,
        };
        ref
            .read(teamsProvider.notifier)
            .resetToDefaults(ProfessionCatalog.defaultTradeGroups);
        for (final name in used) {
          ref.read(teamsProvider.notifier).add(name);
        }
      },
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
      usageLabel: (name, used) => used == 0
          ? 'Görevde kullanılmıyor'
          : '$used görevde',
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
    this.usageLabel,
    this.blockDeleteWhenUsed = false,
    this.deleteBlockedMessage,
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
  final String Function(String name, int used)? usageLabel;
  final bool blockDeleteWhenUsed;
  final String Function(String name)? deleteBlockedMessage;

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
                    blockDeleteWhenUsed
                        ? '$title listesi varsayılanlara sıfırlansın mı? '
                            'Kullanılan öğeler korunur; diğer manuel '
                            'eklemeler silinir.'
                        : '$title listesi varsayılanlara sıfırlansın mı? '
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
                final deleteBlocked = blockDeleteWhenUsed && used > 0;
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
                        height: usageCount != null ? 56 : 48,
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
                                      usageLabel?.call(name, used) ??
                                          (used == 0
                                              ? 'Kullanılmıyor'
                                              : '$used kayıtta'),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: deleteBlocked
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: deleteBlocked
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.28)
                                    : theme.colorScheme.error,
                              ),
                              tooltip: deleteBlocked
                                  ? 'Kullanıldığı için silinemez'
                                  : 'Sil',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => _onDeletePressed(
                                context,
                                name: name,
                                used: used,
                                deleteBlocked: deleteBlocked,
                              ),
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

  Future<void> _onDeletePressed(
    BuildContext context, {
    required String name,
    required int used,
    required bool deleteBlocked,
  }) async {
    if (deleteBlocked) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$itemNoun silinemez'),
          content: Text(
            deleteBlockedMessage?.call(name) ??
                '"$name" kullanıldığı için silinemez.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$itemNoun sil'),
        content: Text(
          used > 0 && !blockDeleteWhenUsed
              ? '"$name" silinsin mi?\n'
                  '$used görevdeki $itemNoun temizlenecek.'
              : '"$name" silinsin mi?',
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
    if (ok == true) onRemove(name);
  }

  Future<void> _openEditor(BuildContext context, {String? existing}) async {
    final controller = TextEditingController(text: existing ?? '');
    final used =
        existing == null ? 0 : (usageCount?.call(existing) ?? 0);
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
              if (existing != null &&
                  blockDeleteWhenUsed &&
                  used > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bu $itemNoun kullanılıyor. Yalnızca ad düzenlenebilir; '
                  'silinemez.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
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
