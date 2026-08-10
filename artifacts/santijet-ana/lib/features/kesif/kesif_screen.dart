import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_empty_state.dart';
import '../../core/widgets/sj_form_field.dart';
import '../../core/widgets/sj_primary_button.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/page_key.dart';
import '../../domain/models/survey.dart';
import '../common/module_helpers.dart';

class KesifScreen extends ConsumerStatefulWidget {
  const KesifScreen({super.key});

  @override
  ConsumerState<KesifScreen> createState() => _KesifScreenState();
}

class _KesifScreenState extends ConsumerState<KesifScreen> {
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'kesif');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('kesif');
    if (perm == Permission.none) return const SizedBox.shrink();
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'Keşif',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Keşif için en az bir proje gerekli.',
          icon: Icons.architecture_outlined,
        ),
      );
    }

    final items = state.surveys
        .where((s) => _projectFilter == null || s.projectId == _projectFilter)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ModuleScaffold(
      title: 'Keşif',
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () => _editSurvey(null),
              backgroundColor: colors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottom: ProjectFilterBar(
        value: _projectFilter,
        onChanged: (v) => setState(() => _projectFilter = v),
      ),
      body: items.isEmpty
          ? const SjEmptyState(
              title: 'Keşif yok',
              message: 'Yeni keşif oluşturun.',
              icon: Icons.list_alt_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final s = items[i];
                final total = s.items.fold<double>(
                  0,
                  (sum, it) => sum + it.quantity * it.unitPrice,
                );
                return EntityCard(
                  title: s.title.isEmpty ? 'Keşif' : s.title,
                  subtitle:
                      '${projectNameOf(state.projects, s.projectId)} · ${s.date}'
                      '${s.location.isNotEmpty ? ' · ${s.location}' : ''}',
                  trailing: Text(
                    '${s.items.length} kalem',
                    style: AppTypography.labelMedium,
                  ),
                  onTap: () => _editSurvey(s),
                  onDelete: _canEdit
                      ? () async {
                          if (await confirmDelete(context, 'Keşfi sil')) {
                            ref
                                .read(appStateProvider.notifier)
                                .deleteSurvey(s.id);
                          }
                        }
                      : null,
                  extra: Text(
                    'Toplam: ${fmtMoney(total)}',
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editSurvey(Survey? existing) async {
    final state = ref.read(appStateProvider);
    var projectId =
        existing?.projectId ?? _projectFilter ?? state.projects.first.id;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final dateCtrl =
        TextEditingController(text: existing?.date ?? todayIso());
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var items = List<SurveyItem>.from(existing?.items ?? const []);

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'Yeni Keşif' : 'Keşif Düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              SjDropdownField<String>(
                label: 'Proje',
                value: projectId,
                items: state.projects
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: _canEdit
                    ? (v) => setLocal(() => projectId = v!)
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Başlık', controller: titleCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tarih', controller: dateCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Lokasyon', controller: locCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Notlar', controller: notesCtrl, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kalemler (${items.length})',
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_canEdit)
                    TextButton.icon(
                      onPressed: () async {
                        final item = await _editItem(null);
                        if (item != null) {
                          setLocal(() => items = [...items, item]);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Kalem'),
                    ),
                ],
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Henüz kalem eklenmedi.'),
                )
              else
                ...items.asMap().entries.map((e) {
                  final it = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(it.description),
                      subtitle: Text(
                        '${fmtNum(it.quantity)} ${it.unit}'
                        ' · ${fmtMoney(it.unitPrice)}'
                        '${it.pozCode != null && it.pozCode!.isNotEmpty ? ' · Poz: ${it.pozCode}' : ''}'
                        ' · ${it.itemType == 'iscilik' ? 'İşçilik' : 'Malzeme'}',
                      ),
                      trailing: _canEdit
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () async {
                                    final next = await _editItem(it);
                                    if (next != null) {
                                      setLocal(() {
                                        items = [...items];
                                        items[e.key] = next;
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => setLocal(() {
                                    items = [...items]..removeAt(e.key);
                                  }),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                }),
              if (_canEdit) ...[
                const SizedBox(height: AppSpacing.md),
                SjPrimaryButton(
                  label: 'Kaydet',
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final model = Survey(
                      id: existing?.id ?? '',
                      projectId: projectId,
                      title: titleCtrl.text.trim(),
                      date: dateCtrl.text.trim().isEmpty
                          ? todayIso()
                          : dateCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                      items: items,
                    );
                    final n = ref.read(appStateProvider.notifier);
                    if (existing == null) {
                      n.addSurvey(model);
                    } else {
                      n.updateSurvey(existing.id, (_) => model);
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<SurveyItem?> _editItem(SurveyItem? existing) async {
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'adet');
    final qtyCtrl =
        TextEditingController(text: existing?.quantity.toString() ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.unitPrice.toString() ?? '');
    final pozCtrl = TextEditingController(text: existing?.pozCode ?? '');
    var itemType = existing?.itemType ?? 'malzeme';

    return showDialog<SurveyItem>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? 'Kalem Ekle' : 'Kalem Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SjFormField(label: 'Açıklama', controller: descCtrl),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child:
                              SjFormField(label: 'Birim', controller: unitCtrl),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SjFormField(
                            label: 'Miktar',
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SjFormField(
                      label: 'Birim fiyat',
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    SjFormField(label: 'Poz kodu', controller: pozCtrl),
                    const SizedBox(height: 8),
                    SjDropdownField<String>(
                      label: 'Tür',
                      value: itemType,
                      items: const [
                        DropdownMenuItem(
                          value: 'malzeme',
                          child: Text('Malzeme'),
                        ),
                        DropdownMenuItem(
                          value: 'iscilik',
                          child: Text('İşçilik'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => itemType = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    if (descCtrl.text.trim().isEmpty) return;
                    Navigator.pop(
                      ctx,
                      SurveyItem(
                        id: existing?.id ?? newEntityId(),
                        description: descCtrl.text.trim(),
                        unit: unitCtrl.text.trim().isEmpty
                            ? 'adet'
                            : unitCtrl.text.trim(),
                        quantity: parseNum(qtyCtrl.text),
                        unitPrice: parseNum(priceCtrl.text),
                        pozCode: pozCtrl.text.trim(),
                        itemType: itemType,
                        pozCategory: existing?.pozCategory,
                        plannedQty: existing?.plannedQty,
                        completedQty: existing?.completedQty,
                        date: existing?.date,
                      ),
                    );
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
