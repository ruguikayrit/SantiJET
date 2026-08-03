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
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../data/providers/verim_provider.dart';
import '../../data/services/is_programi_cloud_service.dart';
import '../../data/services/kesif_cloud_service.dart';
import '../../domain/entities/kesif_plan.dart';
import '../../domain/entities/production.dart';
import '../../domain/entities/production_day_entry.dart';
import '../../domain/entities/work_schedule_plan.dart';
import '../../domain/catalogs/imalat_units.dart';
import '../../domain/yevmiye/yevmiye_calculator.dart';

/// İmalat — iş tanımı + %100'e kadar günlük usta/düz kayıtları.
class ImalatScreen extends ConsumerStatefulWidget {
  const ImalatScreen({super.key});

  @override
  ConsumerState<ImalatScreen> createState() => _ImalatScreenState();
}

class _ImalatScreenState extends ConsumerState<ImalatScreen> {
  /// `null` = tüm ekipler; aksi halde ekip adına göre filtre.
  String? _teamFilter;

  /// `null` = tüm imalat tipleri; aksi halde tip adına göre filtre.
  String? _typeFilter;

  /// Kullanıcının elle açtığı ekip başlıkları.
  final Set<String> _manualExpand = {};

  /// Kullanıcının elle kapattığı ekip başlıkları.
  final Set<String> _manualCollapse = {};

  static String _typeKey(Production p) {
    final n = p.name.trim();
    return n.isEmpty ? 'Adsız imalat' : n;
  }

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

  bool _isTeamExpanded(String team, bool updatedToday) {
    if (_manualExpand.contains(team)) return true;
    if (_manualCollapse.contains(team)) return false;
    // Varsayılan: kapalı; yalnızca bugün güncellenen ekip açık.
    return updatedToday;
  }

  void _toggleTeam(String team, bool currentlyExpanded) {
    setState(() {
      if (currentlyExpanded) {
        _manualExpand.remove(team);
        _manualCollapse.add(team);
      } else {
        _manualCollapse.remove(team);
        _manualExpand.add(team);
      }
    });
  }

  List<Production> _applyFilters(List<Production> items) {
    return items.where((p) {
      if (_teamFilter != null && _teamKey(p) != _teamFilter) return false;
      if (_typeFilter != null && _typeKey(p) != _typeFilter) return false;
      return true;
    }).toList();
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

  Future<void> _openFilterSheet({
    required List<String> teamOptions,
    required List<String> typeOptions,
  }) async {
    var draftTeam = _teamFilter;
    var draftType = _typeFilter;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Widget chipRow({
              required String title,
              required List<String> options,
              required String? selected,
              required ValueChanged<String?> onSelect,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tümü'),
                        selected: selected == null,
                        onSelected: (_) => setModal(() => onSelect(null)),
                      ),
                      for (final o in options)
                        FilterChip(
                          label: Text(o),
                          selected: selected == o,
                          onSelected: (_) => setModal(() => onSelect(o)),
                        ),
                    ],
                  ),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filtrele',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (typeOptions.length > 1) ...[
                      chipRow(
                        title: 'İmalat tipi',
                        options: typeOptions,
                        selected: draftType,
                        onSelect: (v) => draftType = v,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (teamOptions.length > 1) ...[
                      chipRow(
                        title: 'Ekip',
                        options: teamOptions,
                        selected: draftTeam,
                        onSelect: (v) => draftTeam = v,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (typeOptions.length <= 1 && teamOptions.length <= 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          'Filtrelenecek ek tip veya ekip yok.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            draftTeam = null;
                            draftType = null;
                            setModal(() {});
                          },
                          child: const Text('Temizle'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Uygula'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (applied == true && mounted) {
      setState(() {
        _teamFilter = draftTeam;
        _typeFilter = draftType;
      });
    }
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
              _ImalatDualProgress(production: p),
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

  Widget _teamHeader({
    required String team,
    required int count,
    required bool expanded,
    required bool updatedToday,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final accent = AppColors.useDarkCards
        ? AppColors.electricBlueLight
        : AppColors.electricBlue;
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
                  ? accent.withValues(alpha: 0.45)
                  : theme.dividerColor.withValues(alpha: 0.5),
            ),
            color: updatedToday
                ? accent.withValues(alpha: 0.08)
                : theme.colorScheme.surface.withValues(alpha: 0.35),
          ),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: accent,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  team,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              if (updatedToday)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Bugün',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'İmalat'),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'İmalat kayıtları proje kapsamında tutulur.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelere Git',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
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

    final typeOptions = {
      for (final p in items) _typeKey(p),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final teamOptions = {
      for (final p in items) _teamKey(p),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Geçersiz filtreleri temizle (silinen tip/ekip).
    if (_typeFilter != null && !typeOptions.contains(_typeFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _typeFilter = null);
      });
    }
    if (_teamFilter != null && !teamOptions.contains(_teamFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _teamFilter = null);
      });
    }

    final filtered = _applyFilters(items);
    final groups = _groupByTeam(filtered);
    final filterActive = _teamFilter != null || _typeFilter != null;

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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'İmalat'),
            if (items.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: IconButton(
                    tooltip: 'Filtrele',
                    onPressed: () => _openFilterSheet(
                      teamOptions: teamOptions,
                      typeOptions: typeOptions,
                    ),
                    icon: Badge(
                      isLabelVisible: filterActive,
                      smallSize: 8,
                      child: const Icon(Icons.filter_list_rounded),
                    ),
                  ),
                ),
              ),
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
                          ? () => context.go(AppRoutes.personel)
                          : () => _openJobEditor(
                                context,
                                ref,
                                projectId: project.id,
                                teams: teams,
                              ),
                    )
                  : filtered.isEmpty
                      ? SJEmptyState(
                          title: 'Sonuç yok',
                          message: 'Seçilen filtreye uyan imalat bulunamadı.',
                          icon: Icons.filter_alt_off_outlined,
                          actionLabel: 'Filtreyi temizle',
                          onAction: () => setState(() {
                            _teamFilter = null;
                            _typeFilter = null;
                          }),
                        )
                      : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    88,
                  ),
                  children: [
                    for (var gi = 0; gi < groups.length; gi++) ...[
                      if (gi > 0) const SizedBox(height: AppSpacing.sm),
                      Builder(
                        builder: (context) {
                          final g = groups[gi];
                          final expanded =
                              _isTeamExpanded(g.team, g.updatedToday);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _teamHeader(
                                team: g.team,
                                count: g.items.length,
                                expanded: expanded,
                                updatedToday: g.updatedToday,
                                onToggle: () =>
                                    _toggleTeam(g.team, expanded),
                              ),
                              if (expanded) ...[
                                const SizedBox(height: AppSpacing.sm),
                                for (var i = 0; i < g.items.length; i++) ...[
                                  if (i > 0)
                                    const SizedBox(height: AppSpacing.sm),
                                  _productionCard(g.items[i]),
                                ],
                              ],
                            ],
                          );
                        },
                      ),
                    ],
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
  late final TextEditingController _note;
  String? _team;
  late String _unit;
  bool _pullingDays = false;
  String? _scheduleHint;

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
    _note.dispose();
    super.dispose();
  }

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  WorkScheduleItem? _matchSchedule(List<WorkScheduleItem> items, String name) {
    final target = _norm(name);
    if (target.isEmpty) return null;
    for (final item in items) {
      if (_norm(item.imalatName) == target) return item;
    }
    for (final item in items) {
      final n = _norm(item.imalatName);
      if (n.contains(target) || target.contains(n)) return item;
    }
    return null;
  }

  KesifItem? _matchKesif(List<KesifItem> items, String name) {
    final target = _norm(name);
    if (target.isEmpty) return null;
    for (final item in items) {
      if (_norm(item.imalatName) == target) return item;
    }
    for (final item in items) {
      final n = _norm(item.imalatName);
      if (n.contains(target) || target.contains(n)) return item;
    }
    return null;
  }

  /// Süre ← İş Programı, plan metraj ← Keşif.
  Future<void> _pullPlannedDaysFromSchedule() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce imalat adını girin; eşleştirme ada göre yapılır.'),
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
      final scheduleSvc = ref.read(isProgramiCloudServiceProvider);
      final kesifSvc = ref.read(kesifCloudServiceProvider);

      WorkScheduleSnapshot scheduleSnap;
      KesifSnapshot kesifSnap;
      var fromDemo = false;

      try {
        scheduleSnap = await scheduleSvc.sync(
          projectId: widget.projectId,
          projectCode: project?.code,
          projectName: project?.name,
        );
      } on IsProgramiCloudException {
        final cached = scheduleSvc.cachedFor(widget.projectId);
        if (cached != null && cached.items.isNotEmpty) {
          scheduleSnap = cached;
        } else {
          scheduleSnap = await scheduleSvc.syncDemo(
            projectId: widget.projectId,
            projectName: project?.name,
          );
          fromDemo = true;
        }
      }

      try {
        kesifSnap = await kesifSvc.sync(
          projectId: widget.projectId,
          projectCode: project?.code,
          projectName: project?.name,
        );
      } on KesifCloudException {
        final cached = kesifSvc.cachedFor(widget.projectId);
        if (cached != null && cached.items.isNotEmpty) {
          kesifSnap = cached;
        } else {
          kesifSnap = await kesifSvc.syncDemo(
            projectId: widget.projectId,
            projectName: project?.name,
          );
          fromDemo = true;
        }
      }

      if (!mounted) return;

      final scheduleMatch = _matchSchedule(scheduleSnap.items, name);
      final kesifMatch = _matchKesif(kesifSnap.items, name);
      final parts = <String>[];

      if (scheduleMatch != null) {
        final days = scheduleMatch.durationDays;
        if (days != null && days > 0) {
          _plannedDays.text = '$days';
          parts.add(
            'süre $days gün'
            '${scheduleMatch.startDate != null && scheduleMatch.endDate != null ? ' (${scheduleMatch.startDate} → ${scheduleMatch.endDate})' : ''}',
          );
        } else {
          parts.add('İş Programı’nda tarih yok');
        }
      } else {
        parts.add('İş Programı eşleşmedi');
      }

      if (kesifMatch != null && kesifMatch.plannedQty > 0) {
        _planned.text = _num(kesifMatch.plannedQty);
        parts.add(
          'metraj ${_num(kesifMatch.plannedQty)} ${kesifMatch.unit}',
        );
      } else {
        parts.add('Keşif metraj eşleşmedi');
      }

      final prefix = fromDemo ? 'Demo buluttan' : 'Buluttan';
      setState(() {
        if (kesifMatch != null &&
            kesifMatch.unit.trim().isNotEmpty &&
            (_unit.trim().isEmpty ||
                _unit == ImalatUnitCatalog.defaultUnit)) {
          _unit = kesifMatch.unit.trim();
        }
        _scheduleHint = '$prefix: ${parts.join(' · ')}.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_scheduleHint!)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İş Programı / Keşif verisi alınamadı.'),
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
                  'Plan metraj (Keşif) ve gün (İş Programı) girin veya '
                  'buluttan çekin; günlük kayıtları sonradan ekleyin.',
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
            OutlinedButton.icon(
              onPressed: _pullingDays ? null : _pullPlannedDaysFromSchedule,
              icon: _pullingDays
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined, size: 20),
              label: Text(
                _pullingDays
                    ? 'Buluttan alınıyor…'
                    : 'Buluttan al (süre: İş Programı · metraj: Keşif)',
              ),
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
                color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ImalatDualProgress(production: p, dense: false),
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

Color _progressColor(double pct) {
  if (pct >= 100) return AppColors.success;
  if (pct >= 50) return AppColors.warning;
  return AppColors.critical;
}

/// Metraj ve süre bazlı çift ilerleme çubuğu.
class _ImalatDualProgress extends StatelessWidget {
  const _ImalatDualProgress({
    required this.production,
    this.dense = true,
  });

  final Production production;
  final bool dense;

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barH = dense ? 6.0 : 8.0;
    final gap = dense ? AppSpacing.xs : AppSpacing.sm;
    final showTime = production.plannedDays > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressLine(
          label: 'Metraj',
          detail:
              '${_fmt(production.completedQty)} / ${_fmt(production.plannedQty)} ${production.unit}',
          pct: production.progressPct,
          color: _progressColor(production.progressPct),
          barHeight: barH,
          labelStyle: theme.textTheme.labelSmall,
        ),
        if (showTime) ...[
          SizedBox(height: gap),
          _ProgressLine(
            label: 'Süre',
            detail: '${production.workedDays} / ${production.plannedDays} gün',
            pct: production.timeProgressPct,
            color: _progressColor(production.timeProgressPct),
            barHeight: barH,
            labelStyle: theme.textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.detail,
    required this.pct,
    required this.color,
    required this.barHeight,
    required this.labelStyle,
  });

  final String label;
  final String detail;
  final double pct;
  final Color color;
  final double barHeight;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: labelStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                detail,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '%${pct.toStringAsFixed(0)}',
              style: labelStyle?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: barHeight,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}
