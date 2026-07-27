import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/id_gen.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../domain/entities/person.dart';

/// Personel listesi ve ekleme / düzenleme.
class PersonnelScreen extends ConsumerWidget {
  const PersonnelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(personnelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.ayarlar),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ekle'),
      ),
      body: people.isEmpty
          ? SJEmptyState(
              title: 'Henüz personel yok',
              message: 'Puantaj girebilmek için personel ekleyin.',
              icon: Icons.groups_outlined,
              actionLabel: 'Personel Ekle',
              onAction: () => _openEditor(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                88,
              ),
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final p = people[index];
                final meta = [
                  if (p.profession.isNotEmpty) p.profession,
                  if (p.company.isNotEmpty) p.company,
                  if (p.team.isNotEmpty) p.team,
                ].join(' · ');
                return SJCard(
                  onTap: () => _openEditor(context, ref, existing: p),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: theme.textTheme.titleMedium),
                            if (meta.isNotEmpty)
                              Text(meta, style: theme.textTheme.bodySmall),
                            if (p.phone.isNotEmpty)
                              Text(p.phone, style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      if (!p.active)
                        Text(
                          'Pasif',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Personeli sil'),
                              content: Text('${p.name} silinsin mi?'),
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
                          if (ok == true) {
                            ref.read(personnelProvider.notifier).delete(p.id);
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
    Person? existing,
  }) async {
    final result = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _PersonEditorSheet(existing: existing),
    );
    if (result == null) return;
    final notifier = ref.read(personnelProvider.notifier);
    if (existing == null) {
      notifier.add(result);
    } else {
      notifier.update(result);
    }
  }
}

class _PersonEditorSheet extends ConsumerStatefulWidget {
  const _PersonEditorSheet({this.existing});

  final Person? existing;

  @override
  ConsumerState<_PersonEditorSheet> createState() => _PersonEditorSheetState();
}

class _PersonEditorSheetState extends ConsumerState<_PersonEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _company;
  late final TextEditingController _address;
  String _profession = '';
  String _team = '';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _company = TextEditingController(text: e?.company ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _profession = e?.profession ?? '';
    _team = e?.team ?? '';
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final professions = ref.watch(professionsProvider);
    final teams = ref.watch(teamsProvider);
    // Mevcut değer listede yoksa yine de gösterilebilsin.
    final professionItems = [
      ...professions,
      if (_profession.isNotEmpty && !professions.contains(_profession))
        _profession,
    ];
    final teamItems = [
      ...teams,
      if (_team.isNotEmpty && !teams.contains(_team)) _team,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Yeni personel' : 'Personeli düzenle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _profession.isEmpty ? null : _profession,
              decoration: const InputDecoration(
                labelText: 'Meslek',
                helperText: 'Listeyi Ayarlar → Meslekler’den düzenleyin',
              ),
              items: [
                for (final p in professionItems)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _profession = v ?? ''),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _team.isEmpty ? null : _team,
              decoration: const InputDecoration(
                labelText: 'Ekip',
                helperText: 'Listeyi Ayarlar → Ekipler’den düzenleyin',
              ),
              items: [
                for (final t in teamItems)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _team = v ?? ''),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _company,
              decoration: const InputDecoration(labelText: 'Firma'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adres'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            FilledButton(
              onPressed: () {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  context,
                  Person(
                    id: widget.existing?.id ?? IdGen.make('per'),
                    name: name,
                    profession: _profession,
                    phone: _phone.text.trim(),
                    company: _company.text.trim(),
                    team: _team,
                    address: _address.text.trim(),
                    active: _active,
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
