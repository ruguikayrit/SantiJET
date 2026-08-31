import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/widgets/production_triple_progress.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/plan_cloud_sync_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../data/services/plan_item_matcher.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/production_day_entry.dart';
import '../../domain/entities/santijet_plan_pack.dart';
import '../../domain/catalogs/imalat_units.dart';
import '../../domain/yevmiye/yevmiye_calculator.dart';
import 'widgets/production_performance_chart.dart';

enum _ImalatPhase {
  bekleyen,
  devamEden,
  tamamlanan;

  String get label => switch (this) {
        _ImalatPhase.bekleyen => 'Bekleyen imalatlar',
        _ImalatPhase.devamEden => 'Devam eden imalatlar',
        _ImalatPhase.tamamlanan => 'Tamamlanan imalatlar',
      };

  String get shortLabel => switch (this) {
        _ImalatPhase.bekleyen => 'Bekleyen',
        _ImalatPhase.devamEden => 'Devam eden',
        _ImalatPhase.tamamlanan => 'Tamamlanan',
      };

  Color get accent => switch (this) {
        _ImalatPhase.bekleyen => AppColors.warning,
        _ImalatPhase.devamEden => AppColors.info,
        _ImalatPhase.tamamlanan => AppColors.success,
      };
}

/// İmalat — iş tanımı + %100'e kadar günlük usta/düz kayıtları.
class ImalatScreen extends ConsumerStatefulWidget {
  const ImalatScreen({super.key, this.embedded = false});

  /// Hub içindeyken üst chrome (header) gösterilmez.
  final bool embedded;

  @override
  ConsumerState<ImalatScreen> createState() => _ImalatScreenState();
}

class _ImalatScreenState extends ConsumerState<ImalatScreen> {
  /// Seçili imalat durumu — acil görev filtre kartları gibi.
  _ImalatPhase _selectedPhase = _ImalatPhase.devamEden;

  /// Kullanıcının elle açtığı ekip başlıkları.
  final Set<String> _manualExpand = {};

  /// Kullanıcının elle kapattığı ekip başlıkları.
  final Set<String> _manualCollapse = {};

  static String _teamKey(Production p) {
    final t = p.teamName.trim();
    return t.isEmpty ? 'Ekip seçilmedi' : t;
  }

  static bool _updatedToday(Production p) {
    final today = PuantajDate.today();
    return p.dailyEntries.any((e) => e.date.trim() == today);
  }

  static bool _teamUpdatedToday(List<Production> items) =>
      items.any(_updatedToday);

  /// Bekleyen = henüz günlük kayıt yok; tamamlanan = %100; aksi devam eden.
  static _ImalatPhase _phaseOf(Production p) {
    if (p.isComplete) return _ImalatPhase.tamamlanan;
    if (p.dailyEntries.isEmpty) return _ImalatPhase.bekleyen;
    return _ImalatPhase.devamEden;
  }

  bool _isTeamExpanded(String teamKey, bool updatedToday) {
    if (_manualExpand.contains(teamKey)) return true;
    if (_manualCollapse.contains(teamKey)) return false;
    return false;
  }

  void _toggleTeam(String teamKey, bool currentlyExpanded) {
    setState(() {
      if (currentlyExpanded) {
        _manualExpand.remove(teamKey);
        _manualCollapse.add(teamKey);
      } else {
        _manualCollapse.remove(teamKey);
        _manualExpand.add(teamKey);
      }
    });
  }

  /// Ekip başlıkları altında gruplar (Demir, Kalıp, Beton…).
  List<({String team, List<Production> items, bool updatedToday})> _groupByTeam(
    List<Production> items,
  ) {
    final map = <String, List<Production>>{};
    for (final p in items) {
      map.putIfAbsent(_teamKey(p), () => []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (name != 0) return name;
        final loc = a.locationLabel.compareTo(b.locationLabel);
        if (loc != 0) return loc;
        return b.latestDate.compareTo(a.latestDate);
      });
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        final aToday = _teamUpdatedToday(map[a]!) ? 0 : 1;
        final bToday = _teamUpdatedToday(map[b]!) ? 0 : 1;
        if (aToday != bToday) return aToday.compareTo(bToday);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [
      for (final k in keys)
        (
          team: k,
          items: map[k]!,
          updatedToday: _teamUpdatedToday(map[k]!),
        ),
    ];
  }

  Map<_ImalatPhase, List<Production>> _groupByPhase(List<Production> items) {
    final map = {
      for (final p in _ImalatPhase.values) p: <Production>[],
    };
    for (final p in items) {
      map[_phaseOf(p)]!.add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (name != 0) return name;
        return b.latestDate.compareTo(a.latestDate);
      });
    }
    return map;
  }

  Widget _productionCard(Production p) {
    final title = p.name.trim().isEmpty ? 'İmalat' : p.name.trim();
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
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (_updatedToday(p))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SJStatusBadge(
                        label: 'Bugün',
                        color: AppColors.info,
                      ),
                    ),
                  if (p.isComplete)
                    SJStatusBadge(
                      label: 'Tamamlandı',
                      color: AppColors.success,
                    ),
                ],
              ),
              if (p.locationLabel.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  p.locationLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Toplam çalışan: ${_fmt(p.ustaCount)} usta · '
                '${_fmt(p.duzIsciCount)} düz',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ProductionTripleProgress(metrics: p.metrics),
              if (p.dailyEntries.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                ProductionPerformanceChart(production: p),
              ],
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
  }

  Widget _phaseFilterBar(Map<_ImalatPhase, List<Production>> byPhase) {
    return Row(
      children: [
        for (var i = 0; i < _ImalatPhase.values.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _ImalatPhaseFilterCard(
              label: _ImalatPhase.values[i].shortLabel,
              value: '${byPhase[_ImalatPhase.values[i]]!.length}',
              color: _ImalatPhase.values[i].accent,
              selected: _selectedPhase == _ImalatPhase.values[i],
              onTap: () =>
                  setState(() => _selectedPhase = _ImalatPhase.values[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _phaseContent({
    required _ImalatPhase phase,
    required List<Production> phaseItems,
  }) {
    final teamGroups = _groupByTeam(phaseItems);
    if (phaseItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          'Bu grupta imalat yok',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        for (var gi = 0; gi < teamGroups.length; gi++) ...[
          if (gi > 0) const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final g = teamGroups[gi];
              final teamKey = '${phase.name}|${g.team}';
              final expanded = _isTeamExpanded(teamKey, g.updatedToday);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _teamHeader(
                    team: g.team,
                    count: g.items.length,
                    expanded: expanded,
                    updatedToday: g.updatedToday,
                    onToggle: () => _toggleTeam(teamKey, expanded),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < g.items.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _productionCard(g.items[i]),
                    ],
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _teamHeader({
    required String team,
    required int count,
    required bool expanded,
    required bool updatedToday,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final accent = AppColors.useDarkChrome
        ? AppColors.electricBlueLight
        : AppColors.electricBlue;
    final headerBg = updatedToday
        ? accent.withValues(alpha: AppColors.useDarkChrome ? 0.16 : 0.1)
        : AppColors.surface;
    final titleColor = AppColors.textSecondary;
    final countColor = AppColors.readableMutedOn(headerBg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.md,
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            border: Border.all(
              color: updatedToday
                  ? accent.withValues(alpha: 0.4)
                  : AppColors.border.withValues(alpha: 0.65),
            ),
            color: headerBg,
          ),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: titleColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  team,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              if (updatedToday)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Bugün',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.statusInkOnChrome(accent),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: countColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final items = ref.watch(activeProductionProvider);

    if (project == null) {
      final empty = SJEmptyState(
        title: 'Önce proje ekleyin',
        message: 'İmalat kayıtları proje kapsamında tutulur.',
        icon: Icons.apartment_outlined,
        actionLabel: 'Projelere Git',
        onAction: () => context.go(AppRoutes.projeler),
      );
      if (widget.embedded) return empty;
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'İmalat'),
              Expanded(child: empty),
            ],
          ),
        ),
      );
    }

    final teams = {
      ...ref.watch(teamsProvider),
      ...YevmiyeCalculator.teamNames(ref.watch(activePersonnelProvider)),
    }.toList()
      ..sort();

    final byPhase = _groupByPhase(items);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: teams.isEmpty
            ? () => _warnNoTeams(context)
            : () => _openJobEditor(
                  context,
                  ref,
                  projectId: project.id,
                  teams: teams,
                ),
        icon: const Icon(Icons.add),
        label: const Text('İmalat Ekle'),
      ),
      body: SafeArea(
        top: !widget.embedded,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embedded) const SantijetHeader(subtitle: 'İmalat'),
            Expanded(
              child: items.isEmpty
                  ? SJEmptyState(
                      title: teams.isEmpty
                          ? 'Önce ekip tanımlayın'
                          : 'Henüz imalat yok',
                      message: teams.isEmpty
                          ? 'Ayarlar → Ekipler / Personel’de ekip tanımlayın.'
                          : 'İmalat tanımlayın; %100 tamamlanana kadar her gün '
                              'usta ve düz işçi ekleyebilirsiniz.',
                      icon: teams.isEmpty
                          ? Icons.groups_outlined
                          : Icons.construction_outlined,
                      actionLabel: teams.isEmpty ? 'Personel' : 'İmalat Ekle',
                      onAction: teams.isEmpty
                          ? () => context.push(AppRoutes.personel)
                          : () => _openJobEditor(
                                context,
                                ref,
                                projectId: project.id,
                                teams: teams,
                              ),
                    )
                  : ListView(
                      padding: AppLayout.scrollPadding(
                        top: AppSpacing.sm,
                        clearFab: true,
                      ),
                      children: [
                        _phaseFilterBar(byPhase),
                        _phaseContent(
                          phase: _selectedPhase,
                          phaseItems: byPhase[_selectedPhase]!,
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
  }) {
    return openImalatJobEditor(
      context,
      ref,
      projectId: projectId,
      teams: teams,
      existing: existing,
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref, {
    required Production production,
  }) {
    return openImalatProductionDetail(
      context,
      ref,
      productionId: production.id,
    );
  }

  Future<void> _openDayEntry(
    BuildContext context,
    WidgetRef ref, {
    required Production production,
    ProductionDayEntry? existing,
  }) {
    return openImalatDayEntry(
      context,
      ref,
      production: production,
      existing: existing,
    );
  }
}

/// Verim vb. ekranlardan aynı imalat detay kartını açar.
Future<void> openImalatProductionDetail(
  BuildContext context,
  WidgetRef ref, {
  required String productionId,
}) async {
  final seed = ref
      .read(productionProvider)
      .where((p) => p.id == productionId)
      .firstOrNull;
  if (seed == null) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    isDismissible: true,
    builder: (ctx) => _ImalatDetailSheet(
      productionId: productionId,
      onEditJob: () {
        Navigator.pop(ctx);
        final current = ref
                .read(productionProvider)
                .where((p) => p.id == productionId)
                .firstOrNull ??
            seed;
        final teams = {
          ...ref.read(teamsProvider),
          ...YevmiyeCalculator.teamNames(ref.read(activePersonnelProvider)),
        }.toList()
          ..sort();
        openImalatJobEditor(
          context,
          ref,
          projectId: current.projectId,
          teams: teams,
          existing: current,
        );
      },
      onAddDay: () {
        final current = ref
            .read(productionProvider)
            .where((p) => p.id == productionId)
            .firstOrNull;
        if (current != null) {
          openImalatDayEntry(context, ref, production: current);
        }
      },
    ),
  );
}

Future<void> openImalatJobEditor(
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

Future<void> openImalatDayEntry(
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

/// İmalat iş tanımı — ad, ekip, plan miktarı / gün (günlük kayıt ayrı).
class _ImalatJobSheet extends ConsumerStatefulWidget {
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
  ConsumerState<_ImalatJobSheet> createState() => _ImalatJobSheetState();
}

class _ImalatJobSheetState extends ConsumerState<_ImalatJobSheet> {
  late final TextEditingController _floor;
  late final TextEditingController _section;
  late final TextEditingController _name;
  late final TextEditingController _planned;
  late final TextEditingController _plannedDays;
  late final TextEditingController _plannedLabor;
  late final TextEditingController _note;
  String? _team;
  late String _unit;
  bool _pullingDays = false;
  String? _scheduleHint;
  bool _overwritePlanFields = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _floor = TextEditingController(text: e?.floor ?? '');
    _section = TextEditingController(text: e?.section ?? '');
    _name = TextEditingController(text: e?.name ?? '');
    final existingUnit = e?.unit.trim() ?? '';
    _unit = existingUnit.isEmpty
        ? ImalatUnitCatalog.defaultUnit
        : existingUnit;
    _planned = TextEditingController(
      text: e == null ? '' : _num(e.plannedQty),
    );
    _plannedDays = TextEditingController(
      text: e == null || e.plannedDays <= 0 ? '' : '${e.plannedDays}',
    );
    _plannedLabor = TextEditingController(
      text: e == null || e.plannedLabor <= 0 ? '' : _num(e.plannedLabor),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _team = e?.teamName.trim().isNotEmpty == true
        ? e!.teamName.trim()
        : (widget.teams.isNotEmpty ? widget.teams.first : null);
  }

  @override
  void dispose() {
    _floor.dispose();
    _section.dispose();
    _name.dispose();
    _planned.dispose();
    _plannedDays.dispose();
    _plannedLabor.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  double get _currentQty =>
      double.tryParse(_planned.text.replaceAll(',', '.')) ?? 0;
  int get _currentDays => int.tryParse(_plannedDays.text.trim()) ?? 0;
  double get _currentLabor =>
      double.tryParse(_plannedLabor.text.replaceAll(',', '.')) ?? 0;

  /// Süre ← İş Programı, plan metraj ← Keşif (önbellek veya dosya).
  Future<void> _pullPlannedDaysFromSchedule() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Önce imalat adını girin; eşleştirme id veya ada göre yapılır.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _pullingDays = true;
      _scheduleHint = null;
    });

    try {
      final project = ref.read(activeProjectProvider);
      final ctrl = ref.read(planCloudSyncControllerProvider);
      var scheduleSnap = ctrl.cachedSchedule(widget.projectId);
      var kesifSnap = ctrl.cachedKesif(widget.projectId);
      var fromFilePick = false;

      final needFile = (scheduleSnap == null || scheduleSnap.items.isEmpty) &&
          (kesifSnap == null || kesifSnap.items.isEmpty);

      if (needFile) {
        if (project == null) {
          throw SantijetPlanPackException('Aktif proje yok.');
        }
        final imported = await ctrl.importPackForProject(project);
        if (imported == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya seçimi iptal edildi')),
          );
          return;
        }
        fromFilePick = true;
        scheduleSnap = imported.schedule ?? ctrl.cachedSchedule(widget.projectId);
        kesifSnap = imported.kesif ?? ctrl.cachedKesif(widget.projectId);
      }

      if (!mounted) return;

      final scheduleMatch = matchScheduleItem(
        scheduleSnap?.items ?? const [],
        name: name,
      );
      final kesifMatch = matchKesifItem(
        kesifSnap?.items ?? const [],
        name: name,
      );

      final mode = _overwritePlanFields
          ? PlanFieldApplyMode.overwrite
          : PlanFieldApplyMode.fillEmpty;
      final applied = applyPlanToForm(
        mode: mode,
        currentQty: _currentQty,
        currentUnit: _unit,
        currentDays: _currentDays,
        currentLabor: _currentLabor,
        kesif: kesifMatch,
        schedule: scheduleMatch,
      );

      if (applied.plannedDays != null) {
        _plannedDays.text = '${applied.plannedDays}';
      }
      if (applied.plannedLabor != null) {
        _plannedLabor.text = _num(applied.plannedLabor!);
      }
      if (applied.plannedQty != null) {
        _planned.text = _num(applied.plannedQty!);
      }
      if (applied.unit != null && applied.unit!.isNotEmpty) {
        _unit = applied.unit!;
      }

      final prefix = fromFilePick ? 'Dosyadan' : 'Önbellekten';
      setState(() {
        _scheduleHint = '$prefix: ${applied.parts.join(' · ')}.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_scheduleHint!)),
      );
    } on SantijetPlanPackException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İş Programı / Keşif dosyası okunamadı.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _pullingDays = false);
    }
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
                  'Plan metraj (Keşif) ve gün/iş gücü (İş Programı) elle '
                  'girilir veya JSON dosyasından alınır; günlük kayıtlar '
                  'sonradan eklenir.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _floor,
              decoration: const InputDecoration(
                labelText: 'Bulunduğu Kat',
                hintText: 'Örn. Bodrum, Zemin, 3. Kat',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _section,
              decoration: const InputDecoration(
                labelText: 'Bulunduğu Kısım/Bölge/Etap',
                hintText: 'Örn. A Blok, Etap 2, Doğu cephe',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'İmalatın Adı',
                hintText: 'Örn. Kolon Demiri',
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
                      labelText: 'Planlanan keşif miktarı',
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
              controller: _plannedDays,
              decoration: const InputDecoration(
                labelText: 'Planlanan gün sayısı',
                hintText: 'Örn. 14',
                suffixText: 'gün',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _plannedLabor,
              decoration: const InputDecoration(
                labelText: 'Planlanan iş gücü',
                hintText: 'Örn. 8',
                suffixText: 'kişi',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pullingDays ? null : _pullPlannedDaysFromSchedule,
              icon: _pullingDays
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_open_outlined, size: 20),
              label: Text(
                _pullingDays
                    ? 'Plan alınıyor…'
                    : 'Dosyadan / önbellekten al (Keşif + İş Programı)',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _overwritePlanFields,
              onChanged: _pullingDays
                  ? null
                  : (v) => setState(() => _overwritePlanFields = v ?? false),
              title: Text(
                'Dolu plan alanlarını üzerine yaz',
                style: theme.textTheme.bodySmall,
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_scheduleHint != null) ...[
              const SizedBox(height: 6),
              Text(
                _scheduleHint!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
                        floor: _floor.text.trim(),
                        section: _section.text.trim(),
                        teamName: team,
                        unit: _unit.trim().isEmpty
                            ? ImalatUnitCatalog.defaultUnit
                            : _unit.trim(),
                        plannedQty:
                            double.tryParse(_planned.text.trim()) ?? 0,
                        plannedDays:
                            int.tryParse(_plannedDays.text.trim()) ?? 0,
                        plannedLabor:
                            double.tryParse(_plannedLabor.text.trim()) ?? 0,
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
                if (p.metrics.unitEfficiency != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: UnitEfficiencyBadge(
                      efficiency: p.metrics.unitEfficiency,
                    ),
                  ),
                IconButton(
                  onPressed: onEditJob,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'İmalat bilgileri',
                ),
              ],
            ),
            Text(
              [
                if (p.locationLabel.isNotEmpty) p.locationLabel,
                'Ekip: ${p.teamName}',
                'Kalan: ${_fmt(p.remainingQty)} ${p.unit}',
              ].join(' · '),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ProductionTripleProgress(metrics: p.metrics, dense: false),
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
                          color: AppColors.surfaceElevated,
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

/// Tek günlük kayıt — usta/düz + o gün gerçekleşen miktar.
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usta,
                    decoration: const InputDecoration(labelText: 'Usta'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _duz,
                    decoration: const InputDecoration(
                      labelText: 'Düz işçi / Çırak',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
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

/// Ana sayfa acil görev filtre kartları ile aynı dil.
class _ImalatPhaseFilterCard extends StatelessWidget {
  const _ImalatPhaseFilterCard({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.16 : 0.08),
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.55 : 0.25),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 2),
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.statusInkOnCard(color),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.statusInkOnCard(color),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
