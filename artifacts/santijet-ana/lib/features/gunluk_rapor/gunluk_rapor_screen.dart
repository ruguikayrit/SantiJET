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
import 'package:santijet_ana/domain/models/daily_report.dart';
import 'package:santijet_ana/domain/models/page_key.dart';
import 'package:santijet_ana/features/_shared/entity_form_sheet.dart';

const _weatherOpts = <({String value, String label})>[
  (value: 'Güneşli', label: 'Güneşli'),
  (value: 'Bulutlu', label: 'Bulutlu'),
  (value: 'Yağmurlu', label: 'Yağmurlu'),
  (value: 'Karlı', label: 'Karlı'),
  (value: 'Rüzgarlı', label: 'Rüzgarlı'),
];

class GunlukRaporScreen extends ConsumerStatefulWidget {
  const GunlukRaporScreen({super.key});

  @override
  ConsumerState<GunlukRaporScreen> createState() => _GunlukRaporScreenState();
}

class _GunlukRaporScreenState extends ConsumerState<GunlukRaporScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  void _guard() {
    if (!mounted) return;
    final perm = ref.read(appStateProvider).getPermission('gunluk-rapor');
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

  Future<void> _open([DailyReport? r]) async {
    final state = ref.read(appStateProvider);
    final c = ref.read(themeDefinitionProvider).colors;
    final projects = state.projects;
    final tempCtrl = TextEditingController(text: r?.temperature ?? '');
    final workersCtrl = TextEditingController(
      text: r != null ? '${r.workerCount}' : '',
    );
    final activitiesCtrl = TextEditingController(text: r?.activities ?? '');
    final issuesCtrl = TextEditingController(text: r?.issues ?? '');
    final createdByCtrl = TextEditingController(
      text: r?.createdBy ?? state.currentAppUser?.name ?? '',
    );
    var weather = r?.weather.isNotEmpty == true ? r!.weather : 'Güneşli';
    var projectId = r?.projectId ??
        (projects.isNotEmpty ? projects.first.id : '');
    var date = r?.date ?? todayIso();
    final editId = r?.id;

    await showEntityFormSheet(
      context: context,
      title: editId == null ? 'Yeni Günlük Rapor' : 'Raporu Düzenle',
      onSave: () {
        final notifier = ref.read(appStateProvider.notifier);
        final workerCount = int.tryParse(workersCtrl.text.trim()) ?? 0;
        if (editId == null) {
          notifier.addDailyReport(DailyReport(
            id: '',
            projectId: projectId,
            date: date,
            weather: weather,
            temperature: tempCtrl.text.trim(),
            workerCount: workerCount,
            activities: activitiesCtrl.text.trim(),
            issues: issuesCtrl.text.trim(),
            createdBy: createdByCtrl.text.trim(),
          ));
        } else {
          notifier.updateDailyReport(
            editId,
            (e) => e.copyWith(
              projectId: projectId,
              date: date,
              weather: weather,
              temperature: tempCtrl.text.trim(),
              workerCount: workerCount,
              activities: activitiesCtrl.text.trim(),
              issues: issuesCtrl.text.trim(),
              createdBy: createdByCtrl.text.trim(),
            ),
          );
        }
        Navigator.pop(context);
      },
      onDelete: editId == null
          ? null
          : () {
              ref.read(appStateProvider.notifier).deleteDailyReport(editId);
              Navigator.pop(context);
            },
      form: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (projects.isNotEmpty) ...[
                Text(
                  'Proje',
                  style:
                      AppTypography.labelMedium.copyWith(color: c.foreground),
                ),
                const SizedBox(height: AppSpacing.xxs),
                DropdownButtonFormField<String>(
                  value: projects.any((p) => p.id == projectId)
                      ? projectId
                      : projects.first.id,
                  items: [
                    for (final p in projects)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => projectId = v);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.background,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.md,
                      borderSide: BorderSide(color: c.input),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SjDateField(
                label: 'Tarih',
                value: date,
                onPicked: (v) => setModal(() => date = v),
                foreground: c.foreground,
                mutedForeground: c.mutedForeground,
                card: c.background,
                input: c.input,
                primary: c.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hava',
                style: AppTypography.labelMedium.copyWith(color: c.foreground),
              ),
              const SizedBox(height: AppSpacing.xxs),
              SjOptionChips(
                options: _weatherOpts,
                value: weather,
                onChanged: (v) => setModal(() => weather = v),
                foreground: c.foreground,
                muted: c.muted,
                primary: c.primary,
                border: c.border,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Sıcaklık',
                controller: tempCtrl,
                hint: 'Örn: 24°C',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'İşçi sayısı',
                controller: workersCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Faaliyetler',
                controller: activitiesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Sorunlar',
                controller: issuesCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Hazırlayan',
                controller: createdByCtrl,
              ),
            ],
          );
        },
      ),
    );

    tempCtrl.dispose();
    workersCtrl.dispose();
    activitiesCtrl.dispose();
    issuesCtrl.dispose();
    createdByCtrl.dispose();
  }

  List<Widget> _autoSummaryChips(AppState state, Color foreground, Color muted) {
    final today = todayIso();
    final aliases = dateAliases(today);
    final attToday = state.attendance
        .where((a) => aliases.contains(a.date))
        .toList();
    final present = attToday.where((a) => a.status == 'present').length;
    final half = attToday.where((a) => a.status == 'half').length;
    final absent = attToday.where((a) => a.status == 'absent').length;
    final tasksOpen = state.tasks
        .where((t) => t.status == 'open' || t.status == 'in_progress')
        .length;
    final tasksDone = state.tasks.where((t) => t.status == 'done').length;
    final prods = state.productions
        .where((p) => aliases.contains(p.date))
        .toList();

    final chips = <String>[
      'Puantaj: $present mevcut / $half yarım / $absent yok',
      'Görev: $tasksOpen açık · $tasksDone bitti',
      if (prods.isEmpty)
        'İmalat: bugün kayıt yok'
      else
        'İmalat: ${prods.length} kalem · ${prods.fold<double>(0, (s, p) => s + p.completedQty).toStringAsFixed(1)} miktar',
    ];

    return [
      for (final chip in chips)
        Container(
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: muted.withValues(alpha: 0.4),
            borderRadius: AppRadii.sm,
          ),
          child: Text(
            chip,
            style: AppTypography.bodySmall.copyWith(color: foreground),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);
    final perm = state.getPermission('gunluk-rapor');
    if (perm == Permission.none) {
      return Scaffold(backgroundColor: c.background);
    }
    final canEdit = perm == Permission.edit;
    final reports = state.dailyReports;
    final projects = state.projects;

    String projectName(String id) {
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return '';
    }

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Günlük Rapor',
            onBack: _goBack,
            trailing: canEdit
                ? IconButton(
                    onPressed: () => _open(),
                    icon: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
              ),
              children: [
                Text(
                  'Bugünün özeti',
                  style: AppTypography.headlineMedium.copyWith(
                    color: c.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Puantaj, görev ve imalat verilerinden otomatik',
                  style: AppTypography.bodySmall.copyWith(
                    color: c.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  children: _autoSummaryChips(
                    state,
                    c.foreground,
                    c.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Kayıtlı raporlar',
                  style: AppTypography.headlineMedium.copyWith(
                    color: c.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: SjEmptyState(
                      title: 'Henüz rapor yok',
                      message: 'İlk günlük raporu eklemek için + kullanın',
                      icon: Icons.description_outlined,
                    ),
                  )
                else
                  ...[
                    for (var i = 0; i < reports.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      Builder(
                        builder: (context) {
                          final r = reports[i];
                          return Material(
                            color: c.card,
                            borderRadius: AppRadii.md,
                            child: InkWell(
                              borderRadius: AppRadii.md,
                              onTap: canEdit ? () => _open(r) : null,
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
                                        Expanded(
                                          child: Text(
                                            displayDate(r.date),
                                            style: AppTypography.headlineMedium
                                                .copyWith(
                                              color: c.foreground,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (r.weather.isNotEmpty)
                                          Text(
                                            r.weather,
                                            style: AppTypography.bodySmall
                                                .copyWith(color: c.primary),
                                          ),
                                      ],
                                    ),
                                    if (projectName(r.projectId).isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        projectName(r.projectId),
                                        style: AppTypography.bodySmall
                                            .copyWith(color: c.mutedForeground),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'İşçi: ${r.workerCount}'
                                      '${r.temperature.isNotEmpty ? ' · ${r.temperature}' : ''}',
                                      style: AppTypography.bodySmall
                                          .copyWith(color: c.mutedForeground),
                                    ),
                                    if (r.activities.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        r.activities,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyMedium
                                            .copyWith(color: c.foreground),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
