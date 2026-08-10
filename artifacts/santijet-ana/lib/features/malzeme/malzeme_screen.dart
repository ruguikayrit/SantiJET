import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_empty_state.dart';
import '../../core/widgets/sj_form_field.dart';
import '../../core/widgets/sj_primary_button.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/material.dart' as dm;
import '../../domain/models/material_movement.dart';
import '../../domain/models/material_request.dart';
import '../../domain/models/page_key.dart';
import '../common/module_helpers.dart';

enum _MalzemeTab { gelen, kullanim, giden, talep }

const _requestStatus = {
  'pending': ('Beklemede', Color(0xFFF59E0B)),
  'approved': ('Onaylandı', Color(0xFF16A34A)),
  'delivered': ('Teslim Edildi', Color(0xFF2563EB)),
  'rejected': ('Reddedildi', Color(0xFFDC2626)),
};

class MalzemeScreen extends ConsumerStatefulWidget {
  const MalzemeScreen({super.key});

  @override
  ConsumerState<MalzemeScreen> createState() => _MalzemeScreenState();
}

class _MalzemeScreenState extends ConsumerState<MalzemeScreen> {
  _MalzemeTab _tab = _MalzemeTab.gelen;
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'malzeme');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('malzeme');
    if (perm == Permission.none) {
      return const SizedBox.shrink();
    }
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return ModuleScaffold(
        title: 'Malzeme',
        body: const SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Malzeme takibi için en az bir proje gerekli.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    return ModuleScaffold(
      title: 'Malzeme',
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () => _openCreate(),
              backgroundColor: colors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottom: Column(
        children: [
          ProjectFilterBar(
            value: _projectFilter,
            onChanged: (v) => setState(() => _projectFilter = v),
          ),
          _buildTabs(colors),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildTabs(dynamic colors) {
    final items = [
      (_MalzemeTab.gelen, 'Gelen'),
      (_MalzemeTab.kullanim, 'Kullanılan'),
      (_MalzemeTab.giden, 'Giden'),
      (_MalzemeTab.talep, 'Talep'),
    ];
    return Container(
      color: colors.card,
      child: Row(
        children: items.map((e) {
          final selected = _tab == e.$1;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = e.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? colors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  e.$2,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: selected ? colors.primary : colors.mutedForeground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(AppState state) {
    switch (_tab) {
      case _MalzemeTab.gelen:
        return _gelenList(state);
      case _MalzemeTab.kullanim:
        return _movementList(state, 'kullanim');
      case _MalzemeTab.giden:
        return _movementList(state, 'giden');
      case _MalzemeTab.talep:
        return _talepList(state);
    }
  }

  List<T> _filterProject<T>(
    List<T> list,
    String Function(T) projectIdOf,
  ) {
    if (_projectFilter == null) return list;
    return list.where((e) => projectIdOf(e) == _projectFilter).toList();
  }

  Widget _gelenList(AppState state) {
    final items = _filterProject(state.materials, (m) => m.projectId);
    if (items.isEmpty) {
      return const SjEmptyState(
        title: 'Gelen malzeme yok',
        message: 'Depoya giriş kaydı ekleyin.',
        icon: Icons.download_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        return EntityCard(
          title: m.name,
          subtitle:
              '${projectNameOf(state.projects, m.projectId)} · ${m.quantity} ${m.unit} · ${m.supplier}',
          trailing: Text(
            fmtMoney(m.quantity * m.unitPrice),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: _canEdit ? () => _editMaterial(m) : null,
          onDelete: _canEdit
              ? () async {
                  if (await confirmDelete(context, 'Malzemeyi sil')) {
                    ref.read(appStateProvider.notifier).deleteMaterial(m.id);
                  }
                }
              : null,
          extra: Text(
            'Teslim: ${m.deliveryDate}${m.waybillNo != null && m.waybillNo!.isNotEmpty ? ' · İrsaliye: ${m.waybillNo}' : ''}',
            style: AppTypography.bodySmall,
          ),
        );
      },
    );
  }

  Widget _movementList(AppState state, String type) {
    final items = _filterProject(
      state.materialMovements.where((m) => m.type == type).toList(),
      (m) => m.projectId,
    );
    if (items.isEmpty) {
      return SjEmptyState(
        title: type == 'kullanim' ? 'Kullanım kaydı yok' : 'Giden kaydı yok',
        message: 'Hareket eklemek için + butonunu kullanın.',
        icon: type == 'kullanim' ? Icons.build_outlined : Icons.upload_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        return EntityCard(
          title: m.name,
          subtitle:
              '${projectNameOf(state.projects, m.projectId)} · ${m.quantity} ${m.unit} · ${m.date}',
          onTap: _canEdit ? () => _editMovement(m) : null,
          onDelete: _canEdit
              ? () async {
                  if (await confirmDelete(context, 'Hareketi sil')) {
                    ref
                        .read(appStateProvider.notifier)
                        .deleteMaterialMovement(m.id);
                  }
                }
              : null,
          extra: Text(
            '${m.person.isNotEmpty ? m.person : '—'} · ${m.location.isNotEmpty ? m.location : '—'}',
            style: AppTypography.bodySmall,
          ),
        );
      },
    );
  }

  Widget _talepList(AppState state) {
    final items =
        _filterProject(state.materialRequests, (m) => m.projectId);
    if (items.isEmpty) {
      return const SjEmptyState(
        title: 'Talep yok',
        message: 'Malzeme talebi oluşturun.',
        icon: Icons.assignment_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        final st = _requestStatus[r.status] ?? _requestStatus['pending']!;
        final approvals = r.approvals ?? const MaterialRequestApprovals();
        return EntityCard(
          title: r.name,
          subtitle:
              '${projectNameOf(state.projects, r.projectId)} · ${r.quantity} ${r.unit} · ${r.requestDate}',
          trailing: StatusPill(label: st.$1, color: st.$2),
          onTap: _canEdit ? () => _editRequest(r) : null,
          onDelete: _canEdit
              ? () async {
                  if (await confirmDelete(context, 'Talebi sil')) {
                    ref
                        .read(appStateProvider.notifier)
                        .deleteMaterialRequest(r.id);
                  }
                }
              : null,
          extra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talep eden: ${r.requestedBy.isEmpty ? '—' : r.requestedBy}',
                style: AppTypography.bodySmall,
              ),
              if (_canEdit) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _approvalChip('Şef', approvals.sef == true, () {
                      _toggleApproval(r, sef: !(approvals.sef == true));
                    }),
                    _approvalChip('Müdür', approvals.mudur == true, () {
                      _toggleApproval(r, mudur: !(approvals.mudur == true));
                    }),
                    _approvalChip('Satın Alma', approvals.satinAlma == true,
                        () {
                      _toggleApproval(
                        r,
                        satinAlma: !(approvals.satinAlma == true),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final s in [
                      'pending',
                      'approved',
                      'delivered',
                      'rejected'
                    ])
                      ActionChip(
                        label: Text(
                          _requestStatus[s]!.$1,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          ref
                              .read(appStateProvider.notifier)
                              .updateMaterialRequest(
                                r.id,
                                (x) => x.copyWith(status: s),
                              );
                        },
                        backgroundColor: r.status == s
                            ? _requestStatus[s]!.$2.withValues(alpha: 0.2)
                            : null,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _approvalChip(String label, bool on, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF16A34A).withValues(alpha: 0.25),
      checkmarkColor: const Color(0xFF16A34A),
    );
  }

  void _toggleApproval(
    MaterialRequest r, {
    bool? sef,
    bool? mudur,
    bool? satinAlma,
  }) {
    final cur = r.approvals ?? const MaterialRequestApprovals();
    final next = MaterialRequestApprovals(
      sef: sef ?? cur.sef,
      mudur: mudur ?? cur.mudur,
      satinAlma: satinAlma ?? cur.satinAlma,
    );
    var status = r.status;
    if (next.sef == true && next.mudur == true && next.satinAlma == true) {
      if (status == 'pending') status = 'approved';
    }
    ref.read(appStateProvider.notifier).updateMaterialRequest(
          r.id,
          (x) => x.copyWith(approvals: next, status: status),
        );
  }

  void _openCreate() {
    switch (_tab) {
      case _MalzemeTab.gelen:
        _editMaterial(null);
      case _MalzemeTab.kullanim:
        _editMovement(null, type: 'kullanim');
      case _MalzemeTab.giden:
        _editMovement(null, type: 'giden');
      case _MalzemeTab.talep:
        _editRequest(null);
    }
  }

  Future<void> _editMaterial(dm.Material? existing) async {
    final state = ref.read(appStateProvider);
    final projectId = existing?.projectId ??
        _projectFilter ??
        state.projects.first.id;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'adet');
    final qtyCtrl =
        TextEditingController(text: existing?.quantity.toString() ?? '');
    final supplierCtrl =
        TextEditingController(text: existing?.supplier ?? '');
    final dateCtrl =
        TextEditingController(text: existing?.deliveryDate ?? todayIso());
    final priceCtrl =
        TextEditingController(text: existing?.unitPrice.toString() ?? '');
    final waybillCtrl =
        TextEditingController(text: existing?.waybillNo ?? '');
    final invoiceCtrl =
        TextEditingController(text: existing?.invoiceNo ?? '');
    final noteCtrl =
        TextEditingController(text: existing?.description ?? '');
    var selectedProject = projectId;
    var writeToKantar = existing?.writeToKantar == true;

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'Gelen Malzeme' : 'Malzeme Düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              SjDropdownField<String>(
                label: 'Proje',
                value: selectedProject,
                items: state.projects
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => selectedProject = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Malzeme adı', controller: nameCtrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(label: 'Birim', controller: unitCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(
                      label: 'Miktar',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tedarikçi', controller: supplierCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Teslim tarihi (YYYY-AA-GG)',
                controller: dateCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Birim fiyat',
                controller: priceCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'İrsaliye no', controller: waybillCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Fatura no', controller: invoiceCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Açıklama',
                controller: noteCtrl,
                maxLines: 2,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kantara yaz'),
                value: writeToKantar,
                onChanged: (v) => setLocal(() => writeToKantar = v),
              ),
              const SizedBox(height: AppSpacing.md),
              SjPrimaryButton(
                label: 'Kaydet',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final model = dm.Material(
                    id: existing?.id ?? '',
                    projectId: selectedProject,
                    name: nameCtrl.text.trim(),
                    unit: unitCtrl.text.trim().isEmpty
                        ? 'adet'
                        : unitCtrl.text.trim(),
                    quantity: parseNum(qtyCtrl.text),
                    usedQty: existing?.usedQty ?? 0,
                    supplier: supplierCtrl.text.trim(),
                    deliveryDate: dateCtrl.text.trim().isEmpty
                        ? todayIso()
                        : dateCtrl.text.trim(),
                    unitPrice: parseNum(priceCtrl.text),
                    waybillNo: waybillCtrl.text.trim(),
                    invoiceNo: invoiceCtrl.text.trim(),
                    description: noteCtrl.text.trim(),
                    writeToKantar: writeToKantar,
                    kantarEnabled: writeToKantar,
                    kantarSlipId: existing?.kantarSlipId,
                  );
                  final n = ref.read(appStateProvider.notifier);
                  if (existing == null) {
                    n.addMaterial(model);
                  } else {
                    n.updateMaterial(existing.id, (_) => model);
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editMovement(MaterialMovement? existing, {String? type}) async {
    final state = ref.read(appStateProvider);
    final projectId = existing?.projectId ??
        _projectFilter ??
        state.projects.first.id;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'adet');
    final qtyCtrl =
        TextEditingController(text: existing?.quantity.toString() ?? '');
    final dateCtrl =
        TextEditingController(text: existing?.date ?? todayIso());
    final personCtrl = TextEditingController(text: existing?.person ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final reasonCtrl = TextEditingController(text: existing?.reason ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var selectedProject = projectId;
    var selectedType = existing?.type ?? type ?? 'kullanim';

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'Malzeme Hareketi' : 'Hareket Düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              SjDropdownField<String>(
                label: 'Proje',
                value: selectedProject,
                items: state.projects
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => selectedProject = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDropdownField<String>(
                label: 'Tür',
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 'kullanim', child: Text('Kullanım')),
                  DropdownMenuItem(value: 'giden', child: Text('Giden')),
                ],
                onChanged: (v) => setLocal(() => selectedType = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Malzeme adı', controller: nameCtrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(label: 'Birim', controller: unitCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(
                      label: 'Miktar',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tarih', controller: dateCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Personel', controller: personCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Lokasyon', controller: locCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Sebep', controller: reasonCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Not', controller: noteCtrl, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              SjPrimaryButton(
                label: 'Kaydet',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final model = MaterialMovement(
                    id: existing?.id ?? '',
                    projectId: selectedProject,
                    type: selectedType,
                    name: nameCtrl.text.trim(),
                    unit: unitCtrl.text.trim().isEmpty
                        ? 'adet'
                        : unitCtrl.text.trim(),
                    quantity: parseNum(qtyCtrl.text),
                    date: dateCtrl.text.trim().isEmpty
                        ? todayIso()
                        : dateCtrl.text.trim(),
                    person: personCtrl.text.trim(),
                    location: locCtrl.text.trim(),
                    reason: reasonCtrl.text.trim(),
                    note: noteCtrl.text.trim(),
                  );
                  final n = ref.read(appStateProvider.notifier);
                  if (existing == null) {
                    n.addMaterialMovement(model);
                  } else {
                    n.updateMaterialMovement(existing.id, (_) => model);
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editRequest(MaterialRequest? existing) async {
    final state = ref.read(appStateProvider);
    final projectId = existing?.projectId ??
        _projectFilter ??
        state.projects.first.id;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'adet');
    final qtyCtrl =
        TextEditingController(text: existing?.quantity.toString() ?? '');
    final dateCtrl =
        TextEditingController(text: existing?.requestDate ?? todayIso());
    final byCtrl = TextEditingController(text: existing?.requestedBy ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final locCtrl =
        TextEditingController(text: existing?.usageLocation ?? '');
    var selectedProject = projectId;
    var status = existing?.status ?? 'pending';

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'Malzeme Talebi' : 'Talep Düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              SjDropdownField<String>(
                label: 'Proje',
                value: selectedProject,
                items: state.projects
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => selectedProject = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Malzeme adı', controller: nameCtrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(label: 'Birim', controller: unitCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(
                      label: 'Miktar',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Talep tarihi', controller: dateCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Talep eden', controller: byCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Kullanım yeri', controller: locCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjDropdownField<String>(
                label: 'Durum',
                value: status,
                items: _requestStatus.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.$1),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => status = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Not', controller: noteCtrl, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              SjPrimaryButton(
                label: 'Kaydet',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final model = MaterialRequest(
                    id: existing?.id ?? '',
                    projectId: selectedProject,
                    name: nameCtrl.text.trim(),
                    unit: unitCtrl.text.trim().isEmpty
                        ? 'adet'
                        : unitCtrl.text.trim(),
                    quantity: parseNum(qtyCtrl.text),
                    requestDate: dateCtrl.text.trim().isEmpty
                        ? todayIso()
                        : dateCtrl.text.trim(),
                    requestedBy: byCtrl.text.trim(),
                    status: status,
                    note: noteCtrl.text.trim(),
                    usageLocation: locCtrl.text.trim(),
                    approvals: existing?.approvals ??
                        const MaterialRequestApprovals(),
                  );
                  final n = ref.read(appStateProvider.notifier);
                  if (existing == null) {
                    n.addMaterialRequest(model);
                  } else {
                    n.updateMaterialRequest(existing.id, (_) => model);
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
