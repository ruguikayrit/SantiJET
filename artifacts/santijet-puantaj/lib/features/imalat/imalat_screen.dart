import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/production_day_entry.dart';
import '../../domain/catalogs/imalat_units.dart';
import '../../domain/yevmiye/imalat_crew_allocator.dart';
import '../../domain/yevmiye/yevmiye_calculator.dart';

/// İmalat — iş tanımı + %100'e kadar günlük usta/düz kayıtları.
class ImalatScreen extends ConsumerWidget {
  const ImalatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final items = ref.watch(activeProductionProvider);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('İmalat')),
        body: SJEmptyState(
          title: 'Önce proje ekleyin',
          message: 'İmalat kayıtları proje kapsamında tutulur.',
          icon: Icons.apartment_outlined,
          actionLabel: 'Projelere Git',
          onAction: () => context.go(AppRoutes.projeler),
        ),
      );
    }

    final teams = {
      ...ref.watch(teamsProvider),
      ...YevmiyeCalculator.teamNames(ref.watch(activePersonnelProvider)),
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('İmalat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Text(project.name, style: theme.textTheme.labelMedium),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: teams.isEmpty
            ? () => _warnNoTeams(context)
            : () => _openJobEditor(context, ref, projectId: project.id, teams: teams),
        icon: const Icon(Icons.add),
        label: const Text('İmalat Ekle'),
      ),
      body: items.isEmpty
          ? SJEmptyState(
              title: teams.isEmpty ? 'Önce ekip tanımlayın' : 'Henüz imalat yok',
              message: teams.isEmpty
                  ? 'Ayarlar → Ekipler / Personel’de ekip tanımlayın.'
                  : 'İmalat tanımlayın; %100 tamamlanana kadar her gün '
                      'usta ve düz işçi ekleyebilirsiniz.',
              icon: teams.isEmpty
                  ? Icons.groups_outlined
                  : Icons.precision_manufacturing_outlined,
              actionLabel: teams.isEmpty ? 'Personel' : 'İmalat Ekle',
              onAction: teams.isEmpty
                  ? () => context.go(AppRoutes.personel)
                  : () => _openJobEditor(
                        context,
                        ref,
                        projectId: project.id,
                        teams: teams,
                      ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                88,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final p = items[i];
                final pct = p.progressPct;
                final color = pct >= 100
                    ? AppColors.success
                    : pct >= 50
                        ? AppColors.warning
                        : AppColors.critical;
                return SJCard(
                  onTap: () => _openDetail(context, ref, production: p),
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (p.isComplete)
                                SJStatusBadge(
                                  label: 'Tamamlandı',
                                  color: AppColors.success,
                                )
                              else
                                Text(
                                  '%${pct.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            p.teamName.isEmpty
                                ? 'Ekip seçilmedi'
                                : 'Ekip: ${p.teamName}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.electricBlueLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmt(p.completedQty)} / ${_fmt(p.plannedQty)} ${p.unit}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Toplam atama: ${_fmt(p.ustaCount)} usta · '
                            '${_fmt(p.duzIsciCount)} düz · '
                            '${p.dailyEntries.length} günlük kayıt',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (pct / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: color.withValues(alpha: 0.15),
                              color: color,
                            ),
                          ),
                          if (!p.isComplete) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _openDayEntry(
                                  context,
                                  ref,
                                  production: p,
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Günlük kayıt ekle'),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  void _warnNoTeams(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'İmalat için ekip tanımlı olmalı (Ayarlar → Ekipler / Personel).',
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Future<void> _openJobEditor(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    required List<String> teams,
    Production? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ImalatJobSheet(
        projectId: projectId,
        teams: teams,
        existing: existing,
        onDelete: existing == null
            ? null
            : () {
                ref.read(productionProvider.notifier).delete(existing.id);
                Navigator.pop(ctx);
              },
        onSave: (draft) {
          final notifier = ref.read(productionProvider.notifier);
          if (existing == null) {
            notifier.add(draft);
          } else {
            notifier.update(draft);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref, {
    required Production production,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      isDismissible: true,
      builder: (ctx) => _ImalatDetailSheet(
        productionId: production.id,
        onEditJob: () {
          Navigator.pop(ctx);
          final teams = {
            ...ref.read(teamsProvider),
            ...YevmiyeCalculator.teamNames(ref.read(activePersonnelProvider)),
          }.toList()
            ..sort();
          _openJobEditor(
            context,
            ref,
            projectId: production.projectId,
            teams: teams,
            existing: ref.read(productionProvider)
                .where((p) => p.id == production.id)
                .firstOrNull,
          );
        },
        onAddDay: () {
          final current = ref.read(productionProvider)
              .where((p) => p.id == production.id)
              .firstOrNull;
          if (current != null) {
            _openDayEntry(context, ref, production: current);
          }
        },
      ),
    );
  }

  Future<void> _openDayEntry(
    BuildContext context,
    WidgetRef ref, {
    required Production production,
    ProductionDayEntry? existing,
  }) async {
    if (production.isComplete && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu imalat %100 tamamlandı.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ImalatDayEntrySheet(
        production: production,
        existing: existing,
        onDelete: existing == null
            ? null
            : () {
                ref
                    .read(productionProvider.notifier)
                    .deleteDayEntry(production.id, existing.id);
                Navigator.pop(ctx);
              },
        onSave: (entry) {
          final notifier = ref.read(productionProvider.notifier);
          if (existing == null) {
            notifier.addDayEntry(production.id, entry);
          } else {
            notifier.updateDayEntry(production.id, entry);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// İmalat iş tanımı — ad, ekip, plan miktarı (günlük kayıt ayrı).
class _ImalatJobSheet extends StatefulWidget {
  const _ImalatJobSheet({
    required this.projectId,
    required this.teams,
    required this.onSave,
    this.existing,
    this.onDelete,
  });

  final String projectId;
  final List<String> teams;
  final Production? existing;
  final ValueChanged<Production> onSave;
  final VoidCallback? onDelete;

  @override
  State<_ImalatJobSheet> createState() => _ImalatJobSheetState();
}

class _ImalatJobSheetState extends State<_ImalatJobSheet> {
  late final TextEditingController _name;
  late final TextEditingController _planned;
  late final TextEditingController _note;
  String? _team;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    final existingUnit = e?.unit.trim() ?? '';
    _unit = existingUnit.isEmpty
        ? ImalatUnitCatalog.defaultUnit
        : existingUnit;
    _planned = TextEditingController(
      text: e == null ? '' : _num(e.plannedQty),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _team = e?.teamName.trim().isNotEmpty == true
        ? e!.teamName.trim()
        : (widget.teams.isNotEmpty ? widget.teams.first : null);
  }

  @override
  void dispose() {
    _name.dispose();
    _planned.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamItems = [
      ...widget.teams,
      if (_team != null &&
          _team!.isNotEmpty &&
          !widget.teams.contains(_team))
        _team!,
    ];
    final unitItems = [
      ...ImalatUnitCatalog.units,
      if (_unit.isNotEmpty && !ImalatUnitCatalog.units.contains(_unit)) _unit,
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Yeni imalat' : 'İmalat bilgileri',
              style: theme.textTheme.titleLarge,
            ),
            if (widget.existing == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Plan miktarını girin; günlük usta/düz kayıtlarını '
                  'sonradan ekleyebilirsiniz.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'İmalat adı',
                hintText: 'Örn. Temel demiri',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _team,
              decoration: const InputDecoration(labelText: 'Ekip'),
              items: [
                for (final t in teamItems)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _team = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _planned,
                    decoration: const InputDecoration(
                      labelText: 'Plan miktarı',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Birim'),
                    isExpanded: true,
                    items: [
                      for (final u in unitItems)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _unit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Not'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.onDelete != null)
                  TextButton(
                    onPressed: widget.onDelete,
                    child: const Text(
                      'Sil',
                      style: TextStyle(color: AppColors.critical),
                    ),
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () {
                    final name = _name.text.trim();
                    final team = _team?.trim() ?? '';
                    if (name.isEmpty || team.isEmpty) return;
                    widget.onSave(
                      Production(
                        id: widget.existing?.id ?? '',
                        projectId: widget.projectId,
                        name: name,
                        teamName: team,
                        unit: _unit.trim().isEmpty
                            ? ImalatUnitCatalog.defaultUnit
                            : _unit.trim(),
                        plannedQty:
                            double.tryParse(_planned.text.trim()) ?? 0,
                        note: _note.text.trim(),
                        dailyEntries: widget.existing?.dailyEntries ?? [],
                      ),
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// İmalat detay — ilerleme + günlük kayıt listesi.
class _ImalatDetailSheet extends ConsumerWidget {
  const _ImalatDetailSheet({
    required this.productionId,
    required this.onEditJob,
    required this.onAddDay,
  });

  final String productionId;
  final VoidCallback onEditJob;
  final VoidCallback onAddDay;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = ref.watch(productionProvider)
        .where((e) => e.id == productionId)
        .firstOrNull;
    if (p == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('İmalat bulunamadı')),
      );
    }

    final pct = p.progressPct;
    final color = pct >= 100
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.critical;
    final entries = [...p.dailyEntries]
      ..sort((a, b) => b.date.compareTo(a.date));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.name, style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: onEditJob,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'İmalat bilgileri',
                ),
              ],
            ),
            Text(
              'Ekip: ${p.teamName} · Kalan: ${_fmt(p.remainingQty)} ${p.unit}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_fmt(p.completedQty)} / ${_fmt(p.plannedQty)} ${p.unit}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '%${pct.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text('Günlük kayıtlar', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (!p.isComplete)
                  FilledButton.tonalIcon(
                    onPressed: onAddDay,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Gün ekle'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'Henüz günlük kayıt yok.\n'
                        'Her gün çalışan usta ve düz işçi ekleyin.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return Material(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: AppRadii.sm,
                          child: InkWell(
                            borderRadius: AppRadii.sm,
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (ctx) => _ImalatDayEntrySheet(
                                  production: p,
                                  existing: e,
                                  onDelete: () {
                                    ref
                                        .read(productionProvider.notifier)
                                        .deleteDayEntry(p.id, e.id);
                                    Navigator.pop(ctx);
                                  },
                                  onSave: (updated) {
                                    ref
                                        .read(productionProvider.notifier)
                                        .updateDayEntry(p.id, updated);
                                    Navigator.pop(ctx);
                                  },
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.date,
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        Text(
                                          '${_fmt(e.ustaCount)} usta · '
                                          '${_fmt(e.duzIsciCount)} düz',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+${_fmt(e.completedQty)} ${p.unit}',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek günlük kayıt — usta/düz ataması + o gün gerçekleşen miktar.
class _ImalatDayEntrySheet extends ConsumerStatefulWidget {
  const _ImalatDayEntrySheet({
    required this.production,
    required this.onSave,
    this.existing,
    this.onDelete,
  });

  final Production production;
  final ProductionDayEntry? existing;
  final ValueChanged<ProductionDayEntry> onSave;
  final VoidCallback? onDelete;

  @override
  ConsumerState<_ImalatDayEntrySheet> createState() =>
      _ImalatDayEntrySheetState();
}

class _ImalatDayEntrySheetState extends ConsumerState<_ImalatDayEntrySheet> {
  late final TextEditingController _usta;
  late final TextEditingController _duz;
  late final TextEditingController _done;
  late final TextEditingController _note;
  late String _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _usta = TextEditingController(
      text: e == null ? '' : _num(e.ustaCount),
    );
    _duz = TextEditingController(
      text: e == null ? '' : _num(e.duzIsciCount),
    );
    _done = TextEditingController(
      text: e == null ? '' : _num(e.completedQty),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? PuantajDate.today();

    if (e == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fillUnassignedIfEmpty();
      });
    }
  }

  void _fillUnassignedIfEmpty() {
    final pool = _poolFor(
      people: ref.read(activePersonnelProvider),
      attendance: ref.read(attendanceProvider),
      productions: ref.read(productionProvider),
    );
    if (_usta.text.trim().isEmpty) {
      _usta.text = _num(pool.ustaRemaining);
    }
    if (_duz.text.trim().isEmpty) {
      _duz.text = _num(pool.duzRemaining);
    }
    setState(() {});
  }

  CrewPool _poolFor({
    required List<Person> people,
    required List<Attendance> attendance,
    required List<Production> productions,
  }) {
    return ImalatCrewAllocator.availableFor(
      projectId: widget.production.projectId,
      date: _date,
      teamName: widget.production.teamName,
      people: people,
      attendance: attendance,
      productions: productions,
      excludeDayEntryId: widget.existing?.id,
    );
  }

  double _remainingQtyExcludingCurrent() {
    final doneOthers = widget.production.dailyEntries
        .where((e) => e.id != widget.existing?.id)
        .fold<double>(0, (s, e) => s + e.completedQty);
    if (widget.production.plannedQty <= 0) return double.infinity;
    return (widget.production.plannedQty - doneOthers).clamp(0, double.infinity);
  }

  @override
  void dispose() {
    _usta.dispose();
    _duz.dispose();
    _done.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final people = ref.watch(activePersonnelProvider);
    final attendance = ref.watch(attendanceProvider);
    final productions = ref.watch(productionProvider);

    final pool = _poolFor(
      people: people,
      attendance: attendance,
      productions: productions,
    );
    final remainingQty = _remainingQtyExcludingCurrent();
    final duplicateDate = widget.existing == null &&
        widget.production.entryOnDate(_date) != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? 'Günlük kayıt — ${widget.production.name}'
                  : 'Kayıt düzenle — ${_date}',
              style: theme.textTheme.titleLarge,
            ),
            Text(
              'Kalan plan: ${_num(remainingQty)} ${widget.production.unit}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: widget.existing != null
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: PuantajDate.parse(_date),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _date = PuantajDate.format(picked));
                        _usta.clear();
                        _duz.clear();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _fillUnassignedIfEmpty();
                        });
                      }
                    },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_date),
            ),
            if (duplicateDate)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Bu tarihte kayıt var; düzenlemek için listeden seçin.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            _CrewPoolBanner(pool: pool),
            const SizedBox(height: AppSpacing.sm),
            Text('Bu güne atama (manuel)', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usta,
                    decoration: InputDecoration(
                      labelText: 'Usta',
                      helperText:
                          'Ataması yapılmamış ${_num(pool.ustaRemaining)}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _duz,
                    decoration: InputDecoration(
                      labelText: 'Düz işçi / Çırak',
                      helperText:
                          'Ataması yapılmamış ${_num(pool.duzRemaining)}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _usta.text = _num(pool.ustaRemaining);
                  _duz.text = _num(pool.duzRemaining);
                  setState(() {});
                },
                icon: const Icon(Icons.content_paste_go, size: 16),
                label: const Text('Atanmayanı doldur'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _done,
              decoration: InputDecoration(
                labelText: 'Bugün gerçekleşen (${widget.production.unit})',
                helperText: 'Kalan plan: ${_num(remainingQty)}',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Not'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.onDelete != null)
                  TextButton(
                    onPressed: widget.onDelete,
                    child: const Text(
                      'Sil',
                      style: TextStyle(color: AppColors.critical),
                    ),
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: duplicateDate
                      ? null
                      : () {
                          final completed =
                              double.tryParse(_done.text.trim()) ?? 0;
                          if (completed <= 0 &&
                              (double.tryParse(_usta.text.trim()) ?? 0) <= 0 &&
                              (double.tryParse(_duz.text.trim()) ?? 0) <= 0) {
                            return;
                          }
                          widget.onSave(
                            ProductionDayEntry(
                              id: widget.existing?.id ?? '',
                              date: _date,
                              ustaCount:
                                  double.tryParse(_usta.text.trim()) ?? 0,
                              duzIsciCount:
                                  double.tryParse(_duz.text.trim()) ?? 0,
                              completedQty: completed,
                              note: _note.text.trim(),
                            ),
                          );
                        },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CrewPoolBanner extends StatelessWidget {
  const _CrewPoolBanner({required this.pool});

  final CrewPool pool;

  static String _n(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.08),
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined,
                  size: 18, color: AppColors.electricBlue),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Puantaj havuzu (mesai dahil)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.electricBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Toplam: ${_n(pool.ustaTotal)} usta · ${_n(pool.duzTotal)} düz işçi',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Diğer imalatlarda: ${_n(pool.ustaAllocated)} usta · '
            '${_n(pool.duzAllocated)} düz',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Ataması yapılmamış: ${_n(pool.ustaRemaining)} usta · '
            '${_n(pool.duzRemaining)} düz',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.electricBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sayılar bilgi amaçlıdır; atamayı siz girersiniz. '
            'Personel / puantaj değişince otomatik güncellenir.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
