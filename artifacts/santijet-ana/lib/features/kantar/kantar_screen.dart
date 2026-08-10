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
import '../../domain/models/weighbridge.dart';
import '../common/module_helpers.dart';

class KantarScreen extends ConsumerStatefulWidget {
  const KantarScreen({super.key});

  @override
  ConsumerState<KantarScreen> createState() => _KantarScreenState();
}

class _KantarScreenState extends ConsumerState<KantarScreen> {
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'kantar');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('kantar');
    if (perm == Permission.none) return const SizedBox.shrink();
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'Kantar',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Kantar fişi için en az bir proje gerekli.',
          icon: Icons.scale_outlined,
        ),
      );
    }

    final items = state.weighbridges
        .where((w) => _projectFilter == null || w.projectId == _projectFilter)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ModuleScaffold(
      title: 'Kantar',
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
              title: 'Kantar fişi yok',
              message: 'Yeni tartım fişi ekleyin.',
              icon: Icons.scale_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final w = items[i];
                return EntityCard(
                  title: w.materialName.isEmpty ? 'Malzeme' : w.materialName,
                  subtitle:
                      '${projectNameOf(state.projects, w.projectId)} · ${w.date} · ${w.plate}',
                  trailing: Text(
                    '${fmtNum(w.netWeight)} ${w.unit}',
                    style: AppTypography.labelMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  onTap: _canEdit ? () => _edit(w) : null,
                  onDelete: _canEdit
                      ? () async {
                          if (await confirmDelete(context, 'Fişi sil')) {
                            ref
                                .read(appStateProvider.notifier)
                                .deleteWeighbridge(w.id);
                          }
                        }
                      : null,
                  extra: Text(
                    'Tedarikçi: ${w.supplier.isEmpty ? '—' : w.supplier}'
                    ' · Brüt ${fmtNum(w.grossWeight)} / Dara ${fmtNum(w.tareWeight)}'
                    '${w.irsaliyeNo.isNotEmpty ? ' · İrs: ${w.irsaliyeNo}' : ''}',
                    style: AppTypography.bodySmall,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(Weighbridge? existing) async {
    final state = ref.read(appStateProvider);
    var projectId =
        existing?.projectId ?? _projectFilter ?? state.projects.first.id;
    final dateCtrl =
        TextEditingController(text: existing?.date ?? todayIso());
    final nameCtrl =
        TextEditingController(text: existing?.materialName ?? '');
    final supplierCtrl =
        TextEditingController(text: existing?.supplier ?? '');
    final plateCtrl = TextEditingController(text: existing?.plate ?? '');
    final driverCtrl = TextEditingController(text: existing?.driver ?? '');
    final irsCtrl = TextEditingController(text: existing?.irsaliyeNo ?? '');
    final grossCtrl =
        TextEditingController(text: existing?.grossWeight.toString() ?? '');
    final tareCtrl =
        TextEditingController(text: existing?.tareWeight.toString() ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'kg');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final supIrsCtrl =
        TextEditingController(text: existing?.supplierIrsaliyeNo ?? '');
    final supTonCtrl = TextEditingController(
      text: existing?.supplierTonnage?.toString() ?? '',
    );
    final supGrossCtrl = TextEditingController(
      text: existing?.supplierGrossWeight?.toString() ?? '',
    );
    final supTareCtrl = TextEditingController(
      text: existing?.supplierTareWeight?.toString() ?? '',
    );

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'Kantar Fişi' : 'Fiş Düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          void recalc() => setLocal(() {});
          final gross = parseNum(grossCtrl.text);
          final tare = parseNum(tareCtrl.text);
          final net = (gross - tare).clamp(0, double.infinity);
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
                onChanged: (v) => setLocal(() => projectId = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tarih', controller: dateCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Malzeme', controller: nameCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Tedarikçi', controller: supplierCtrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(label: 'Plaka', controller: plateCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        SjFormField(label: 'Şoför', controller: driverCtrl),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'İrsaliye no', controller: irsCtrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(
                      label: 'Brüt',
                      controller: grossCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => recalc(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(
                      label: 'Dara',
                      controller: tareCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => recalc(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Net: ${fmtNum(net)}',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Birim', controller: unitCtrl),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Notlar', controller: notesCtrl, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tedarikçi tonaj bilgisi',
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Tedarikçi irsaliye no',
                controller: supIrsCtrl,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Tedarikçi tonaj',
                controller: supTonCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(
                      label: 'Ted. brüt',
                      controller: supGrossCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(
                      label: 'Ted. dara',
                      controller: supTareCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SjPrimaryButton(
                label: 'Kaydet',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final g = parseNum(grossCtrl.text);
                  final t = parseNum(tareCtrl.text);
                  final model = Weighbridge(
                    id: existing?.id ?? '',
                    projectId: projectId,
                    date: dateCtrl.text.trim().isEmpty
                        ? todayIso()
                        : dateCtrl.text.trim(),
                    materialName: nameCtrl.text.trim(),
                    supplier: supplierCtrl.text.trim(),
                    plate: plateCtrl.text.trim(),
                    driver: driverCtrl.text.trim(),
                    irsaliyeNo: irsCtrl.text.trim(),
                    grossWeight: g,
                    tareWeight: t,
                    netWeight: (g - t).clamp(0, double.infinity),
                    unit: unitCtrl.text.trim().isEmpty
                        ? 'kg'
                        : unitCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                    supplierIrsaliyeNo: supIrsCtrl.text.trim(),
                    supplierTonnage: supTonCtrl.text.trim().isEmpty
                        ? null
                        : parseNum(supTonCtrl.text),
                    supplierGrossWeight: supGrossCtrl.text.trim().isEmpty
                        ? null
                        : parseNum(supGrossCtrl.text),
                    supplierTareWeight: supTareCtrl.text.trim().isEmpty
                        ? null
                        : parseNum(supTareCtrl.text),
                    materialId: existing?.materialId,
                  );
                  final n = ref.read(appStateProvider.notifier);
                  if (existing == null) {
                    n.addWeighbridge(model);
                  } else {
                    n.updateWeighbridge(existing.id, (_) => model);
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
