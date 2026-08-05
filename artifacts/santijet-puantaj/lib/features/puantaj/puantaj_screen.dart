import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/services/puantaj_export_service.dart';
import '../../data/services/puantaj_report_builder.dart';
import '../../domain/entities/person.dart';
import '../../domain/enums/attendance_status.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/project.dart';

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
    final people = ref.watch(activePersonnelProvider);
    final attendance = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);

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

    AttendanceStatus? statusOf(String personId, String date) {
      for (final a in attendance) {
        if (a.projectId == project.id &&
            a.personId == personId &&
            a.date == date) {
          return a.status;
        }
      }
      return null;
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

    final missing = people
        .where((p) => statusOf(p.id, _date) == null)
        .length;

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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Puantaj'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
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
                                  ? Colors.white
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
                  notifier.setNote(
                    projectId: project.id,
                    person: person,
                    date: _date,
                    note: _noteController.text,
                  );
                  setState(() => _openNote = null);
                },
                onSetStatus: (person, status) {
                  notifier.setStatus(
                    projectId: project.id,
                    person: person,
                    date: _date,
                    status: status,
                  );
                  setState(() => _openDropdown = null);
                },
                onSetOvertime: (person, hours) {
                  notifier.setOvertime(
                    projectId: project.id,
                    person: person,
                    date: _date,
                    overtimeHours: hours,
                  );
                },
                onBulk: (status) {
                  notifier.bulkSetStatus(
                    projectId: project.id,
                    people: people,
                    date: _date,
                    status: status,
                  );
                },
                onCopyYesterday: () {
                  final copied = notifier.copyFromPreviousDay(
                    projectId: project.id,
                    people: people,
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
                    _date = PuantajDate.format(DateTime(d.year, d.month - 1, 1));
                  }
                }),
                onNext: () => setState(() {
                  if (_mode == _ViewMode.weekly) {
                    _date = PuantajDate.shift(_date, 7);
                  } else {
                    final d = PuantajDate.parse(_date);
                    _date = PuantajDate.format(DateTime(d.year, d.month + 1, 1));
                  }
                }),
                people: people,
                grouped: _grouped(people),
                statusOf: statusOf,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SJButton(
                label: 'Puantaj Dışa Aktar',
                icon: Icons.ios_share_outlined,
                expanded: true,
                onPressed: () => _openExportSheet(
                  context,
                  project: project,
                  people: people,
                  attendance: attendance,
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
    required List<Person> people,
    required List<Attendance> attendance,
  }) {
    final initial = switch (_mode) {
      _ViewMode.daily => PuantajReportPeriod.daily,
      _ViewMode.weekly => PuantajReportPeriod.weekly,
      _ViewMode.monthly => PuantajReportPeriod.monthly,
    };
    return SJModal.showSheet(
      context: context,
      title: 'Puantaj dışa aktar',
      child: _PuantajExportSheet(
        project: project,
        people: people,
        attendance: attendance,
        anchorDate: _date,
        initialPeriod: initial,
      ),
    );
  }
}

class _DailyView extends StatelessWidget {
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

  Future<void> _pickDate(BuildContext context) async {
    final initial = PuantajDate.parse(date);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateChanged(PuantajDate.format(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (people.isEmpty) {
      return SJEmptyState(
        title: 'Kayıtlı personel yok',
        message: 'Personel yönetiminden ekip üyesi ekleyin.',
        icon: Icons.groups_outlined,
        actionLabel: 'Personel',
        onAction: () => context.push(AppRoutes.personel),
      );
    }

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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(date),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onCopyYesterday,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Dünden Kopyala'),
            ),
          ],
        ),
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
                const Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '$missing personelin puantajı girilmedi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
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
                onPressed: () => onBulk(AttendanceStatus.present),
                icon: Icon(Icons.check_circle,
                    size: 16, color: AttendanceStatus.present.color),
                label: Text(
                  'Tümünü Mevcut',
                  style: TextStyle(color: AttendanceStatus.present.color),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onBulk(AttendanceStatus.absent),
                icon: Icon(Icons.cancel,
                    size: 16, color: AttendanceStatus.absent.color),
                label: Text(
                  'Tümünü Yok',
                  style: TextStyle(color: AttendanceStatus.absent.color),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final group in grouped) ...[
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                color: AppColors.electricBlue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.work_outline,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(group.company, style: theme.textTheme.titleMedium),
              ),
              Text(
                '${group.users.length} kişi',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final person in group.users)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PersonCard(
                person: person,
                status: statusOf(person.id),
                note: noteOf(person.id),
                overtimeHours: overtimeOf(person.id),
                dropdownOpen: openDropdown == person.id,
                noteOpen: openNote == person.id,
                noteController: noteController,
                onToggleDropdown: () => onToggleDropdown(person.id),
                onOpenNote: () => onOpenNote(person),
                onCloseNote: onCloseNote,
                onSaveNote: () => onSaveNote(person),
                onSetStatus: (s) => onSetStatus(person, s),
                onSetOvertime: (h) => onSetOvertime(person, h),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Özet rozeti — kısa kod (M, Y…) varsayılan; tıklanınca tam ad (Mevcut…).
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
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: color,
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

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (person.team.trim().isNotEmpty) person.team.trim(),
      if (person.profession.trim().isNotEmpty) person.profession.trim(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(person.name, style: theme.textTheme.titleMedium),
                        if (meta.isNotEmpty)
                          Text(meta, style: theme.textTheme.bodySmall),
                      ],
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
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            dropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: statusColor,
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
                      style: TextStyle(
                        color: s.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: status == s
                        ? Icon(Icons.check, color: s.color, size: 18)
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
  });

  final _ViewMode mode;
  final String date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final List<Person> people;
  final List<({String company, List<Person> users})> grouped;
  final AttendanceStatus? Function(String personId, String date) statusOf;

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
    const totalW = 36.0;
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
                          color: Colors.white,
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
                  _cetvelHeader(theme, days, cellW, nameW, totalW, today),
                  for (final group in grouped) ...[
                    Container(
                      width: nameW + days.length * cellW + totalW,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      color: AppColors.electricBlue.withValues(alpha: 0.08),
                      child: Text(
                        group.company,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final person in group.users)
                      _cetvelRow(
                        theme,
                        person,
                        days,
                        cellW,
                        nameW,
                        totalW,
                        statusOf,
                      ),
                  ],
                  _mevcutFooter(theme, people, days, cellW, nameW, totalW, statusOf),
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
        SizedBox(
          width: totalW,
          child: Text(
            'Top.',
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
    double totalW,
    AttendanceStatus? Function(String, String) statusOf,
  ) {
    final statuses = [for (final d in days) statusOf(person.id, d)];
    final workCount = statuses.where((s) => s?.isWorkedDay ?? false).length;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: nameW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                person.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
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
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: (s?.short.length ?? 0) > 1 ? 8 : 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: totalW,
            child: Text(
              workCount > 0 ? '$workCount' : '–',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: workCount > 0
                    ? AttendanceStatus.present.color
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mevcutFooter(
    ThemeData theme,
    List<Person> people,
    List<String> days,
    double cellW,
    double nameW,
    double totalW,
    AttendanceStatus? Function(String, String) statusOf,
  ) {
    return Row(
      children: [
        SizedBox(
          width: nameW,
          child: Text(
            'Mevcut',
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
                color: AttendanceStatus.present.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        SizedBox(width: totalW),
      ],
    );
  }
}

class _PuantajExportSheet extends StatefulWidget {
  const _PuantajExportSheet({
    required this.project,
    required this.people,
    required this.attendance,
    required this.anchorDate,
    required this.initialPeriod,
  });

  final Project project;
  final List<Person> people;
  final List<Attendance> attendance;
  final String anchorDate;
  final PuantajReportPeriod initialPeriod;

  @override
  State<_PuantajExportSheet> createState() => _PuantajExportSheetState();
}

class _PuantajExportSheetState extends State<_PuantajExportSheet> {
  late PuantajReportPeriod _period = widget.initialPeriod;
  bool _busy = false;
  String? _error;

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

  Future<void> _export({required bool pdf}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = PuantajReportBuilder.build(
        projectName: widget.project.name,
        projectId: widget.project.id,
        people: widget.people,
        attendance: widget.attendance,
        period: _period,
        anchorDate: widget.anchorDate,
      );
      if (pdf) {
        await puantajExportService.exportPdf(report);
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
            selectedForegroundColor: Colors.white,
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
          onSelectionChanged: _busy
              ? null
              : (s) => setState(() => _period = s.first),
        ),
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
