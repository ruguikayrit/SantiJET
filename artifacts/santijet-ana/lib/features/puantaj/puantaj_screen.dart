import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/app_radii.dart';
import 'package:santijet_ana/core/theme/app_spacing.dart';
import 'package:santijet_ana/core/theme/app_typography.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_empty_state.dart';
import 'package:santijet_ana/core/widgets/sj_form_field.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/app_user.dart';
import 'package:santijet_ana/domain/models/attendance.dart';
import 'package:santijet_ana/domain/models/page_key.dart';
import 'package:santijet_ana/features/_shared/entity_form_sheet.dart';

class _StatusOpt {
  const _StatusOpt(this.value, this.label, this.color, this.hours);
  final String value;
  final String label;
  final Color color;
  final double hours;
}

const _statusOpts = <_StatusOpt>[
  _StatusOpt('present', 'Mevcut', Color(0xFF16A34A), 8),
  _StatusOpt('half', 'Yarım Gün', Color(0xFFD97706), 4),
  _StatusOpt('izinli', 'İzinli', Color(0xFF0EA5E9), 0),
  _StatusOpt('raporlu', 'Raporlu', Color(0xFF8B5CF6), 0),
  _StatusOpt('mazeret', 'Mazeret', Color(0xFFF59E0B), 0),
  _StatusOpt('tatil', 'Tatil', Color(0xFF64748B), 0),
  _StatusOpt('absent', 'Yok', Color(0xFFDC2626), 0),
];

_StatusOpt _optFor(String? s) =>
    _statusOpts.firstWhere((o) => o.value == s, orElse: () => _statusOpts.first);

class PuantajScreen extends ConsumerStatefulWidget {
  const PuantajScreen({super.key});

  @override
  ConsumerState<PuantajScreen> createState() => _PuantajScreenState();
}

class _PuantajScreenState extends ConsumerState<PuantajScreen> {
  late String _date;
  String? _projectId;

  @override
  void initState() {
    super.initState();
    _date = todayIso();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guard();
      final projects = ref.read(appStateProvider).projects;
      if (projects.isNotEmpty && _projectId == null) {
        setState(() => _projectId = projects.first.id);
      }
    });
  }

  void _guard() {
    if (!mounted) return;
    final perm = ref.read(appStateProvider).getPermission('puantaj');
    if (perm == Permission.none) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Attendance? _attFor(List<Attendance> list, String userId, String projectId) {
    final aliases = dateAliases(_date);
    for (final a in list) {
      if (a.workerId == userId &&
          a.projectId == projectId &&
          aliases.contains(a.date)) {
        return a;
      }
    }
    return null;
  }

  void _setStatus(AppUser u, String status) {
    final state = ref.read(appStateProvider);
    final projectId = _projectId ??
        (state.projects.isNotEmpty ? state.projects.first.id : '');
    if (projectId.isEmpty) return;
    final opt = _optFor(status);
    final existing = _attFor(state.attendance, u.id, projectId);
    final notifier = ref.read(appStateProvider.notifier);
    if (existing != null) {
      notifier.updateAttendance(
        existing.id,
        (a) => a.copyWith(status: status, hours: opt.hours),
      );
    } else {
      notifier.addAttendance(Attendance(
        id: '',
        projectId: projectId,
        workerId: u.id,
        workerName: u.name,
        date: _date,
        status: status,
        hours: opt.hours,
        note: '',
      ));
    }
  }

  Future<void> _editDetail(AppUser u) async {
    final state = ref.read(appStateProvider);
    final c = ref.read(themeDefinitionProvider).colors;
    final projectId = _projectId ??
        (state.projects.isNotEmpty ? state.projects.first.id : '');
    if (projectId.isEmpty) return;
    final existing = _attFor(state.attendance, u.id, projectId);
    var status = existing?.status ?? 'present';
    final hoursCtrl = TextEditingController(
      text: (existing?.hours ?? _optFor(status).hours).toString(),
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    await showEntityFormSheet(
      context: context,
      title: u.name,
      onSave: () {
        final hours = double.tryParse(
              hoursCtrl.text.trim().replaceAll(',', '.'),
            ) ??
            _optFor(status).hours;
        final notifier = ref.read(appStateProvider.notifier);
        final latest = _attFor(
          ref.read(appStateProvider).attendance,
          u.id,
          projectId,
        );
        if (latest != null) {
          notifier.updateAttendance(
            latest.id,
            (a) => a.copyWith(
              status: status,
              hours: hours,
              note: noteCtrl.text.trim(),
            ),
          );
        } else {
          notifier.addAttendance(Attendance(
            id: '',
            projectId: projectId,
            workerId: u.id,
            workerName: u.name,
            date: _date,
            status: status,
            hours: hours,
            note: noteCtrl.text.trim(),
          ));
        }
        Navigator.pop(context);
      },
      form: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Durum',
                style: AppTypography.labelMedium.copyWith(color: c.foreground),
              ),
              const SizedBox(height: AppSpacing.xxs),
              SjOptionChips(
                options: [
                  for (final o in _statusOpts)
                    (value: o.value, label: o.label),
                ],
                value: status,
                onChanged: (v) => setModal(() {
                  status = v;
                  hoursCtrl.text = _optFor(v).hours.toString();
                }),
                foreground: c.foreground,
                muted: c.muted,
                primary: c.primary,
                border: c.border,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Saat',
                controller: hoursCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Not',
                controller: noteCtrl,
                maxLines: 2,
              ),
            ],
          );
        },
      ),
    );

    hoursCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);
    final perm = state.getPermission('puantaj');
    if (perm == Permission.none) {
      return Scaffold(backgroundColor: c.background);
    }
    final canEdit = perm == Permission.edit;
    final projects = state.projects;
    final users = state.appUsers;
    final projectId = _projectId ??
        (projects.isNotEmpty ? projects.first.id : '');

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Puantaj',
            subtitle: displayDate(_date),
            onBack: _goBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Column(
              children: [
                SjDateField(
                  label: 'Gün',
                  value: _date,
                  onPicked: (v) => setState(() => _date = v),
                  foreground: c.foreground,
                  mutedForeground: c.mutedForeground,
                  card: c.card,
                  input: c.input,
                  primary: c.primary,
                ),
                if (projects.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: projects.any((p) => p.id == projectId)
                        ? projectId
                        : projects.first.id,
                    decoration: InputDecoration(
                      labelText: 'Proje',
                      filled: true,
                      fillColor: c.card,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.md,
                        borderSide: BorderSide(color: c.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      for (final p in projects)
                        DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _projectId = v);
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: users.isEmpty
                ? const SjEmptyState(
                    title: 'Personel yok',
                    message: 'Önce Kullanıcılar ekranından personel ekleyin',
                    icon: Icons.people_outline,
                  )
                : projectId.isEmpty
                    ? const SjEmptyState(
                        title: 'Proje gerekli',
                        message: 'Puantaj için önce bir proje oluşturun',
                        icon: Icons.folder_off_outlined,
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          final att = _attFor(state.attendance, u.id, projectId);
                          final opt = att == null ? null : _optFor(att.status);
                          return Material(
                            color: c.card,
                            borderRadius: AppRadii.md,
                            child: InkWell(
                              borderRadius: AppRadii.md,
                              onTap: canEdit ? () => _editDetail(u) : null,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadii.md,
                                  border: Border.all(
                                    color: c.border.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: c.primary
                                              .withValues(alpha: 0.15),
                                          child: Text(
                                            u.name.isNotEmpty
                                                ? u.name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: c.primary,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                u.name,
                                                style: AppTypography
                                                    .headlineMedium
                                                    .copyWith(
                                                  color: c.foreground,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (u.profession.isNotEmpty)
                                                Text(
                                                  u.profession,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                    color: c.mutedForeground,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (att != null)
                                          Text(
                                            '${att.hours}s',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                              color: c.foreground,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (canEdit) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          for (final o in _statusOpts)
                                            GestureDetector(
                                              onTap: () =>
                                                  _setStatus(u, o.value),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: att?.status == o.value
                                                      ? o.color.withValues(
                                                          alpha: 0.18,
                                                        )
                                                      : c.muted.withValues(
                                                          alpha: 0.35,
                                                        ),
                                                  borderRadius: AppRadii.sm,
                                                  border: Border.all(
                                                    color:
                                                        att?.status == o.value
                                                            ? o.color
                                                            : c.border,
                                                  ),
                                                ),
                                                child: Text(
                                                  o.label,
                                                  style: TextStyle(
                                                    color:
                                                        att?.status == o.value
                                                            ? o.color
                                                            : c.foreground,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ] else if (opt != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        opt.label,
                                        style: TextStyle(
                                          color: opt.color,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                    if (att != null && att.note.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        att.note,
                                        style: AppTypography.bodySmall
                                            .copyWith(color: c.mutedForeground),
                                      ),
                                    ],
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
    );
  }
}
