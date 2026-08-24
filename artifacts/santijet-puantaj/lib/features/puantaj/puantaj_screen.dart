import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../core/widgets/project_permission_gate.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/collaboration_provider.dart';
import '../../data/providers/uninsured_teams_provider.dart';
import '../../data/providers/yevmiyeli_is_provider.dart';
import '../../data/services/puantaj_export_service.dart';
import '../../data/services/puantaj_report_builder.dart';
import '../../domain/attendance/attendance_display.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/uninsured_team_entry.dart';
import '../../domain/entities/yevmiyeli_is_kaydi.dart';
import '../../domain/enums/attendance_status.dart';
import '../personnel/personnel_screen.dart';
import 'widgets/yevmiyeli_is_widgets.dart';

List<({String team, List<Person> users})> _teamsOf(List<Person> users) {
  final map = <String, List<Person>>{};
  for (final u in users) {
    final key = u.team.trim();
    map.putIfAbsent(key, () => []).add(u);
  }
  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a.isEmpty && b.isNotEmpty) return 1;
      if (a.isNotEmpty && b.isEmpty) return -1;
      return a.compareTo(b);
    });
  return keys
      .map((k) => (team: k.isEmpty ? 'Ekipsiz' : k, users: map[k]!))
      .toList();
}

enum _ViewMode { daily, weekly, monthly }

/// Ana puantaj ekranı — santiye-takip `puantaj.tsx` kurgusu.
///
/// Günlük giriş + toplu işlem / dünden kopyala + haftalık/aylık cetvel.
class PuantajScreen extends ConsumerStatefulWidget {
  const PuantajScreen({super.key});

  @override
  ConsumerState<PuantajScreen> createState() => _PuantajScreenState();
}

class _PuantajScreenState extends ConsumerState<PuantajScreen> {
  String _date = PuantajDate.today();
  _ViewMode _mode = _ViewMode.daily;
  String? _openDropdown;
  String? _openNote;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<({String company, List<Person> users})> _grouped(List<Person> people) {
    final map = <String, List<Person>>{};
    for (final u in people) {
      final key = u.company.trim();
      map.putIfAbsent(key, () => []).add(u);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty && b.isNotEmpty) return 1;
        if (a.isNotEmpty && b.isEmpty) return -1;
        return a.compareTo(b);
      });
    return keys
        .map((k) => (company: k.isEmpty ? 'Diğer' : k, users: map[k]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final attendance = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);
    final canEdit = ref.watch(canEditActiveProjectProvider);

    void denyWrite() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu işte yalnızca görüntüleme yetkiniz var'),
        ),
      );
    }

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Puantaj'),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'Puantaj tutmak için en az bir projeniz olmalı.',
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

    final rangeDays = PuantajDate.daysForReportPeriod(
      anchorDate: _date,
      daily: _mode == _ViewMode.daily,
      weekly: _mode == _ViewMode.weekly,
    );
    final allPersonnel = ref.watch(personnelProvider);
    final people = allPersonnel
        .where(
          (p) =>
              p.projectId == project.id &&
              p.wasEmployedInPeriod(rangeDays),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    AttendanceStatus? statusOf(String personId, String date) {
      Person? person;
      for (final p in allPersonnel) {
        if (p.id == personId) {
          person = p;
          break;
        }
      }
      AttendanceStatus? recorded;
      for (final a in attendance) {
        if (a.projectId == project.id &&
            a.personId == personId &&
            a.date == date) {
          recorded = a.status;
          break;
        }
      }
      return AttendanceDisplay.resolve(
        person: person,
        date: date,
        recorded: recorded,
      );
    }

    String? noteOf(String personId) {
      for (final a in attendance) {
        if (a.projectId == project.id &&
            a.personId == personId &&
            a.date == _date) {
          return a.note.isEmpty ? null : a.note;
        }
      }
      return null;
    }

    double overtimeOf(String personId) {
      for (final a in attendance) {
        if (a.projectId == project.id &&
            a.personId == personId &&
            a.date == _date) {
          return a.overtimeHours;
        }
      }
      return 0;
    }

    final missing = people.where((p) => statusOf(p.id, _date) == null).length;

    final counts = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values) s: 0,
    };
    var none = 0;
    for (final p in people) {
      final s = statusOf(p.id, _date);
      if (s == null) {
        none++;
      } else {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExportSheet(
          context,
          project: project,
          allProjectPeople: allPersonnel
              .where((p) => p.projectId == project.id)
              .toList(),
          attendance: attendance,
        ),
        icon: const Icon(Icons.ios_share_outlined),
        label: const Text('Puantaj AL'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Puantaj'),
            const ReadOnlyBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.afterHeader,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: AppRadii.md,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    for (final m in _ViewMode.values)
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _mode = m),
                          borderRadius: AppRadii.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _mode == m
                                  // Dışa aktarma dönem seçicisi ile aynı dolgu.
                                  ? theme.colorScheme.secondary
                                  : Colors.transparent,
                              borderRadius: AppRadii.md,
                            ),
                            child: Text(
                              switch (m) {
                                _ViewMode.daily => 'Günlük',
                                _ViewMode.weekly => 'Haftalık',
                                _ViewMode.monthly => 'Aylık',
                              },
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: _mode == m
                                    ? theme.colorScheme.onSecondary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_mode == _ViewMode.daily)
              Expanded(
                child: _DailyView(
                  date: _date,
                  onDateChanged: (d) => setState(() {
                    _date = d;
                    _openDropdown = null;
                    _openNote = null;
                  }),
                  people: people,
                  grouped: _grouped(people),
                  missing: missing,
                  counts: counts,
                  none: none,
                  statusOf: (id) => statusOf(id, _date),
                  noteOf: noteOf,
                  overtimeOf: overtimeOf,
                  openDropdown: _openDropdown,
                  openNote: _openNote,
                  noteController: _noteController,
                  onToggleDropdown: (id) => setState(() {
                    _openDropdown = _openDropdown == id ? null : id;
                    _openNote = null;
                  }),
                  onOpenNote: (person) {
                    _noteController.text = noteOf(person.id) ?? '';
                    setState(() {
                      _openNote = person.id;
                      _openDropdown = null;
                    });
                  },
                  onCloseNote: () => setState(() => _openNote = null),
                  onSaveNote: (person) {
                    if (!canEdit) return denyWrite();
                    notifier.setNote(
                      projectId: project.id,
                      person: person,
                      date: _date,
                      note: _noteController.text,
                    );
                    setState(() => _openNote = null);
                  },
                  onSetStatus: (person, status) {
                    if (!canEdit) return denyWrite();
                    if (!person.isActiveOn(_date)) return;
                    notifier.setStatus(
                      projectId: project.id,
                      person: person,
                      date: _date,
                      status: status,
                    );
                    setState(() => _openDropdown = null);
                  },
                  onSetOvertime: (person, hours) {
                    if (!canEdit) return denyWrite();
                    if (!person.isActiveOn(_date)) return;
                    notifier.setOvertime(
                      projectId: project.id,
                      person: person,
                      date: _date,
                      overtimeHours: hours,
                    );
                  },
                  onBulk: (status) {
                    if (!canEdit) return denyWrite();
                    final eligible =
                        people.where((p) => p.isActiveOn(_date)).toList();
                    notifier.bulkSetStatus(
                      projectId: project.id,
                      people: eligible,
                      date: _date,
                      status: status,
                    );
                  },
                  onCopyYesterday: () {
                    if (!canEdit) return denyWrite();
                    final eligible =
                        people.where((p) => p.isActiveOn(_date)).toList();
                    final copied = notifier.copyFromPreviousDay(
                      projectId: project.id,
                      people: eligible,
                      date: _date,
                      previousDate: PuantajDate.shift(_date, -1),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          copied == 0
                              ? 'Önceki gün için kayıt bulunamadı.'
                              : '$copied kayıt kopyalandı.',
                        ),
                      ),
                    );
                  },
                  onPersonTap: (person) => openPersonEditor(
                    context,
                    ref,
                    projectId: project.id,
                    existing: person,
                  ),
                ),
              )
            else
              Expanded(
                child: _CetvelView(
                  mode: _mode,
                  date: _date,
                  onPrev: () => setState(() {
                    if (_mode == _ViewMode.weekly) {
                      _date = PuantajDate.shift(_date, -7);
                    } else {
                      final d = PuantajDate.parse(_date);
                      _date =
                          PuantajDate.format(DateTime(d.year, d.month - 1, 1));
                    }
                  }),
                  onNext: () => setState(() {
                    if (_mode == _ViewMode.weekly) {
                      _date = PuantajDate.shift(_date, 7);
                    } else {
                      final d = PuantajDate.parse(_date);
                      _date =
                          PuantajDate.format(DateTime(d.year, d.month + 1, 1));
                    }
                  }),
                  people: people,
                  grouped: _grouped(people),
                  statusOf: statusOf,
                  onPersonTap: (person) => openPersonEditor(
                    context,
                    ref,
                    projectId: project.id,
                    existing: person,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExportSheet(
    BuildContext context, {
    required Project project,
    required List<Person> allProjectPeople,
    required List<Attendance> attendance,
  }) {
    final initial = switch (_mode) {
      _ViewMode.daily => PuantajReportPeriod.daily,
      _ViewMode.weekly => PuantajReportPeriod.weekly,
      _ViewMode.monthly => PuantajReportPeriod.monthly,
    };
    final uninsured = ref
        .read(uninsuredTeamsProvider)
        .where((e) => e.projectId == project.id)
        .toList();
    final yevmiyeli = ref
        .read(yevmiyeliIsProvider)
        .where((e) => e.projectId == project.id)
        .toList();
    return SJModal.showSheet(
      context: context,
      title: 'Puantaj AL',
      child: _PuantajExportSheet(
        project: project,
        allProjectPeople: allProjectPeople,
        attendance: attendance,
        uninsuredTeams: uninsured,
        yevmiyeliEntries: yevmiyeli,
        anchorDate: _date,
        initialPeriod: initial,
      ),
    );
  }
}

class _DailyView extends StatefulWidget {
  const _DailyView({
    required this.date,
    required this.onDateChanged,
    required this.people,
    required this.grouped,
    required this.missing,
    required this.counts,
    required this.none,
    required this.statusOf,
    required this.noteOf,
    required this.overtimeOf,
    required this.openDropdown,
    required this.openNote,
    required this.noteController,
    required this.onToggleDropdown,
    required this.onOpenNote,
    required this.onCloseNote,
    required this.onSaveNote,
    required this.onSetStatus,
    required this.onSetOvertime,
    required this.onBulk,
    required this.onCopyYesterday,
    required this.onPersonTap,
  });

  final String date;
  final ValueChanged<String> onDateChanged;
  final List<Person> people;
  final List<({String company, List<Person> users})> grouped;
  final int missing;
  final Map<AttendanceStatus, int> counts;
  final int none;
  final AttendanceStatus? Function(String personId) statusOf;
  final String? Function(String personId) noteOf;
  final double Function(String personId) overtimeOf;
  final String? openDropdown;
  final String? openNote;
  final TextEditingController noteController;
  final ValueChanged<String> onToggleDropdown;
  final ValueChanged<Person> onOpenNote;
  final VoidCallback onCloseNote;
  final ValueChanged<Person> onSaveNote;
  final void Function(Person, AttendanceStatus) onSetStatus;
  final void Function(Person, double) onSetOvertime;
  final ValueChanged<AttendanceStatus> onBulk;
  final VoidCallback onCopyYesterday;
  final ValueChanged<Person> onPersonTap;

  @override
  State<_DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<_DailyView> {
  bool _l1Personel = false;
  bool _l1Ekip = false;
  final Map<String, bool> _l2Companies = {};
  final Map<String, bool> _l3Teams = {};

  @override
  void didUpdateWidget(covariant _DailyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _l1Personel = false;
      _l1Ekip = false;
      _l2Companies.clear();
      _l3Teams.clear();
    }
  }

  String _teamKey(String company, String team) => '$company|$team';

  bool _companyExpanded(String company) => _l2Companies[company] ?? false;

  bool _teamExpanded(String company, String team) =>
      _l3Teams[_teamKey(company, team)] ?? false;

  /// 0 kapalı · 1 firma · 2 ekip · 3 personel.
  int _kirilimDepth() {
    if (!_l1Personel && !_l1Ekip) return 0;
    final companies = widget.grouped.map((g) => g.company).toList();
    if (companies.isEmpty) return 1;
    final allL2 = companies.every((c) => _l2Companies[c] ?? false);
    if (!allL2) return 1;
    final keys = <String>[];
    for (final g in widget.grouped) {
      for (final t in _teamsOf(g.users)) {
        keys.add(_teamKey(g.company, t.team));
      }
    }
    if (keys.isEmpty) return 2;
    final allL3 = keys.every((k) => _l3Teams[k] ?? false);
    return allL3 ? 3 : 2;
  }

  void _setKirilimDepth(int depth) {
    final companies = widget.grouped.map((g) => g.company).toList();
    final keys = <String>[];
    for (final g in widget.grouped) {
      for (final t in _teamsOf(g.users)) {
        keys.add(_teamKey(g.company, t.team));
      }
    }
    setState(() {
      _l1Personel = depth >= 1;
      _l1Ekip = depth >= 1;
      for (final c in companies) {
        _l2Companies[c] = depth >= 2;
      }
      for (final k in keys) {
        _l3Teams[k] = depth >= 3;
      }
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final initial = PuantajDate.parse(widget.date);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) widget.onDateChanged(PuantajDate.format(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = widget.date == PuantajDate.today();
    final people = widget.people;
    final grouped = widget.grouped;
    final date = widget.date;
    final missing = widget.missing;
    final counts = widget.counts;
    final none = widget.none;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  widget.onDateChanged(PuantajDate.shift(date, -1)),
              visualDensity: VisualDensity.compact,
              tooltip: 'Önceki gün',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context),
                borderRadius: AppRadii.md,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isToday)
                        Text(
                          'Bugün',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.electricBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      Text(
                        PuantajDate.withDayName(date),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () =>
                  widget.onDateChanged(PuantajDate.shift(date, 1)),
              visualDensity: VisualDensity.compact,
              tooltip: 'Sonraki gün',
              icon: const Icon(Icons.chevron_right),
            ),
            if (people.isNotEmpty)
              Tooltip(
                message: 'Dünden kopyala',
                child: OutlinedButton.icon(
                  onPressed: widget.onCopyYesterday,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('Dünden'),
                ),
              ),
          ],
        ),
        if (people.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _PuantajKirilimBar(
            depth: _kirilimDepth(),
            maxDepth: 1,
            onDepthChanged: _setKirilimDepth,
          ),
          _ExpandableSection(
            leadingBar: true,
            expanded: _l1Personel,
            onExpandedChanged: (v) => setState(() => _l1Personel = v),
            title: Text(
              'Personel',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              const SizedBox(height: AppSpacing.sm),
              SJEmptyState(
                title: 'Kayıtlı personel yok',
                message: 'Personel yönetiminden ekip üyesi ekleyin. '
                    'Ekip başlığı altından çalışan sayısı girebilirsiniz.',
                icon: Icons.groups_outlined,
                actionLabel: 'Personel',
                onAction: () => context.push(AppRoutes.personel),
              ),
            ],
          ),
          _DayTeamsSection(
            date: date,
            expanded: _l1Ekip,
            onExpandedChanged: (v) => setState(() => _l1Ekip = v),
          ),
          const SizedBox(height: AppSpacing.md),
          DayYevmiyeliSection(
            date: date,
            people: widget.people,
          ),
        ] else ...[
        if (missing > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: AppRadii.sm,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: AppColors.statusInkOnChrome(AppColors.warning),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '$missing personelin puantajı girilmedi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.statusInkOnChrome(AppColors.warning),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in AttendanceStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _SumChip(
                    count: counts[s] ?? 0,
                    label: s.short,
                    fullLabel: s.label,
                    color: s.color,
                  ),
                ),
              _SumChip(
                count: people.length,
                label: 'Top',
                fullLabel: 'Toplam',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              if (none > 0)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: _SumChip(
                    count: none,
                    label: '–',
                    fullLabel: 'Girilmedi',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onBulk(AttendanceStatus.present),
                icon: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.statusInkOnChrome(
                    AttendanceStatus.present.color,
                  ),
                ),
                label: Text(
                  'Tümünü Mevcut',
                  style: TextStyle(
                    color: AppColors.statusInkOnChrome(
                      AttendanceStatus.present.color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onBulk(AttendanceStatus.absent),
                icon: Icon(
                  Icons.cancel,
                  size: 16,
                  color: AppColors.statusInkOnChrome(
                    AttendanceStatus.absent.color,
                  ),
                ),
                label: Text(
                  'Tümünü Yok',
                  style: TextStyle(
                    color: AppColors.statusInkOnChrome(
                      AttendanceStatus.absent.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _PuantajKirilimBar(
          depth: _kirilimDepth(),
          maxDepth: 3,
          onDepthChanged: _setKirilimDepth,
        ),
        _ExpandableSection(
          leadingBar: true,
          expanded: _l1Personel,
          onExpandedChanged: (v) => setState(() => _l1Personel = v),
          title: Text(
            'Personel',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Text(
            '${people.length} personel',
            style: theme.textTheme.labelSmall,
          ),
          children: [
            for (final group in grouped)
              _ExpandableSection(
                indent: AppSpacing.sm,
                expanded: _companyExpanded(group.company),
                onExpandedChanged: (v) => setState(
                  () => _l2Companies[group.company] = v,
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        group.company,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Sigorta ettiren firma',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Text(
                  '${group.users.length} personel',
                  style: theme.textTheme.labelSmall,
                ),
                children: [
                  for (final teamGroup in _teamsOf(group.users))
                    _ExpandableSection(
                      indent: AppSpacing.md,
                      expanded: _teamExpanded(group.company, teamGroup.team),
                      onExpandedChanged: (v) => setState(
                        () => _l3Teams[_teamKey(group.company, teamGroup.team)] =
                            v,
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              teamGroup.team,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Ekip',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '${teamGroup.users.length} personel',
                        style: theme.textTheme.labelSmall,
                      ),
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        for (final person in teamGroup.users)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Consumer(
                              builder: (context, ref, _) {
                                final project =
                                    ref.watch(activeProjectProvider);
                                final entries = ref.watch(yevmiyeliIsProvider);
                                final personEntries = project == null
                                    ? const <YevmiyeliIsKaydi>[]
                                    : entries
                                        .where(
                                          (e) =>
                                              e.projectId == project.id &&
                                              e.date == date &&
                                              e.personId == person.id,
                                        )
                                        .toList();
                                final yvTotal = personEntries.fold<double>(
                                  0,
                                  (s, e) => s + e.yevmiyeCount,
                                );
                                return _PersonCard(
                                  person: person,
                                  status: widget.statusOf(person.id),
                                  note: widget.noteOf(person.id),
                                  overtimeHours: widget.overtimeOf(person.id),
                                  dropdownOpen:
                                      widget.openDropdown == person.id,
                                  noteOpen: widget.openNote == person.id,
                                  noteController: widget.noteController,
                                  yevmiyeIsTotal: yvTotal,
                                  onYevmiyeliTap: project == null
                                      ? null
                                      : () => openYevmiyeliIsEditor(
                                            context,
                                            ref,
                                            projectId: project.id,
                                            date: date,
                                            people: widget.people,
                                            initialPerson: person,
                                            existing: personEntries.length == 1
                                                ? personEntries.first
                                                : null,
                                          ),
                                  onToggleDropdown: () =>
                                      widget.onToggleDropdown(person.id),
                                  onOpenNote: () => widget.onOpenNote(person),
                                  onCloseNote: widget.onCloseNote,
                                  onSaveNote: () => widget.onSaveNote(person),
                                  onSetStatus: (s) =>
                                      widget.onSetStatus(person, s),
                                  onSetOvertime: (h) =>
                                      widget.onSetOvertime(person, h),
                                  onPersonTap: () =>
                                      widget.onPersonTap(person),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              ),
          ],
        ),
        _DayTeamsSection(
          date: date,
          expanded: _l1Ekip,
          onExpandedChanged: (v) => setState(() => _l1Ekip = v),
        ),
        const SizedBox(height: AppSpacing.md),
        DayYevmiyeliSection(
          date: date,
          people: widget.people,
        ),
        ],
      ],
    );
  }
}


/// Açılır/kapanır bölüm başlığı — günlük puantaj hiyerarşisi.
class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    this.leadingBar = false,
    this.indent = 0,
    this.expanded,
    this.onExpandedChanged,
    this.initiallyExpanded = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final bool leadingBar;
  final double indent;
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _internalExpanded = widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _internalExpanded;

  void _toggle() {
    if (widget.expanded != null && widget.onExpandedChanged != null) {
      widget.onExpandedChanged!(!widget.expanded!);
    } else {
      setState(() => _internalExpanded = !_internalExpanded);
    }
  }

  @override
  void didUpdateWidget(covariant _ExpandableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == null &&
        oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _internalExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: AppRadii.sm,
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.indent,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.leadingBar) ...[
                  Container(
                    width: 3,
                    height: 16,
                    margin: const EdgeInsets.only(top: 2),
                    color: AppColors.electricBlue,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.title,
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        widget.subtitle!,
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: widget.trailing!,
                  ),
                ],
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...widget.children,
      ],
    );
  }
}

/// Liste derinliği — Kapalı · Firma · Ekip · Personel (Günlük sekmesi düzeni).
class _PuantajKirilimBar extends StatelessWidget {
  const _PuantajKirilimBar({
    required this.depth,
    required this.maxDepth,
    required this.onDepthChanged,
  });

  final int depth;
  final int maxDepth;
  final ValueChanged<int> onDepthChanged;

  static const _labels = ['Kapalı', 'Firma', 'Ekip', 'Personel'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Liste görünümü',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadii.md,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: _KirilimDepthSegment(
                      label: _labels[i],
                      selected: depth == i,
                      enabled: i <= maxDepth,
                      onTap: () => onDepthChanged(i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KirilimDepthSegment extends StatelessWidget {
  const _KirilimDepthSegment({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = enabled
        ? (selected
            ? theme.colorScheme.onSecondary
            : theme.colorScheme.onSurfaceVariant)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadii.md,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected && enabled ? theme.colorScheme.secondary : null,
          borderRadius: AppRadii.md,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: fg,
            fontWeight: selected && enabled ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Günlük ekip — katalogdan ekip adı + çalışan sayısı (personel adı yok).
class _DayTeamsSection extends ConsumerWidget {
  const _DayTeamsSection({
    required this.date,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final String date;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    required List<String> catalogTeams,
    required Set<String> usedTeamNames,
    UninsuredTeamEntry? existing,
  }) async {
    final available = <String>{
      ...catalogTeams,
      if (existing != null && existing.teamName.trim().isNotEmpty)
        existing.teamName,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectable = available
        .where(
          (t) =>
              existing?.teamName == t ||
              !usedTeamNames.contains(t),
        )
        .toList();

    if (selectable.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            catalogTeams.isEmpty
                ? 'Önce Ayarlar → Ekipler’den ekip tanımlayın.'
                : 'Bu gün için seçilebilecek ekip kalmadı.',
          ),
          action: catalogTeams.isEmpty
              ? SnackBarAction(
                  label: 'Ekipler',
                  onPressed: () => context.push(AppRoutes.ekipler),
                )
              : null,
        ),
      );
      return;
    }

    String? selectedTeam = existing?.teamName;
    if (selectedTeam == null || !selectable.contains(selectedTeam)) {
      selectedTeam = selectable.first;
    }
    final countCtrl = TextEditingController(
      text: existing == null ? '' : '${existing.workerCount}',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Ekip ekle' : 'Ekibi düzenle',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ayarlar’daki ekiplerden seçin; çalışan sayısını girin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedTeam,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ekip *'),
                  items: [
                    for (final t in selectable)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setModalState(() => selectedTeam = v);
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ekip seçin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Çalışan sayısı *',
                    hintText: 'Örn. 8',
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return '1 veya daha fazla girin';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SJButton(
                  label: existing == null ? 'Ekle' : 'Kaydet',
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );

    final teamName = selectedTeam;
    final countText = countCtrl.text;
    countCtrl.dispose();
    if (saved != true || teamName == null || teamName.trim().isEmpty) return;

    final count = int.tryParse(countText.trim()) ?? 0;
    final notifier = ref.read(uninsuredTeamsProvider.notifier);
    if (existing != null) {
      notifier.upsert(
        existing.copyWith(teamName: teamName, workerCount: count),
      );
    } else {
      notifier.add(
        projectId: projectId,
        date: date,
        teamName: teamName,
        workerCount: count,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    if (project == null) return const SizedBox.shrink();

    final canEdit = ref.watch(canEditActiveProjectProvider);
    final catalogTeams = ref.watch(teamsProvider);
    final entries = ref
        .watch(uninsuredTeamsProvider)
        .where((e) => e.projectId == project.id && e.date == date)
        .toList()
      ..sort((a, b) => a.teamName.compareTo(b.teamName));
    final usedTeamNames = entries.map((e) => e.teamName).toSet();
    final totalWorkers =
        entries.fold<int>(0, (sum, e) => sum + e.workerCount);

    void denyWrite() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu işte yalnızca görüntüleme yetkiniz var'),
        ),
      );
    }

    final bodyChildren = <Widget>[
        if (entries.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            catalogTeams.isEmpty
                ? 'Ayarlar → Ekipler’de ekip tanımlayın; ardından çalışan sayısı ekleyin.'
                : 'Açılır listeden ekip seçip çalışan sayısı girin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (catalogTeams.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.ekipler),
                child: const Text('Ekiplere git'),
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SJCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.teamName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.workerCount} çalışan',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Düzenle',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (!canEdit) return denyWrite();
                        _openEditor(
                          context,
                          ref,
                          projectId: project.id,
                          catalogTeams: catalogTeams,
                          usedTeamNames: usedTeamNames,
                          existing: entry,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Sil',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        if (!canEdit) return denyWrite();
                        final ok = await SJModal.confirm(
                          context: context,
                          title: 'Ekibi sil',
                          message:
                              '${entry.teamName} (${entry.workerCount} çalışan) silinsin mi?',
                          confirmLabel: 'Sil',
                          destructive: true,
                        );
                        if (!ok) return;
                        ref
                            .read(uninsuredTeamsProvider.notifier)
                            .remove(entry.id);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        _ExpandableSection(
          leadingBar: true,
          expanded: expanded,
          onExpandedChanged: onExpandedChanged,
          title: Text(
            'Ekip',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entries.isNotEmpty)
                Text(
                  '$totalWorkers personel',
                  style: theme.textTheme.labelSmall,
                ),
              const SizedBox(width: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: () {
                  if (!canEdit) return denyWrite();
                  _openEditor(
                    context,
                    ref,
                    projectId: project.id,
                    catalogTeams: catalogTeams,
                    usedTeamNames: usedTeamNames,
                  );
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Ekip ekle'),
              ),
            ],
          ),
          children: bodyChildren,
        ),
      ],
    );
  }
}

class _SumChip extends StatefulWidget {
  const _SumChip({
    required this.count,
    required this.label,
    required this.color,
    this.fullLabel,
  });

  final int count;
  final String label;
  final String? fullLabel;
  final Color color;

  @override
  State<_SumChip> createState() => _SumChipState();
}

class _SumChipState extends State<_SumChip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final text = _expanded && widget.fullLabel != null
        ? widget.fullLabel!
        : widget.label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.fullLabel == null
            ? null
            : () => setState(() => _expanded = !_expanded),
        borderRadius: AppRadii.sm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: _expanded ? 0.2 : 0.12),
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: color.withValues(alpha: _expanded ? 0.55 : 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.count}',
                style: TextStyle(
                  color: AppColors.statusInkOnChrome(color),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: AppColors.statusInkOnChrome(color),
                  fontSize: 11,
                  fontWeight: _expanded ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.status,
    required this.note,
    required this.overtimeHours,
    required this.dropdownOpen,
    required this.noteOpen,
    required this.noteController,
    required this.onToggleDropdown,
    required this.onOpenNote,
    required this.onCloseNote,
    required this.onSaveNote,
    required this.onSetStatus,
    required this.onSetOvertime,
    required this.onPersonTap,
    this.yevmiyeIsTotal = 0,
    this.onYevmiyeliTap,
  });

  final Person person;
  final AttendanceStatus? status;
  final String? note;
  final double overtimeHours;
  final bool dropdownOpen;
  final bool noteOpen;
  final TextEditingController noteController;
  final VoidCallback onToggleDropdown;
  final VoidCallback onOpenNote;
  final VoidCallback onCloseNote;
  final VoidCallback onSaveNote;
  final ValueChanged<AttendanceStatus> onSetStatus;
  final ValueChanged<double> onSetOvertime;
  final VoidCallback onPersonTap;
  final double yevmiyeIsTotal;
  final VoidCallback? onYevmiyeliTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (person.team.trim().isNotEmpty) titleCaseTr(person.team),
      if (person.profession.trim().isNotEmpty) titleCaseTr(person.profession),
    ].join(' · ');
    final worked = status?.isWorkedDay ?? false;
    final baseHours = status?.hours ?? 0;
    final yevmiye = worked ? (baseHours + overtimeHours) / 8.0 : 0.0;

    return SJCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final statusColor =
              status?.color ?? theme.colorScheme.onSurfaceVariant;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onPersonTap,
                      borderRadius: AppRadii.sm,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleCaseTr(person.name),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    theme.colorScheme.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            for (final line
                                in AttendanceDisplay.employmentDateLines(
                                    person))
                              Text(
                                line,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (meta.isNotEmpty)
                              Text(meta, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: noteOpen ? onCloseNote : onOpenNote,
                    icon: Icon(
                      Icons.edit_note,
                      color: note != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  InkWell(
                    onTap: onToggleDropdown,
                    borderRadius: AppRadii.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: AppRadii.sm,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status?.label ?? 'Seçilmedi',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.statusInkOnCard(statusColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            dropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.statusInkOnCard(statusColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (worked) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Spacer(),
                    Text('Mesai', style: theme.textTheme.labelMedium),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: overtimeHours <= 0
                          ? null
                          : () => onSetOvertime(
                                (overtimeHours - 0.5).clamp(0, 12),
                              ),
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                    ),
                    Text(
                      overtimeHours == overtimeHours.roundToDouble()
                          ? '${overtimeHours.toStringAsFixed(0)} sa'
                          : '${overtimeHours.toStringAsFixed(1)} sa',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: overtimeHours >= 12
                          ? null
                          : () => onSetOvertime(
                                (overtimeHours + 0.5).clamp(0, 12),
                              ),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${yevmiye.toStringAsFixed(yevmiye == yevmiye.roundToDouble() ? 0 : 2)} yv',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.electricBlueLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (onYevmiyeliTap != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onYevmiyeliTap,
                    icon: Icon(
                      yevmiyeIsTotal > 0
                          ? Icons.handyman
                          : Icons.handyman_outlined,
                      size: 16,
                    ),
                    label: Text(
                      yevmiyeIsTotal > 0
                          ? 'Yevmiye iş · ${formatYevmiyeCount(yevmiyeIsTotal)} yv'
                          : 'Yevmiyeli iş',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.electricBlue,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
              if (note != null && !noteOpen) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(note!, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ],
              if (noteOpen) ...[
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Not ekle...',
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onSaveNote,
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
              if (dropdownOpen) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final s in AttendanceStatus.values)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      s.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.statusInkOnCard(s.color),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: status == s
                        ? Icon(
                            Icons.check,
                            color: AppColors.statusInkOnCard(s.color),
                            size: 18,
                          )
                        : null,
                    selected: status == s,
                    onTap: () => onSetStatus(s),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CetvelView extends StatelessWidget {
  const _CetvelView({
    required this.mode,
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.people,
    required this.grouped,
    required this.statusOf,
    required this.onPersonTap,
  });

  final _ViewMode mode;
  final String date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final List<Person> people;
  final List<({String company, List<Person> users})> grouped;
  final AttendanceStatus? Function(String personId, String date) statusOf;
  final ValueChanged<Person> onPersonTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = mode == _ViewMode.weekly
        ? PuantajDate.weekDays(date)
        : PuantajDate.monthDays(date);
    final label = mode == _ViewMode.weekly
        ? PuantajDate.weekLabel(days)
        : PuantajDate.monthLabel(date);
    final cellW = mode == _ViewMode.weekly ? 36.0 : 26.0;
    const nameW = 88.0;
    const summaryW = 48.0;
    const totalW = 56.0;
    final tableW = nameW +
        days.length * cellW +
        AttendanceStatus.values.length * summaryW +
        totalW;
    final today = PuantajDate.today();

    if (people.isEmpty) {
      return const SJEmptyState(
        title: 'Kayıtlı personel yok',
        message: 'Personel yönetiminden ekip üyesi ekleyin.',
        icon: Icons.groups_outlined,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        PeriodYevmiyeliSummary(dates: days),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in AttendanceStatus.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: AppRadii.xs,
                      ),
                      child: Text(
                        s.short,
                        style: TextStyle(
                          color: AppColors.readableOn(s.color),
                          fontSize: s.short.length > 1 ? 8 : 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(s.label, style: theme.textTheme.labelSmall),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cetvelHeader(
                    theme,
                    days,
                    cellW,
                    nameW,
                    summaryW,
                    totalW,
                    today,
                  ),
                  for (final group in grouped)
                    _ExpandableSection(
                      title: SizedBox(
                        width: tableW,
                        child: Text(
                          group.company,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.statusInkOnChrome(
                              AppColors.useDarkChrome
                                  ? AppColors.electricBlueLight
                                  : AppColors.electricBlue,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        'Sigorta ettiren firma',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '${group.users.length} personel',
                        style: theme.textTheme.labelSmall,
                      ),
                      children: [
                        for (final teamGroup in _teamsOf(group.users))
                          _ExpandableSection(
                            indent: AppSpacing.sm,
                            title: Text(
                              teamGroup.team,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Ekip',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Text(
                              '${teamGroup.users.length} personel',
                              style: theme.textTheme.labelSmall,
                            ),
                            children: [
                              for (final person in teamGroup.users)
                                _cetvelRow(
                                  theme,
                                  person,
                                  days,
                                  cellW,
                                  nameW,
                                  summaryW,
                                  totalW,
                                  statusOf,
                                  onPersonTap,
                                ),
                            ],
                          ),
                      ],
                    ),
                  _totalsFooter(
                    theme,
                    people,
                    days,
                    cellW,
                    nameW,
                    summaryW,
                    totalW,
                    statusOf,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cetvelHeader(
    ThemeData theme,
    List<String> days,
    double cellW,
    double nameW,
    double summaryW,
    double totalW,
    String today,
  ) {
    return Row(
      children: [
        SizedBox(
          width: nameW,
          child: Text('Personel', style: theme.textTheme.labelSmall),
        ),
        for (var i = 0; i < days.length; i++)
          SizedBox(
            width: cellW,
            child: Text(
              mode == _ViewMode.weekly
                  ? '${PuantajDate.trDaysShort[i]}\n${days[i].split('.').first}'
                  : days[i].split('.').first,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: days[i] == today
                    ? AppColors.electricBlue
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    days[i] == today ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        for (final s in AttendanceStatus.values)
          SizedBox(
            width: summaryW,
            child: Text(
              switch (s) {
                AttendanceStatus.present => 'Mevcut',
                AttendanceStatus.half => 'Yarım',
                AttendanceStatus.giris => 'Giriş',
                AttendanceStatus.cikis => 'Çıkış',
                AttendanceStatus.izinli => 'İzinli',
                AttendanceStatus.raporlu => 'Raporlu',
                AttendanceStatus.mazeret => 'Mazeret',
                AttendanceStatus.tatil => 'Resmi\nTatil',
                AttendanceStatus.haftaTatili => 'Hafta\nTatili',
                AttendanceStatus.absent => 'Yok',
              },
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.statusInkOnChrome(s.color),
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
        SizedBox(
          width: totalW,
          child: Text(
            'Genel\nToplam',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  Widget _cetvelRow(
    ThemeData theme,
    Person person,
    List<String> days,
    double cellW,
    double nameW,
    double summaryW,
    double totalW,
    AttendanceStatus? Function(String, String) statusOf,
    ValueChanged<Person> onPersonTap,
  ) {
    final statuses = [for (final d in days) statusOf(person.id, d)];
    final statusCounts = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values)
        s: statuses.where((value) => value == s).length,
    };
    final generalTotal = AttendanceStatus.values
        .where((s) => s.countsInGeneralTotal)
        .fold<int>(0, (sum, s) => sum + (statusCounts[s] ?? 0));
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: nameW,
            child: InkWell(
              onTap: () => onPersonTap(person),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleCaseTr(person.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            theme.colorScheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    for (final line
                        in AttendanceDisplay.employmentDateLines(person))
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          for (final s in statuses)
            SizedBox(
              width: cellW,
              child: Center(
                child: Container(
                  width: cellW - 6,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s?.color ?? theme.dividerColor,
                    borderRadius: AppRadii.xs,
                  ),
                  child: Text(
                    s?.short ?? '–',
                    style: TextStyle(
                      color: s != null
                          ? AppColors.readableOn(s.color)
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: (s?.short.length ?? 0) > 1 ? 8 : 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          for (final s in AttendanceStatus.values)            SizedBox(
              width: summaryW,
              child: Text(
                '${statusCounts[s] ?? 0}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.statusInkOnChrome(s.color),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          SizedBox(
            width: totalW,
            child: Text(
              generalTotal > 0 ? '$generalTotal' : '–',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: generalTotal > 0
                    ? AppColors.statusInkOnChrome(
                        AttendanceStatus.present.color,
                      )
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsFooter(
    ThemeData theme,
    List<Person> people,
    List<String> days,
    double cellW,
    double nameW,
    double summaryW,
    double totalW,
    AttendanceStatus? Function(String, String) statusOf,
  ) {
    final allStatuses = [
      for (final p in people)
        for (final d in days) statusOf(p.id, d),
    ];
    final statusTotals = <AttendanceStatus, int>{
      for (final s in AttendanceStatus.values)
        s: allStatuses.where((value) => value == s).length,
    };
    final generalTotal = AttendanceStatus.values
        .where((s) => s.countsInGeneralTotal)
        .fold<int>(0, (sum, s) => sum + (statusTotals[s] ?? 0));
    return Row(
      children: [
        SizedBox(
          width: nameW,
          child: Text(
            'Toplam',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final d in days)
          SizedBox(
            width: cellW,
            child: Text(
              () {
                final c = people.where((p) {
                  final s = statusOf(p.id, d);
                  return s?.isWorkedDay ?? false;
                }).length;
                return c > 0 ? '$c' : '–';
              }(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.statusInkOnChrome(
                  AttendanceStatus.present.color,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        for (final s in AttendanceStatus.values)
          SizedBox(
            width: summaryW,
            child: Text(
              '${statusTotals[s] ?? 0}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.statusInkOnChrome(s.color),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        SizedBox(
          width: totalW,
          child: Text(
            '$generalTotal',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.statusInkOnChrome(
                AttendanceStatus.present.color,
              ),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PuantajExportSheet extends StatefulWidget {
  const _PuantajExportSheet({
    required this.project,
    required this.allProjectPeople,
    required this.attendance,
    required this.uninsuredTeams,
    required this.yevmiyeliEntries,
    required this.anchorDate,
    required this.initialPeriod,
  });

  final Project project;
  final List<Person> allProjectPeople;
  final List<Attendance> attendance;
  final List<UninsuredTeamEntry> uninsuredTeams;
  final List<YevmiyeliIsKaydi> yevmiyeliEntries;
  final String anchorDate;
  final PuantajReportPeriod initialPeriod;

  @override
  State<_PuantajExportSheet> createState() => _PuantajExportSheetState();
}

class _PuantajExportSheetState extends State<_PuantajExportSheet> {
  late PuantajReportPeriod _period = widget.initialPeriod;
  late PuantajExportLayout _layout = PuantajExportLayout.isim;
  late Set<String> _selectedPersonIds;
  final _personSearchController = TextEditingController();
  final _teamSearchController = TextEditingController();
  final _peopleTileController = ExpansionTileController();
  final _teamsTileController = ExpansionTileController();
  String _personQuery = '';
  String _teamQuery = '';
  bool _busy = false;
  String? _error;

  static const _noTeamKey = '__no_team__';

  @override
  void initState() {
    super.initState();
    _selectedPersonIds = _eligiblePeople.map((p) => p.id).toSet();
  }

  @override
  void dispose() {
    _personSearchController.dispose();
    _teamSearchController.dispose();
    super.dispose();
  }

  List<String> get _periodDays => PuantajDate.daysForReportPeriod(
        anchorDate: widget.anchorDate,
        daily: _period == PuantajReportPeriod.daily,
        weekly: _period == PuantajReportPeriod.weekly,
      );

  /// PDF/Excel ile ekran aynı kural:
  /// günlük/haftalık → çıkış gününe kadar; aylık → çıkış yaptığı ay.
  List<Person> get _eligiblePeople {
    final list = widget.allProjectPeople
        .where((p) => p.wasEmployedInPeriod(_periodDays))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  String _teamKeyOf(Person p) {
    final t = p.team.trim();
    return t.isEmpty ? _noTeamKey : t;
  }

  String _teamLabel(String key) =>
      key == _noTeamKey ? 'Ekipsiz' : titleCaseTr(key);

  /// Dönemdeki uygun personelden türetilen ekip listesi.
  List<String> get _eligibleTeams {
    final keys = <String>{};
    for (final p in _eligiblePeople) {
      keys.add(_teamKeyOf(p));
    }
    final list = keys.toList()
      ..sort((a, b) {
        if (a == _noTeamKey) return 1;
        if (b == _noTeamKey) return -1;
        return a.compareTo(b);
      });
    return list;
  }

  List<String> get _filteredEligibleTeams {
    final q = _foldTr(_teamQuery.trim());
    if (q.isEmpty) return _eligibleTeams;
    return _eligibleTeams.where((key) {
      return _foldTr(_teamLabel(key)).contains(q);
    }).toList();
  }

  List<Person> _peopleInTeam(String teamKey) =>
      _eligiblePeople.where((p) => _teamKeyOf(p) == teamKey).toList();

  bool _isTeamFullySelected(String teamKey) {
    final members = _peopleInTeam(teamKey);
    return members.isNotEmpty &&
        members.every((p) => _selectedPersonIds.contains(p.id));
  }

  bool _isTeamPartiallySelected(String teamKey) {
    final members = _peopleInTeam(teamKey);
    if (members.isEmpty) return false;
    final selected =
        members.where((p) => _selectedPersonIds.contains(p.id)).length;
    return selected > 0 && selected < members.length;
  }

  List<Person> get _filteredEligiblePeople {
    final q = _foldTr(_personQuery.trim());
    if (q.isEmpty) return _eligiblePeople;
    return _eligiblePeople.where((p) {
      final haystack = _foldTr('${p.name} ${p.profession} ${p.team}');
      return haystack.contains(q);
    }).toList();
  }

  /// Varsayılan: tüm uygun personel. Özel seçimde yalnızca işaretlenenler.
  List<Person> get _exportPeople {
    final selected = _selectedPersonIds;
    return _eligiblePeople.where((p) => selected.contains(p.id)).toList();
  }

  bool get _allSelected {
    final eligible = _eligiblePeople;
    return eligible.isNotEmpty &&
        eligible.every((p) => _selectedPersonIds.contains(p.id));
  }

  String get _personSelectionLabel {
    final total = _eligiblePeople.length;
    final count = _exportPeople.length;
    if (total == 0) return 'Personel yok';
    if (_allSelected) return 'Tümü ($total personel)';
    return '$count / $total personel seçili';
  }

  String get _teamSelectionLabel {
    final teams = _eligibleTeams;
    if (teams.isEmpty) return 'Ekip yok';
    final full = teams.where(_isTeamFullySelected).length;
    if (full == teams.length && _allSelected) {
      return 'Tüm ekipler (${teams.length})';
    }
    if (full == 0) return 'Ekip seçilmedi';
    return '$full / ${teams.length} ekip';
  }

  String get _rangeHint {
    switch (_period) {
      case PuantajReportPeriod.daily:
        return widget.anchorDate;
      case PuantajReportPeriod.weekly:
        return PuantajDate.weekLabel(PuantajDate.weekDays(widget.anchorDate));
      case PuantajReportPeriod.monthly:
        return PuantajDate.monthLabel(widget.anchorDate);
    }
  }

  static String _foldTr(String s) {
    final b = StringBuffer();
    for (final unit in s.runes) {
      final c = String.fromCharCode(unit);
      switch (c) {
        case 'I':
          b.write('ı');
        case 'İ':
          b.write('i');
        case 'Ğ':
          b.write('ğ');
        case 'Ü':
          b.write('ü');
        case 'Ş':
          b.write('ş');
        case 'Ö':
          b.write('ö');
        case 'Ç':
          b.write('ç');
        default:
          b.write(c.toLowerCase());
      }
    }
    return b.toString();
  }

  void _onPersonSearchChanged(String value) {
    setState(() => _personQuery = value);
    if (value.trim().isNotEmpty) {
      _peopleTileController.expand();
    }
  }

  void _clearPersonSearch() {
    _personSearchController.clear();
    setState(() => _personQuery = '');
  }

  void _onTeamSearchChanged(String value) {
    setState(() => _teamQuery = value);
    if (value.trim().isNotEmpty) {
      _teamsTileController.expand();
    }
  }

  void _clearTeamSearch() {
    _teamSearchController.clear();
    setState(() => _teamQuery = '');
  }

  void _setPeriod(PuantajReportPeriod period) {
    setState(() {
      _period = period;
      final available = _eligiblePeople.map((p) => p.id).toSet();
      _selectedPersonIds = _selectedPersonIds.intersection(available);
      // Dönem değişince uygun kimse kalmazsa yine tümünü seç.
      if (_selectedPersonIds.isEmpty) {
        _selectedPersonIds = available;
      }
      _error = null;
    });
  }

  void _selectAllPeople() {
    setState(() {
      _selectedPersonIds = _eligiblePeople.map((p) => p.id).toSet();
      _error = null;
    });
  }

  void _selectFilteredPeople() {
    setState(() {
      _selectedPersonIds = {
        ..._selectedPersonIds,
        ..._filteredEligiblePeople.map((p) => p.id),
      };
      _error = null;
    });
  }

  void _clearPeople() {
    setState(() {
      _selectedPersonIds = {};
      _error = null;
    });
  }

  void _togglePerson(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedPersonIds.add(id);
      } else {
        _selectedPersonIds.remove(id);
      }
      _error = null;
    });
  }

  void _toggleTeam(String teamKey, bool selected) {
    final memberIds = _peopleInTeam(teamKey).map((p) => p.id);
    setState(() {
      if (selected) {
        _selectedPersonIds.addAll(memberIds);
      } else {
        _selectedPersonIds.removeAll(memberIds);
      }
      _error = null;
    });
  }

  void _selectOnlyTeam(String teamKey) {
    setState(() {
      _selectedPersonIds = _peopleInTeam(teamKey).map((p) => p.id).toSet();
      _error = null;
    });
  }

  void _selectFilteredTeams() {
    final ids = <String>{};
    for (final key in _filteredEligibleTeams) {
      ids.addAll(_peopleInTeam(key).map((p) => p.id));
    }
    setState(() {
      _selectedPersonIds = {..._selectedPersonIds, ...ids};
      _error = null;
    });
  }

  Future<void> _export({required bool pdf}) async {
    if (_busy) return;
    final hasUninsured = widget.uninsuredTeams.any(
      (e) => _periodDays.contains(e.date),
    );
    final hasYevmiyeli = widget.yevmiyeliEntries.any(
      (e) => _periodDays.contains(e.date),
    );
    if (_layout == PuantajExportLayout.isim && _exportPeople.isEmpty) {
      setState(() => _error = 'En az bir personel seçin.');
      return;
    }
    if (_layout == PuantajExportLayout.ekip &&
        _exportPeople.isEmpty &&
        !hasUninsured) {
      setState(() => _error = 'Dışa aktarılacak ekip kaydı yok.');
      return;
    }
    if (_layout == PuantajExportLayout.yevmiyeli && !hasYevmiyeli) {
      setState(() => _error = 'Bu dönemde yevmiyeli iş kaydı yok.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = PuantajReportBuilder.build(
        projectName: widget.project.name,
        projectId: widget.project.id,
        people: _exportPeople,
        attendance: widget.attendance,
        period: _period,
        anchorDate: widget.anchorDate,
        layout: _layout,
        uninsuredTeams: widget.uninsuredTeams,
        yevmiyeliEntries: widget.yevmiyeliEntries,
      );
      if (pdf) {
        await puantajExportService.exportPdf(
          report,
          companyName: widget.project.name,
          companyLogoBase64: widget.project.logoBase64,
        );
      } else {
        await puantajExportService.exportExcel(report);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pdf ? 'PDF dışa aktarıldı.' : 'Excel dışa aktarıldı.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eligible = _eligiblePeople;
    final filtered = _filteredEligiblePeople;
    final teams = _eligibleTeams;
    final filteredTeams = _filteredEligibleTeams;
    final hasQuery = _personQuery.trim().isNotEmpty;
    final hasTeamQuery = _teamQuery.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.project.name} · $_rangeHint',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Dönem', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<PuantajReportPeriod>(
          style: SegmentedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            selectedForegroundColor: theme.colorScheme.onSecondary,
            selectedBackgroundColor: theme.colorScheme.secondary,
          ),
          segments: const [
            ButtonSegment(
              value: PuantajReportPeriod.daily,
              label: Text('Günlük'),
            ),
            ButtonSegment(
              value: PuantajReportPeriod.weekly,
              label: Text('Haftalık'),
            ),
            ButtonSegment(
              value: PuantajReportPeriod.monthly,
              label: Text('Aylık'),
            ),
          ],
          selected: {_period},
          onSelectionChanged: _busy ? null : (s) => _setPeriod(s.first),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Çıktı türü', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<PuantajExportLayout>(
          style: SegmentedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            selectedForegroundColor: theme.colorScheme.onSecondary,
            selectedBackgroundColor: theme.colorScheme.secondary,
          ),
          segments: const [
            ButtonSegment(
              value: PuantajExportLayout.isim,
              label: Text('Personel'),
            ),
            ButtonSegment(
              value: PuantajExportLayout.ekip,
              label: Text('Ekip'),
            ),
            ButtonSegment(
              value: PuantajExportLayout.yevmiyeli,
              label: Text('Yevmiyeli'),
            ),
          ],
          selected: {_layout},
          onSelectionChanged: _busy
              ? null
              : (s) => setState(() {
                    _layout = s.first;
                    _error = null;
                  }),
        ),
        if (_layout == PuantajExportLayout.ekip) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ekip çıktısı: firma + ekip + sayı '
            '(Mevcut, Yarım, Giriş, Çıkış). '
            'Ekip başlığı kayıtları ayrı satırda.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_layout == PuantajExportLayout.yevmiyeli) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Yevmiyeli iş tablosu: taşeron, meslek, ekip, iş tanımı '
            've manuel yevmiye adedi.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_layout != PuantajExportLayout.yevmiyeli) ...[
        const SizedBox(height: AppSpacing.md),
        Text('Personel', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SJSearchBar(
          controller: _personSearchController,
          hint: 'Personel ara...',
          onChanged: _busy ? null : _onPersonSearchChanged,
          onClear: _busy ? null : _clearPersonSearch,
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.md,
            side: BorderSide(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              controller: _peopleTileController,
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              childrenPadding: EdgeInsets.zero,
              title: Text(
                _personSelectionLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _allSelected
                    ? 'Standart: tüm personel'
                    : 'Özel seçim: yalnızca işaretlenenler',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                if (eligible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      'Bu dönemde çıktıya uygun personel yok.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : _selectAllPeople,
                          child: const Text('Tümünü seç'),
                        ),
                        if (hasQuery)
                          TextButton(
                            onPressed: _busy || filtered.isEmpty
                                ? null
                                : _selectFilteredPeople,
                            child: Text('Görünenleri seç (${filtered.length})'),
                          ),
                        TextButton(
                          onPressed: _busy ? null : _clearPeople,
                          child: const Text('Temizle'),
                        ),
                      ],
                    ),
                  ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        'Eşleşen personel yok.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.28,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final person = filtered[index];
                          final checked =
                              _selectedPersonIds.contains(person.id);
                          final parts = <String>[
                            if (person.profession.trim().isNotEmpty)
                              person.profession,
                            if (person.team.trim().isNotEmpty) person.team,
                          ];
                          final subtitle =
                              parts.isEmpty ? null : parts.join(' · ');
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            value: checked,
                            onChanged: _busy
                                ? null
                                : (v) =>
                                    _togglePerson(person.id, v ?? false),
                            title: Text(person.name),
                            subtitle:
                                subtitle == null ? null : Text(subtitle),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Ekip', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SJSearchBar(
          controller: _teamSearchController,
          hint: 'Ekip ara...',
          onChanged: _busy ? null : _onTeamSearchChanged,
          onClear: _busy ? null : _clearTeamSearch,
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.md,
            side: BorderSide(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              controller: _teamsTileController,
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              childrenPadding: EdgeInsets.zero,
              title: Text(
                _teamSelectionLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Ekip seçerek yalnızca o ekibin puantajını alın',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                if (teams.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      'Bu dönemde ekip kaydı yok.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : _selectAllPeople,
                          child: const Text('Tüm ekipler'),
                        ),
                        if (hasTeamQuery)
                          TextButton(
                            onPressed: _busy || filteredTeams.isEmpty
                                ? null
                                : _selectFilteredTeams,
                            child: Text(
                              'Görünenleri seç (${filteredTeams.length})',
                            ),
                          ),
                        TextButton(
                          onPressed: _busy ? null : _clearPeople,
                          child: const Text('Temizle'),
                        ),
                      ],
                    ),
                  ),
                  if (filteredTeams.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        'Eşleşen ekip yok.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.28,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredTeams.length,
                        itemBuilder: (context, index) {
                          final teamKey = filteredTeams[index];
                          final members = _peopleInTeam(teamKey);
                          final fully = _isTeamFullySelected(teamKey);
                          final partial = _isTeamPartiallySelected(teamKey);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            tristate: true,
                            value: fully
                                ? true
                                : (partial ? null : false),
                            onChanged: _busy
                                ? null
                                : (v) => _toggleTeam(
                                      teamKey,
                                      v ?? false,
                                    ),
                            title: Text(_teamLabel(teamKey)),
                            subtitle: Text('${members.length} personel'),
                            secondary: TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _selectOnlyTeam(teamKey),
                              child: const Text('Yalnız'),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        ], // personel/ekip seçimi — yevmiyeli çıktıda gizlenir
        const SizedBox(height: AppSpacing.md),
        Text('Format', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SJButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                loading: _busy,
                expanded: true,
                onPressed: () => _export(pdf: true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SJButton(
                label: 'Excel',
                icon: Icons.table_chart_outlined,
                variant: SJButtonVariant.secondary,
                loading: _busy,
                expanded: true,
                onPressed: () => _export(pdf: false),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.critical,
            ),
          ),
        ],
      ],
    );
  }
}
