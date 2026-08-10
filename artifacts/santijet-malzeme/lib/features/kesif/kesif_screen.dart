import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_fab.dart';
import '../../core/design_system/sj_filter_chips.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/id_gen.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/catalogs/material_units.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/main_discipline.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/kesif/material_need_calculator.dart';
import '../projects/widgets/project_switcher.dart';

/// Keşif Malzeme — birim sarfiyatlar × keşif metrajı → malzeme ihtiyacı.
class KesifScreen extends ConsumerStatefulWidget {
  const KesifScreen({super.key});

  @override
  ConsumerState<KesifScreen> createState() => _KesifScreenState();
}

class _KesifScreenState extends ConsumerState<KesifScreen> {
  static const _tabs = ['Birim Sarfiyatlar', 'Keşif Listesi'];
  int _tab = 0;
  final Set<String> _selectedNeeds = {};

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final kesif = ref.watch(activeKesifProvider);
    final consumptions = ref.watch(activeUnitConsumptionsProvider);

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Keşif Malzeme'),
              Expanded(
                child: SJEmptyState(
                  title: 'Proje yok',
                  message: 'Keşif yüklemek için önce proje seçin.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projeler',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final needs = kesif == null
        ? const <MaterialNeed>[]
        : computeMaterialNeeds(
            lines: kesif.lines,
            consumptions: consumptions,
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Keşif Malzeme'),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ProjectSwitcher(),
            ),
            SJFilterChips(
              labels: _tabs,
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _tab == 0
                  ? _BirimSarfiyatlarPane(
                      consumptions: consumptions,
                      kesif: kesif,
                      onAdd: () => _openAddSarfiyat(project.id, kesif),
                      onEdit: (c) => _openEditSarfiyat(c, kesif),
                      onDelete: (c) {
                        ref
                            .read(unitConsumptionsProvider.notifier)
                            .delete(c.id);
                      },
                    )
                  : _KesifListesiPane(
                      kesif: kesif,
                      needs: needs,
                      selected: _selectedNeeds,
                      onToggle: (id) {
                        setState(() {
                          if (_selectedNeeds.contains(id)) {
                            _selectedNeeds.remove(id);
                          } else {
                            _selectedNeeds.add(id);
                          }
                        });
                      },
                    ),
            ),
            if (_tab == 1 && _selectedNeeds.isNotEmpty && kesif != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SJButton(
                    label: 'Talebe ekle (${_selectedNeeds.length})',
                    expanded: true,
                    onPressed: () => _addNeedsToRequest(
                      needs: needs,
                      kesif: kesif,
                      projectId: project.id,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _tab == 0
          ? SJFab(
              label: 'Sarfiyat Ekle',
              onPressed: () => _openAddSarfiyat(project.id, kesif),
            )
          : null,
    );
  }

  Future<void> _openAddSarfiyat(String projectId, KesifSnapshot? kesif) async {
    await _openSarfiyatSheet(
      projectId: projectId,
      kesif: kesif,
      existing: null,
    );
  }

  Future<void> _openEditSarfiyat(
    UnitConsumption existing,
    KesifSnapshot? kesif,
  ) async {
    await _openSarfiyatSheet(
      projectId: existing.projectId,
      kesif: kesif,
      existing: existing,
    );
  }

  Future<void> _openSarfiyatSheet({
    required String projectId,
    required KesifSnapshot? kesif,
    required UnitConsumption? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.materialName ?? '');
    final rateCtrl = TextEditingController(
      text: existing == null
          ? ''
          : (existing.rate == existing.rate.roundToDouble()
              ? existing.rate.toInt().toString()
              : existing.rate.toString()),
    );
    final pozOptions = <String>[
      if (kesif != null) ...kesif.lines.map((l) => l.pozNo),
    ];
    var pozNo = existing?.pozNo ??
        (pozOptions.isNotEmpty ? pozOptions.first : '');
    var materialUnit =
        MaterialUnits.dropdownValue(existing?.materialUnit) ?? 'KG';
    var kesifUnit = existing?.kesifUnit ?? '';
    if (kesifUnit.isEmpty && kesif != null && pozNo.isNotEmpty) {
      for (final l in kesif.lines) {
        if (l.pozNo == pozNo) {
          kesifUnit = l.birim;
          break;
        }
      }
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.md,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null
                          ? 'Birim Sarfiyat Ekle'
                          : 'Birim Sarfiyat Düzenle',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (pozOptions.isNotEmpty) ...[
                      Text(
                        'Keşif pozu',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: pozOptions.contains(pozNo) ? pozNo : null,
                        items: [
                          for (final p in pozOptions)
                            DropdownMenuItem(value: p, child: Text(p)),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setSheet(() {
                            pozNo = v;
                            if (kesif != null) {
                              for (final l in kesif.lines) {
                                if (l.pozNo == v) {
                                  kesifUnit = l.birim;
                                  break;
                                }
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Malzeme'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: kesifUnit.isEmpty
                                  ? 'Sarfiyat'
                                  : 'Sarfiyat / 1 $kesifUnit',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: materialUnit,
                            decoration: const InputDecoration(
                              labelText: 'Malzeme birimi',
                            ),
                            isExpanded: true,
                            items: [
                              for (final code in MaterialUnits.codes)
                                DropdownMenuItem(
                                  value: code,
                                  child: Text(
                                    MaterialUnits.labelOf(code),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setSheet(() => materialUnit = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        if (double.tryParse(
                              rateCtrl.text.replaceAll(',', '.'),
                            ) ==
                            null) {
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;
    final rate = double.tryParse(rateCtrl.text.replaceAll(',', '.')) ?? 0;
    final item = UnitConsumption(
      id: existing?.id ?? IdGen.make('ucn'),
      projectId: projectId,
      materialName: nameCtrl.text.trim(),
      materialUnit: materialUnit,
      rate: rate,
      pozNo: pozNo.trim(),
      kesifUnit: kesifUnit,
      category: existing?.category ?? '',
      notes: existing?.notes ?? '',
    );
    ref.read(unitConsumptionsProvider.notifier).upsert(item);
  }

  void _addNeedsToRequest({
    required List<MaterialNeed> needs,
    required KesifSnapshot kesif,
    required String projectId,
  }) {
    final selected = needs.where((n) => _selectedNeeds.contains(n.id)).toList();
    if (selected.isEmpty) return;

    final now = DateTime.now();
    for (final n in selected) {
      ref.read(requestsProvider.notifier).add(
            MaterialRequest(
              id: IdGen.make('req'),
              projectId: projectId,
              name: n.materialName,
              category: n.consumption.category.isNotEmpty
                  ? n.consumption.category
                  : n.kesifLine.altGrup,
              unit: n.materialUnit,
              quantity: n.quantity,
              requestDate: now,
              requestedBy: 'Saha',
              status: RequestStatus.pending,
              note:
                  '${n.pozNo} · metraj ${_fmt(n.metraj)} ${n.kesifLine.birim}'
                  ' × ${_fmt(n.rate)}',
              pozCode: n.pozNo,
              kesifLineId: n.kesifLine.id,
              kesifSnapshotId: kesif.id,
            ),
          );
    }

    setState(() => _selectedNeeds.clear());
    context.go(AppRoutes.talep);
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _BirimSarfiyatlarPane extends StatelessWidget {
  const _BirimSarfiyatlarPane({
    required this.consumptions,
    required this.kesif,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UnitConsumption> consumptions;
  final KesifSnapshot? kesif;
  final VoidCallback onAdd;
  final ValueChanged<UnitConsumption> onEdit;
  final ValueChanged<UnitConsumption> onDelete;

  @override
  Widget build(BuildContext context) {
    if (consumptions.isEmpty) {
      return SJEmptyState(
        title: 'Birim sarfiyat yok',
        message:
            'Poz başına malzeme sarfiyatını tanımlayın. '
            'Keşif metrajı ile çarpılarak malzeme miktarı hesaplanır.',
        icon: Icons.science_outlined,
        actionLabel: 'Sarfiyat Ekle',
        onAction: onAdd,
      );
    }

    String pozLabel(String poz) {
      if (kesif == null) return poz;
      for (final l in kesif!.lines) {
        if (l.pozNo == poz) return '${l.pozNo} · ${l.tanim}';
      }
      return poz;
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        SJFab.scrollClearanceOf(context),
      ),
      itemCount: consumptions.length,
      itemBuilder: (context, index) {
        final c = consumptions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: SJCard(
            onTap: () => onEdit(c),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.materialName,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (c.pozNo.isNotEmpty)
                        Text(
                          pozLabel(c.pozNo),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmt(c.rate)} ${c.materialUnit}'
                        '${c.kesifUnit.isEmpty ? '' : ' / 1 ${c.kesifUnit}'}',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.electricBlueLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sil',
                  onPressed: () => onDelete(c),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _KesifListesiPane extends StatelessWidget {
  const _KesifListesiPane({
    required this.kesif,
    required this.needs,
    required this.selected,
    required this.onToggle,
  });

  final KesifSnapshot? kesif;
  final List<MaterialNeed> needs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (kesif == null || kesif!.lines.isEmpty) {
      return const SJEmptyState(
        title: 'Keşif listesi yok',
        message:
            'Demo seed veya JSON/elle import ile keşif yükleyin. '
            'Bulut senkron sonraki faz.',
        icon: Icons.account_tree_outlined,
      );
    }

    final tree = kesif!.groupedTree();
    final disciplineOrder =
        MainDiscipline.values.where((d) => tree.containsKey(d)).toList();
    final needsByLine = <String, List<MaterialNeed>>{};
    for (final n in needs) {
      needsByLine.putIfAbsent(n.kesifLine.id, () => []).add(n);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          kesif!.name,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Malzeme = keşif metrajı × birim sarfiyat',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final discipline in disciplineOrder) ...[
          Text(
            discipline.label,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.electricBlueLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in tree[discipline]!.entries) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                entry.key.isEmpty ? 'Genel' : entry.key,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            for (final line in entry.value) ...[
              _KesifMetrajCard(line: line),
              for (final need in needsByLine[line.id] ?? const <MaterialNeed>[])
                _NeedTile(
                  need: need,
                  selected: selected.contains(need.id),
                  onToggle: () => onToggle(need.id),
                ),
              if ((needsByLine[line.id] ?? const []).isEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    'Bu poz için birim sarfiyat tanımlı değil',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _KesifMetrajCard extends StatelessWidget {
  const _KesifMetrajCard({required this.line});

  final KesifLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: SJCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${line.pozNo} · ${line.tanim}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Metraj: ${_fmt(line.miktar)} ${line.birim}',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.electricBlueLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _NeedTile extends StatelessWidget {
  const _NeedTile({
    required this.need,
    required this.selected,
    required this.onToggle,
  });

  final MaterialNeed need;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: SJCard(
        onTap: onToggle,
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: (_) => onToggle()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    need.materialName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(need.metraj)} ${need.kesifLine.birim}'
                    ' × ${_fmt(need.rate)}'
                    ' = ${_fmt(need.quantity)} ${need.materialUnit}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    if ((v * 10).roundToDouble() == v * 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}
