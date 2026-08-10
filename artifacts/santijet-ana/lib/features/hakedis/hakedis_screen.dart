import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_empty_state.dart';
import '../../core/widgets/sj_form_field.dart';
import '../../core/widgets/sj_primary_button.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/hakedis.dart';
import '../../domain/models/page_key.dart';
import '../common/module_helpers.dart';

const _statusLabels = {
  'draft': ('Taslak', Color(0xFF64748B)),
  'submitted': ('Gönderildi', Color(0xFFF59E0B)),
  'approved': ('Onaylandı', Color(0xFF16A34A)),
  'paid': ('Ödendi', Color(0xFF2563EB)),
};

class HakedisScreen extends ConsumerStatefulWidget {
  const HakedisScreen({super.key});

  @override
  ConsumerState<HakedisScreen> createState() => _HakedisScreenState();
}

class _HakedisScreenState extends ConsumerState<HakedisScreen> {
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'hakedis');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('hakedis');
    if (perm == Permission.none) return const SizedBox.shrink();
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'Hakediş',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Hakediş için en az bir proje gerekli.',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    final items = state.hakedisler
        .where((h) => _projectFilter == null || h.projectId == _projectFilter)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ModuleScaffold(
      title: 'Hakediş',
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () => _edit(null),
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
              title: 'Hakediş yok',
              message: 'Yeni hakediş oluşturun.',
              icon: Icons.request_quote_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final h = items[i];
                final st = _statusLabels[h.status] ?? _statusLabels['draft']!;
                final total = h.items.fold<double>(
                  0,
                  (sum, it) => sum + it.quantity * it.unitPrice,
                );
                return EntityCard(
                  title: h.number.isEmpty ? 'Hakediş' : 'No: ${h.number}',
                  subtitle:
                      '${projectNameOf(state.projects, h.projectId)} · ${h.period} · ${h.date}',
                  trailing: StatusPill(label: st.$1, color: st.$2),
                  onTap: () => _edit(h),
                  onDelete: _canEdit
                      ? () async {
                          if (await confirmDelete(context, 'Hakedişi sil')) {
                            ref
                                .read(appStateProvider.notifier)
                                .deleteHakedis(h.id);
                          }
                        }
                      : null,
                  extra: Text(
                    'Yüklenici: ${h.contractor.isEmpty ? '—' : h.contractor}'
                    ' · ${h.items.length} kalem · ${fmtMoney(total)}',
                    style: AppTypography.bodySmall,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(Hakedis? existing) async {
    final state = ref.read(appStateProvider);
    var projectId =
        existing?.projectId ?? _projectFilter ?? state.projects.first.id;
    final numberCtrl = TextEditingController(text: existing?.number ?? '');
    final dateCtrl =
        TextEditingController(text: existing?.date ?? todayIso());
    final periodCtrl = TextEditingController(text: existing?.period ?? '');
    final contractorCtrl =
        TextEditingController(text: existing?.contractor ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var status = existing?.status ?? 'draft';
    var items = List<HakedisItem>.from(existing?.items ?? const []);

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'Yeni Hakediş' : 'Hakediş Düzenle',
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
                onChanged:
                    _canEdit ? (v) => setLocal(() => projectId = v!) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Numara', controller: numberCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tarih', controller: dateCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Dönem', controller: periodCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Yüklenici', controller: contractorCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjDropdownField<String>(
                label: 'Durum',
                value: status,
                items: _statusLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.$1),
                        ))
                    .toList(),
                onChanged: _canEdit ? (v) => setLocal(() => status = v!) : null,
              ),
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
              ...items.asMap().entries.map((e) {
                final it = e.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(it.description),
                  subtitle: Text(
                    '${fmtNum(it.quantity)} ${it.unit} × ${fmtMoney(it.unitPrice)}'
                    ' = ${fmtMoney(it.quantity * it.unitPrice)}',
                  ),
                  trailing: _canEdit
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setLocal(() {
                            items = [...items]..removeAt(e.key);
                          }),
                        )
                      : null,
                  onTap: _canEdit
                      ? () async {
                          final next = await _editItem(it);
                          if (next != null) {
                            setLocal(() {
                              items = [...items];
                              items[e.key] = next;
                            });
                          }
                        }
                      : null,
                );
              }),
              if (_canEdit) ...[
                const SizedBox(height: AppSpacing.md),
                SjPrimaryButton(
                  label: 'Kaydet',
                  onPressed: () {
                    final model = Hakedis(
                      id: existing?.id ?? '',
                      projectId: projectId,
                      number: numberCtrl.text.trim(),
                      date: dateCtrl.text.trim().isEmpty
                          ? todayIso()
                          : dateCtrl.text.trim(),
                      period: periodCtrl.text.trim(),
                      contractor: contractorCtrl.text.trim(),
                      status: status,
                      notes: notesCtrl.text.trim(),
                      items: items,
                    );
                    final n = ref.read(appStateProvider.notifier);
                    if (existing == null) {
                      n.addHakedis(model);
                    } else {
                      n.updateHakedis(existing.id, (_) => model);
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

  Future<HakedisItem?> _editItem(HakedisItem? existing) async {
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'adet');
    final qtyCtrl =
        TextEditingController(text: existing?.quantity.toString() ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.unitPrice.toString() ?? '');

    return showDialog<HakedisItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Kalem Ekle' : 'Kalem Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SjFormField(label: 'Açıklama', controller: descCtrl),
              const SizedBox(height: 8),
              SjFormField(label: 'Birim', controller: unitCtrl),
              const SizedBox(height: 8),
              SjFormField(
                label: 'Miktar',
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SjFormField(
                label: 'Birim fiyat',
                controller: priceCtrl,
                keyboardType: TextInputType.number,
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
                HakedisItem(
                  id: existing?.id ?? newEntityId(),
                  description: descCtrl.text.trim(),
                  unit: unitCtrl.text.trim().isEmpty
                      ? 'adet'
                      : unitCtrl.text.trim(),
                  quantity: parseNum(qtyCtrl.text),
                  unitPrice: parseNum(priceCtrl.text),
                ),
              );
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
