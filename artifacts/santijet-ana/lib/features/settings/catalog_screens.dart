import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/catalog_models.dart';

/// Ortak string-liste CRUD (meslek / meslek grubu / malzeme kategorisi).
class _StringCatalogScreen extends ConsumerStatefulWidget {
  const _StringCatalogScreen({
    required this.title,
    required this.items,
    required this.onAdd,
    required this.onDelete,
    this.onRename,
    this.addLabel = 'Yeni ekle',
  });

  final String title;
  final List<String> items;
  final void Function(String name) onAdd;
  final void Function(String name) onDelete;
  final void Function(String oldName, String newName)? onRename;
  final String addLabel;

  @override
  ConsumerState<_StringCatalogScreen> createState() =>
      _StringCatalogScreenState();
}

class _StringCatalogScreenState extends ConsumerState<_StringCatalogScreen> {
  Future<void> _promptAdd([String? existing]) async {
    final ctrl = TextEditingController(text: existing ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? widget.addLabel : 'Düzenle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ad'),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || name.isEmpty) return;
    if (existing != null && widget.onRename != null) {
      widget.onRename!(existing, name);
    } else {
      widget.onAdd(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final items = widget.items;

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _promptAdd(),
        backgroundColor: c.primary,
        child: Icon(Icons.add, color: c.primaryForeground),
      ),
      body: Column(
        children: [
          SjHeader(
            title: widget.title,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.ayarlar);
              }
            },
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Henüz kayıt yok',
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.paddingOf(context).bottom + 80,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final name = items[i];
                      return _tile(
                        c,
                        title: name,
                        onEdit: widget.onRename != null
                            ? () => _promptAdd(name)
                            : null,
                        onDelete: () => widget.onDelete(name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Widget _tile(
  ThemeColors c, {
  required String title,
  String? subtitle,
  VoidCallback? onEdit,
  required VoidCallback onDelete,
}) {
  return Material(
    color: c.card,
    borderRadius: BorderRadius.circular(12),
    child: ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: c.foreground,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                color: c.mutedForeground,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: c.mutedForeground),
            ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: c.destructive),
          ),
        ],
      ),
    ),
  );
}

class MesleklerScreen extends ConsumerWidget {
  const MesleklerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final n = ref.read(appStateProvider.notifier);
    return _StringCatalogScreen(
      title: 'Meslekler',
      items: state.professions,
      onAdd: n.addProfession,
      onRename: n.updateProfession,
      onDelete: n.deleteProfession,
      addLabel: 'Meslek ekle',
    );
  }
}

class MeslekGrubuScreen extends ConsumerWidget {
  const MeslekGrubuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final n = ref.read(appStateProvider.notifier);
    return _StringCatalogScreen(
      title: 'Meslek Grubu',
      items: state.tradeGroups,
      onAdd: n.addTradeGroup,
      onRename: n.updateTradeGroup,
      onDelete: n.deleteTradeGroup,
      addLabel: 'Grup ekle',
    );
  }
}

class MalzemeKategorisiScreen extends ConsumerWidget {
  const MalzemeKategorisiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final n = ref.read(appStateProvider.notifier);
    return _StringCatalogScreen(
      title: 'Malzeme Kategorisi',
      items: state.materialCategories,
      onAdd: n.addMaterialCategory,
      onDelete: n.deleteMaterialCategory,
      addLabel: 'Kategori ekle',
    );
  }
}

class MalzemeListesiScreen extends ConsumerStatefulWidget {
  const MalzemeListesiScreen({super.key});

  @override
  ConsumerState<MalzemeListesiScreen> createState() =>
      _MalzemeListesiScreenState();
}

class _MalzemeListesiScreenState extends ConsumerState<MalzemeListesiScreen> {
  Future<void> _add() async {
    final state = ref.read(appStateProvider);
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    var category = state.materialCategories.isNotEmpty
        ? state.materialCategories.first
        : 'Diğer';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Malzeme ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                items: state.materialCategories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setLocal(() => category = v);
                },
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(labelText: 'Birim (opsiyonel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    final unit = unitCtrl.text.trim();
    nameCtrl.dispose();
    unitCtrl.dispose();
    if (ok != true || name.isEmpty) return;
    ref.read(appStateProvider.notifier).addMaterialItem(
          ConstructionMaterial(
            category: category,
            name: name,
            defaultUnit: unit.isEmpty ? null : unit,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final items = ref.watch(appStateProvider).materialList;

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: c.primary,
        child: Icon(Icons.add, color: c.primaryForeground),
      ),
      body: Column(
        children: [
          SjHeader(
            title: 'Malzeme Listesi',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.ayarlar);
              }
            },
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Katalog boş',
                      style: TextStyle(
                        color: c.mutedForeground,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.paddingOf(context).bottom + 80,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final m = items[i];
                      return _tile(
                        c,
                        title: m.name,
                        subtitle:
                            '${m.category}${m.defaultUnit != null ? ' · ${m.defaultUnit}' : ''}',
                        onDelete: () => ref
                            .read(appStateProvider.notifier)
                            .deleteMaterialItem(m.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MalzemeBirimiScreen extends ConsumerStatefulWidget {
  const MalzemeBirimiScreen({super.key});

  @override
  ConsumerState<MalzemeBirimiScreen> createState() =>
      _MalzemeBirimiScreenState();
}

class _MalzemeBirimiScreenState extends ConsumerState<MalzemeBirimiScreen> {
  Future<void> _add() async {
    final codeCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Birim ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Kod (örn. M³)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Etiket'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final code = codeCtrl.text.trim();
    final label = labelCtrl.text.trim();
    codeCtrl.dispose();
    labelCtrl.dispose();
    if (ok != true || code.isEmpty) return;
    ref.read(appStateProvider.notifier).addMaterialUnit(
          UnitOption(code: code, label: label.isEmpty ? code : label),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final units = ref.watch(appStateProvider).materialUnits;

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: c.primary,
        child: Icon(Icons.add, color: c.primaryForeground),
      ),
      body: Column(
        children: [
          SjHeader(
            title: 'Malzeme Birimi',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.ayarlar);
              }
            },
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.paddingOf(context).bottom + 80,
              ),
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = units[i];
                return _tile(
                  c,
                  title: u.code,
                  subtitle: u.label,
                  onDelete: () => ref
                      .read(appStateProvider.notifier)
                      .deleteMaterialUnit(u.code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
