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
import '../../core/widgets/swipe_to_delete_row.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/catalogs/material_units.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/main_discipline.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/kesif/material_need_calculator.dart';
import '../projects/widgets/project_switcher.dart';
import 'partial_order_sheet.dart';

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
    final requests = ref.watch(activeRequestsProvider);
    final balances = computeMaterialNeedBalances(
      needs: needs,
      requests: requests,
    );
    final balanceById = {for (final b in balances) b.need.id: b};

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
                      onDelete: (c) async {
                        ref
                            .read(unitConsumptionsProvider.notifier)
                            .delete(c.id);
                      },
                    )
                  : _KesifListesiPane(
                      kesif: kesif,
                      needs: needs,
                      balanceById: balanceById,
                      selected: _selectedNeeds,
                      onToggle: (id) {
                        final bal = balanceById[id];
                        if (bal != null && bal.isFullyOrdered) return;
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
                      balances: balances,
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
    var anaGrup = existing?.anaGrup ?? MainDiscipline.insaat;
    var kesifUnit = existing?.kesifUnit ?? '';
    if (kesif != null && pozNo.isNotEmpty) {
      for (final l in kesif.lines) {
        if (l.pozNo == pozNo) {
          kesifUnit = kesifUnit.isEmpty ? l.birim : kesifUnit;
          if (existing == null) anaGrup = l.anaGrup;
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
                                  anaGrup = l.anaGrup;
                                  break;
                                }
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Text(
                      'Disiplin',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<MainDiscipline>(
                      value: anaGrup,
                      items: [
                        for (final d in MainDiscipline.values)
                          DropdownMenuItem(value: d, child: Text(d.label)),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setSheet(() => anaGrup = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
      anaGrup: anaGrup,
    );
    ref.read(unitConsumptionsProvider.notifier).upsert(item);
  }

  Future<void> _addNeedsToRequest({
    required List<MaterialNeedBalance> balances,
    required KesifSnapshot kesif,
    required String projectId,
  }) async {
    final selected = balances
        .where((b) => _selectedNeeds.contains(b.need.id))
        .toList();
    if (selected.isEmpty) return;

    final orderable = selected.where((b) => !b.isFullyOrdered).toList();
    if (orderable.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seçilen malzemelerin tamamı daha önce talep edildi.'),
        ),
      );
      return;
    }

    final qtyByNeed = await showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => PartialOrderSheet(balances: orderable),
    );
    if (qtyByNeed == null || !mounted) return;

    final now = DateTime.now();
    for (final b in orderable) {
      final n = b.need;
      final qty = qtyByNeed[n.id];
      if (qty == null || qty <= 0) continue;
      final capped = qty > b.remainingQty ? b.remainingQty : qty;
      if (capped <= 0) continue;
      final pctOfRemaining = b.remainingQty > 0
          ? ((capped / b.remainingQty) * 100)
          : 100.0;
      final pctLabel = pctOfRemaining == pctOfRemaining.roundToDouble()
          ? pctOfRemaining.toInt().toString()
          : pctOfRemaining.toStringAsFixed(0);
      ref.read(requestsProvider.notifier).add(
            MaterialRequest(
              id: IdGen.make('req'),
              projectId: projectId,
              name: n.materialName,
              category: n.consumption.category.isNotEmpty
                  ? n.consumption.category
                  : n.kesifLine.altGrup,
              unit: n.materialUnit,
              quantity: capped,
              requestDate: now,
              requestedBy: 'Saha',
              status: RequestStatus.pending,
              note:
                  '${n.pozNo} · kalanın %$pctLabel\'i'
                  ' (${_fmt(capped)} / ${_fmt(b.remainingQty)} kalan'
                  ' · toplam ${_fmt(b.fullQty)}'
                  ' · önce ${_fmt(b.orderedQty)})',
              pozCode: n.pozNo,
              kesifLineId: n.kesifLine.id,
              kesifSnapshotId: kesif.id,
              unitConsumptionId: n.consumption.id,
            ),
          );
    }

    setState(() => _selectedNeeds.clear());
    if (!mounted) return;
    context.go(AppRoutes.talep);
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _BirimSarfiyatlarPane extends StatefulWidget {
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
  final Future<void> Function(UnitConsumption) onDelete;

  @override
  State<_BirimSarfiyatlarPane> createState() => _BirimSarfiyatlarPaneState();
}

class _BirimSarfiyatlarPaneState extends State<_BirimSarfiyatlarPane> {
  /// Kapalı disiplinler; listede yoksa açık.
  final Set<MainDiscipline> _collapsed = {};

  MainDiscipline _disciplineOf(UnitConsumption c) {
    if (widget.kesif != null && c.pozNo.isNotEmpty) {
      for (final l in widget.kesif!.lines) {
        if (l.pozNo == c.pozNo) return l.anaGrup;
      }
    }
    return c.anaGrup;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.consumptions.isEmpty) {
      return SJEmptyState(
        title: 'Birim sarfiyat yok',
        message:
            'Poz başına malzeme sarfiyatını tanımlayın. '
            'Keşif metrajı ile çarpılarak malzeme miktarı hesaplanır.',
        icon: Icons.science_outlined,
        actionLabel: 'Sarfiyat Ekle',
        onAction: widget.onAdd,
      );
    }

    String pozLabel(String poz) {
      if (widget.kesif == null) return poz;
      for (final l in widget.kesif!.lines) {
        if (l.pozNo == poz) return '${l.pozNo} · ${l.tanim}';
      }
      return poz;
    }

    final grouped = <MainDiscipline, List<UnitConsumption>>{};
    for (final c in widget.consumptions) {
      grouped.putIfAbsent(_disciplineOf(c), () => []).add(c);
    }
    final order =
        MainDiscipline.values.where((d) => grouped.containsKey(d)).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        SJFab.scrollClearanceOf(context),
      ),
      children: [
        for (final discipline in order) ...[
          _DisciplineHeader(
            label: discipline.label,
            count: grouped[discipline]!.length,
            expanded: !_collapsed.contains(discipline),
            onToggle: () {
              setState(() {
                if (_collapsed.contains(discipline)) {
                  _collapsed.remove(discipline);
                } else {
                  _collapsed.add(discipline);
                }
              });
            },
          ),
          if (!_collapsed.contains(discipline)) ...[
            const SizedBox(height: AppSpacing.xs),
            for (final c in grouped[discipline]!)
              SwipeToDeleteRow(
                itemKey: ValueKey('ucn-${c.id}'),
                bottomMargin: 4,
                title: 'Sarfiyatı sil',
                message: '"${c.materialName}" birim sarfiyatı silinsin mi?',
                onDelete: () => widget.onDelete(c),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: SJCard(
                    onTap: () => widget.onEdit(c),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.materialName,
                          style: AppTypography.cardTitleMedium,
                        ),
                        const SizedBox(height: 2),
                        if (c.pozNo.isNotEmpty)
                          Text(
                            pozLabel(c.pozNo),
                            style: AppTypography.cardBodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmt(c.rate)} ${c.materialUnit}'
                          '${c.kesifUnit.isEmpty ? '' : ' / 1 ${c.kesifUnit}'}',
                          style: AppTypography.cardLabelLarge.copyWith(
                            color: AppColors.statusInkOnCard(
                              AppColors.electricBlueLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _DisciplineHeader extends StatelessWidget {
  const _DisciplineHeader({
    required this.label,
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final String label;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ),
              Text(
                '$count',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.electricBlueLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KesifListesiPane extends StatelessWidget {
  const _KesifListesiPane({
    required this.kesif,
    required this.needs,
    required this.balanceById,
    required this.selected,
    required this.onToggle,
  });

  final KesifSnapshot? kesif;
  final List<MaterialNeed> needs;
  final Map<String, MaterialNeedBalance> balanceById;
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
                  balance: balanceById[need.id],
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
              style: AppTypography.cardBodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Metraj: ${_fmt(line.miktar)} ${line.birim}',
              style: AppTypography.cardLabelLarge.copyWith(
                color: AppColors.statusInkOnCard(AppColors.electricBlueLight),
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
    required this.balance,
    required this.selected,
    required this.onToggle,
  });

  final MaterialNeed need;
  final MaterialNeedBalance? balance;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final bal = balance;
    final done = bal?.isFullyOrdered ?? false;
    final remaining = bal?.remainingQty ?? need.quantity;
    final ordered = bal?.orderedQty ?? 0;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Opacity(
        opacity: done ? 0.55 : 1,
        child: SJCard(
          onTap: done ? null : onToggle,
          child: Row(
            children: [
              Checkbox(
                value: selected && !done,
                onChanged: done ? null : (_) => onToggle(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      need.materialName,
                      style: AppTypography.cardBodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toplam ${_fmt(need.quantity)} ${need.materialUnit}'
                      ' · talep ${_fmt(ordered)}'
                      ' · kalan ${_fmt(remaining)}',
                      style: AppTypography.cardBodySmall.copyWith(
                        color: done
                            ? AppColors.statusInkOnCard(
                                AppColors.electricBlueLight,
                              )
                            : AppColors.cardTextSecondary,
                      ),
                    ),
                    if (done)
                      Text(
                        'Tamamı talep edildi',
                        style: AppTypography.cardLabelSmall.copyWith(
                          color: AppColors.statusInkOnCard(
                            AppColors.electricBlueLight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
