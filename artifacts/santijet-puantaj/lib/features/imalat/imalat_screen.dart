import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
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
import '../../domain/yevmiye/imalat_crew_allocator.dart';
import '../../domain/yevmiye/yevmiye_calculator.dart';

/// Günlük imalat — ekip seçimi; usta/düz işçi puantajdan, manuel atama.
class ImalatScreen extends ConsumerWidget {
  const ImalatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final items = ref.watch(activeProductionProvider);
    final people = ref.watch(activePersonnelProvider);
    final attendance = ref.watch(attendanceProvider);
    final allProductions = ref.watch(productionProvider);

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
      ...YevmiyeCalculator.teamNames(people),
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
            : () => _openEditor(
                  context,
                  ref,
                  projectId: project.id,
                  teams: teams,
                ),
        icon: const Icon(Icons.add),
        label: const Text('İmalat Ekle'),
      ),
      body: items.isEmpty
          ? SJEmptyState(
              title: teams.isEmpty ? 'Önce ekip tanımlayın' : 'Henüz imalat yok',
              message: teams.isEmpty
                  ? 'Ayarlar → Ekipler / Personel’de ekip tanımlayın.'
                  : 'Aynı ekip günde birden fazla imalat yapabilir. '
                      'Usta ve düz işçi sayıları puantajdan gelir; '
                      'atamayı manuel yaparsınız.',
              icon: teams.isEmpty
                  ? Icons.groups_outlined
                  : Icons.precision_manufacturing_outlined,
              actionLabel: teams.isEmpty ? 'Personel' : 'İmalat Ekle',
              onAction: teams.isEmpty
                  ? () => context.go(AppRoutes.personel)
                  : () => _openEditor(
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
                final pool = ImalatCrewAllocator.availableFor(
                  projectId: project.id,
                  date: p.date,
                  teamName: p.teamName,
                  people: people,
                  attendance: attendance,
                  productions: allProductions,
                  excludeProductionId: p.id,
                );
                final pct = p.progressPct;
                final color = pct >= 80
                    ? AppColors.success
                    : pct >= 50
                        ? AppColors.warning
                        : AppColors.critical;
                return SJCard(
                  onTap: () => _openEditor(
                    context,
                    ref,
                    projectId: project.id,
                    teams: teams,
                    existing: p,
                  ),
                  child: Column(
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
                          Text(p.date, style: theme.textTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        p.teamName.isEmpty
                            ? 'Ekip seçilmedi'
                            : 'Ekip: ${p.teamName}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Atama: ${_fmt(p.ustaCount)} usta · '
                        '${_fmt(p.duzIsciCount)} düz işçi',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Puantaj kalan (diğerleri düşülmüş): '
                        '${_fmt(pool.ustaRemaining)} usta · '
                        '${_fmt(pool.duzRemaining)} düz',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmt(p.completedQty)} / ${_fmt(p.plannedQty)} ${p.unit}',
                        style: theme.textTheme.bodySmall,
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
                    ],
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

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    required List<String> teams,
    Production? existing,
  }) async {
    final people = ref.read(activePersonnelProvider);
    final attendance = ref.read(attendanceProvider);
    final productions = ref.read(productionProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ImalatEditorSheet(
        projectId: projectId,
        teams: teams,
        existing: existing,
        people: people,
        attendance: attendance,
        productions: productions,
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
}

class _ImalatEditorSheet extends StatefulWidget {
  const _ImalatEditorSheet({
    required this.projectId,
    required this.teams,
    required this.people,
    required this.attendance,
    required this.productions,
    required this.onSave,
    this.existing,
    this.onDelete,
  });

  final String projectId;
  final List<String> teams;
  final List<Person> people;
  final List<Attendance> attendance;
  final List<Production> productions;
  final Production? existing;
  final ValueChanged<Production> onSave;
  final VoidCallback? onDelete;

  @override
  State<_ImalatEditorSheet> createState() => _ImalatEditorSheetState();
}

class _ImalatEditorSheetState extends State<_ImalatEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _planned;
  late final TextEditingController _done;
  late final TextEditingController _note;
  late final TextEditingController _usta;
  late final TextEditingController _duz;
  late String _date;
  late String? _team;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _unit = TextEditingController(text: e?.unit ?? 'adet');
    _planned = TextEditingController(text: e == null ? '' : _num(e.plannedQty));
    _done = TextEditingController(text: e == null ? '' : _num(e.completedQty));
    _note = TextEditingController(text: e?.note ?? '');
    _usta = TextEditingController(text: e == null ? '' : _num(e.ustaCount));
    _duz = TextEditingController(text: e == null ? '' : _num(e.duzIsciCount));
    _date = e?.date ?? PuantajDate.today();
    final existingTeam = e?.teamName.trim() ?? '';
    _team = existingTeam.isNotEmpty && widget.teams.contains(existingTeam)
        ? existingTeam
        : (widget.teams.isNotEmpty ? widget.teams.first : null);

    // Yeni kayıtta kalan kapasiteyi öneri olarak yaz (manuel değiştirilebilir).
    if (e == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _suggestRemaining());
    }
  }

  void _suggestRemaining() {
    final pool = _pool;
    if (_usta.text.trim().isEmpty) {
      _usta.text = _num(pool.ustaRemaining);
    }
    if (_duz.text.trim().isEmpty) {
      _duz.text = _num(pool.duzRemaining);
    }
    setState(() {});
  }

  CrewPool get _pool {
    if (_team == null || _team!.isEmpty) {
      return const CrewPool(ustaTotal: 0, duzTotal: 0);
    }
    return ImalatCrewAllocator.availableFor(
      projectId: widget.projectId,
      date: _date,
      teamName: _team!,
      people: widget.people,
      attendance: widget.attendance,
      productions: widget.productions,
      excludeProductionId: widget.existing?.id,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _planned.dispose();
    _done.dispose();
    _note.dispose();
    _usta.dispose();
    _duz.dispose();
    super.dispose();
  }

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pool = _pool;

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
              widget.existing == null ? 'Yeni imalat' : 'İmalatı düzenle',
              style: theme.textTheme.titleLarge,
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
                for (final t in widget.teams)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) {
                setState(() => _team = v);
                _usta.clear();
                _duz.clear();
                _suggestRemaining();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: PuantajDate.parse(_date),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _date = PuantajDate.format(picked));
                  if (widget.existing == null) {
                    _usta.clear();
                    _duz.clear();
                    _suggestRemaining();
                  } else {
                    setState(() {});
                  }
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_date),
            ),
            const SizedBox(height: AppSpacing.sm),
            _CrewPoolBanner(pool: pool),
            const SizedBox(height: AppSpacing.sm),
            Text('Bu imalata atama (manuel)', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usta,
                    decoration: InputDecoration(
                      labelText: 'Usta',
                      helperText: 'Kalan ${_num(pool.ustaRemaining)}',
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
                      helperText: 'Kalan ${_num(pool.duzRemaining)}',
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
                label: const Text('Kalanı doldur'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _planned,
                    decoration: const InputDecoration(labelText: 'Plan'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _done,
                    decoration:
                        const InputDecoration(labelText: 'Gerçekleşen'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: 'Birim'),
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
                        date: _date,
                        teamName: team,
                        ustaCount: double.tryParse(_usta.text.trim()) ?? 0,
                        duzIsciCount: double.tryParse(_duz.text.trim()) ?? 0,
                        unit: _unit.text.trim().isEmpty
                            ? 'adet'
                            : _unit.text.trim(),
                        plannedQty:
                            double.tryParse(_planned.text.trim()) ?? 0,
                        completedQty:
                            double.tryParse(_done.text.trim()) ?? 0,
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
            'Kalan (öneri): ${_n(pool.ustaRemaining)} usta · '
            '${_n(pool.duzRemaining)} düz',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.electricBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sayılar bilgi amaçlıdır; atamayı siz girersiniz.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
