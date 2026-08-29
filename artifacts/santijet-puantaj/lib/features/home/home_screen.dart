import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/project_permission_gate.dart';
import '../../core/widgets/santijet_header.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/catalogs/task_categories.dart';
import '../../domain/catalogs/task_tags.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/attendance_status.dart';
import '../projects/widgets/project_switcher.dart';
import 'home_daily_report_pdf_sheet.dart';
import 'home_task_summary_dialog.dart';
import '../demo/demo_guide_banner.dart';
import '../daily_report/widgets/daily_report_export_sections_sheet.dart';
import '../../data/providers/daily_report_export_sections_provider.dart';

/// Ana sayfa — günlük puantaj, günlük rapor, acil görevler.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dailyReportBusy = false;

  Future<void> _exportDailyReportForDates(
    Project project,
    List<String> dates, {
    required String successLabel,
  }) async {
    if (_dailyReportBusy) return;

    final sections = await showDailyReportExportSectionsPicker(
      context,
      ref,
      title: 'Çıktıda yer alacak başlıklar',
      subtitle: dates.length == 1
          ? '${project.name} · ${dates.first}'
          : '${project.name} · ${dates.length} gün',
    );
    if (sections == null || !mounted) return;

    ref.read(dailyReportExportSectionsProvider.notifier).save(sections);

    setState(() => _dailyReportBusy = true);
    try {
      await exportHomeDailyReportPdf(
        ref,
        project: project,
        dates: dates,
        sections: sections,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successLabel PDF dışa aktarıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _dailyReportBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final today = PuantajDate.today();
    final people = ref.watch(personnelForDateProvider(today));
    final attendance = ref.watch(attendanceProvider);
    final urgentTasks = ref.watch(upcomingUrgentTasksProvider);
    final urgentByCategory = ref.watch(urgentTaskCategorySummariesProvider);
    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(showWordmark: true, avatarInitial: 'SJ'),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.afterHeader,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
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

    // —— Puantaj özeti ——
    final todayRecords = attendance
        .where((a) => a.projectId == project.id && a.date == today)
        .toList();
    final present = todayRecords
        .where((a) => a.status == AttendanceStatus.present)
        .length;
    final half = todayRecords
        .where((a) => a.status == AttendanceStatus.half)
        .length;
    // Yok = kayıtlı personel − mevcut − yarım
    final absent = (people.length - present - half).clamp(0, people.length);
    final overtimeHours =
        todayRecords.fold<double>(0, (sum, a) => sum + a.overtimeHours);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(showWordmark: true, avatarInitial: 'SJ'),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.afterHeader,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
            ),
            const SliverToBoxAdapter(child: ReadOnlyBanner()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: DemoGuideBanner(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SummarySection(
                    title: 'Günlük Puantaj',
                    icon: Icons.fact_check_outlined,
                    onTap: () => context.go(AppRoutes.puantaj),
                    child: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Mevcut',
                                    value: '$present',
                                    color: AttendanceStatus.present.color,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Yarım',
                                    value: '$half',
                                    color: AttendanceStatus.half.color,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Yok',
                                    value: '$absent',
                                    color: AttendanceStatus.absent.color,
                                  ),
                                ),
                              ],
                            ),
                            if (overtimeHours > 0) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Mesai: ${_fmt(overtimeHours)} sa',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummarySection(
                    title: 'Günlük rapor',
                    icon: Icons.edit_calendar_outlined,
                    child: _DailyReportQuickActions(
                      busy: _dailyReportBusy,
                      onDun: () => _exportDailyReportForDates(
                        project,
                        [PuantajDate.shift(today, -1)],
                        successLabel: 'Dünün raporu',
                      ),
                      onBugun: () => _exportDailyReportForDates(
                        project,
                        [today],
                        successLabel: 'Bugünün raporu',
                      ),
                      onOzel: () => showHomeDailyReportPdfSheet(
                        context,
                        ref,
                        project: project,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummarySection(
                    title: 'Acil görevler',
                    icon: Icons.assignment_late_outlined,
                    onTap: () => context.go(AppRoutes.gorevler),
                    child: _HomeUrgentTasksSection(
                      tasks: urgentTasks,
                      categorySummaries: urgentByCategory,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _HomeUrgentTasksSection extends StatefulWidget {
  const _HomeUrgentTasksSection({
    required this.tasks,
    required this.categorySummaries,
  });

  final List<SiteTask> tasks;
  final List<UrgentTaskCategorySummary> categorySummaries;

  @override
  State<_HomeUrgentTasksSection> createState() => _HomeUrgentTasksSectionState();
}

class _HomeUrgentTasksSectionState extends State<_HomeUrgentTasksSection> {
  String? _selectedCategory;
  String? _selectedTag;

  String _categoryKey(SiteTask task) {
    return task.category.trim().isEmpty
        ? TaskCategoryCatalog.uncategorized
        : task.category.trim();
  }

  /// Karşı boyuttaki seçime göre süzülmüş havuz (liste + çapraz sayımlar).
  List<SiteTask> _poolForTags() {
    if (_selectedCategory == null) return widget.tasks;
    return widget.tasks
        .where((t) => _categoryKey(t) == _selectedCategory)
        .toList();
  }

  List<SiteTask> _poolForCategories() {
    if (_selectedTag == null) return widget.tasks;
    return widget.tasks
        .where((t) => TaskTagCatalog.normalize(t.tag) == _selectedTag)
        .toList();
  }

  List<SiteTask> get _filteredTasks {
    var list = widget.tasks;
    if (_selectedTag != null) {
      list = list
          .where((t) => TaskTagCatalog.normalize(t.tag) == _selectedTag)
          .toList();
    }
    if (_selectedCategory != null) {
      list = list
          .where((t) => _categoryKey(t) == _selectedCategory)
          .toList();
    }
    list = [...list]..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    return list;
  }

  /// Etiket kartları: kategori seçiliyse yalnız o kategorideki adetler.
  List<UrgentTaskTagSummary> get _displayTagSummaries {
    final pool = _poolForTags();
    final counts = {for (final t in TaskTagCatalog.all) t: 0};
    for (final task in pool) {
      final tag = TaskTagCatalog.normalize(task.tag);
      if (counts.containsKey(tag)) {
        counts[tag] = counts[tag]! + 1;
      }
    }
    return [
      for (final tag in TaskTagCatalog.all) (tag: tag, count: counts[tag]!),
    ];
  }

  /// Kategori kartları: etiket seçiliyse yalnız o etiketteki adetler (0 dahil).
  List<UrgentTaskCategorySummary> get _displayCategorySummaries {
    final pool = _poolForCategories();
    final counts = <String, int>{};
    for (final t in pool) {
      final cat = _categoryKey(t);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    // Kart sırası sabit kalsın; seçim sonrası 0 olanlar da görünsün.
    return [
      for (final summary in widget.categorySummaries)
        (category: summary.category, count: counts[summary.category] ?? 0),
    ];
  }

  @override
  void didUpdateWidget(covariant _HomeUrgentTasksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seçim yalnızca o kategori/etiket acil listeden tamamen düşerse sıfırlanır
    // (çapraz filtrede 0 olması seçimi kaldırmaz).
    if (_selectedCategory != null &&
        !widget.tasks.any((t) => _categoryKey(t) == _selectedCategory)) {
      _selectedCategory = null;
    }
    if (_selectedTag != null &&
        !widget.tasks.any(
          (t) => TaskTagCatalog.normalize(t.tag) == _selectedTag,
        )) {
      _selectedTag = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagSummaries = _displayTagSummaries;
    final categorySummaries = _displayCategorySummaries;
    final selectedTagSummary = tagSummaries.where((s) => s.tag == _selectedTag);
    final tagCount = _selectedTag == null
        ? widget.tasks.length
        : (selectedTagSummary.isEmpty ? 0 : selectedTagSummary.first.count);
    final selectedCatSummary =
        categorySummaries.where((s) => s.category == _selectedCategory);
    final catCount =
        selectedCatSummary.isEmpty ? 0 : selectedCatSummary.first.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeFilterMenu<String?>(
                caption: 'Etiket',
                valueLabel: _selectedTag == null
                    ? 'Tümü'
                    : '${TaskTagCatalog.cardLabel(_selectedTag!)} ($tagCount)',
                accent: _selectedTag == null
                    ? null
                    : TaskTagCatalog.accentFor(_selectedTag!),
                selected: _selectedTag,
                items: [
                  (value: null, label: 'Tüm etiketler'),
                  for (final s in tagSummaries)
                    (
                      value: s.tag,
                      label:
                          '${TaskTagCatalog.cardLabel(s.tag)} (${s.count})',
                    ),
                ],
                onSelected: (v) => setState(() => _selectedTag = v),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _HomeFilterMenu<String?>(
                caption: 'Kategori',
                valueLabel: _selectedCategory == null
                    ? 'Tümü'
                    : '$_selectedCategory ($catCount)',
                accent: _selectedCategory == null
                    ? null
                    : TaskCategoryCatalog.accentFor(_selectedCategory!),
                selected: _selectedCategory,
                items: [
                  (value: null, label: 'Tüm kategoriler'),
                  for (final s in categorySummaries)
                    (
                      value: s.category,
                      label: '${s.category} (${s.count})',
                    ),
                ],
                onSelected: (v) => setState(() => _selectedCategory = v),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _HomeFilterMenu<String>(
                caption: 'Seçim',
                valueLabel:
                    (_selectedTag == null && _selectedCategory == null)
                        ? 'Yok'
                        : 'Filtreli',
                selected: 'keep',
                items: const [
                  (value: 'clear', label: 'Filtreleri temizle'),
                ],
                onSelected: (v) {
                  if (v == 'clear') {
                    setState(() {
                      _selectedTag = null;
                      _selectedCategory = null;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (_selectedTag != null || _selectedCategory != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _HomeUrgentTasksList(
            tasks: _filteredTasks,
            filteredByCategory: _selectedCategory,
            filteredByTag: _selectedTag,
          ),
        ],
      ],
    );
  }
}

class _HomeFilterMenu<T> extends StatelessWidget {
  const _HomeFilterMenu({
    required this.caption,
    required this.valueLabel,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.accent,
  });

  final String caption;
  final String valueLabel;
  final List<({T value, String label})> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAccent = accent != null;
    return PopupMenuButton<T>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      onSelected: onSelected,
      itemBuilder: (ctx) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Expanded(child: Text(item.label)),
                if (item.value == selected)
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        decoration: BoxDecoration(
          color: hasAccent
              ? accent!.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppRadii.sm,
          border: Border.all(
            color: (accent ?? theme.colorScheme.outlineVariant)
                .withValues(alpha: hasAccent ? 0.85 : 0.55),
            width: hasAccent ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeUrgentTasksList extends StatelessWidget {
  const _HomeUrgentTasksList({
    required this.tasks,
    this.filteredByCategory,
    this.filteredByTag,
  });

  final List<SiteTask> tasks;
  final String? filteredByCategory;
  final String? filteredByTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tasks.isEmpty) {
      return Text(
        filteredByCategory == null && filteredByTag == null
            ? '1 hafta içinde teslim tarihi olan açık görev yok.'
            : 'Bu filtrede acil görev yok.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          _HomeUrgentTaskTile(task: tasks[i], today: today),
        ],
      ],
    );
  }
}

class _HomeUrgentTaskTile extends StatelessWidget {
  const _HomeUrgentTaskTile({
    required this.task,
    required this.today,
  });

  final SiteTask task;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = TaskUrgency.of(task, today).color;

    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: () => showHomeTaskSummaryDialog(context, task: task),
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: AppRadii.xs,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  sentenceCaseTr(task.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (task.dueDate.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  task.dueDate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.statusInkOnCard(accent),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyReportQuickActions extends StatelessWidget {
  const _DailyReportQuickActions({
    required this.busy,
    required this.onDun,
    required this.onBugun,
    required this.onOzel,
  });

  final bool busy;
  final VoidCallback onDun;
  final VoidCallback onBugun;
  final VoidCallback onOzel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DailyReportPeriodButton(
                label: 'Dün',
                icon: Icons.history,
                busy: busy,
                onPressed: onDun,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _DailyReportPeriodButton(
                label: 'Bugün',
                icon: Icons.today_outlined,
                busy: busy,
                onPressed: onBugun,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _DailyReportPeriodButton(
                label: 'Özel tarih',
                icon: Icons.calendar_month_outlined,
                busy: busy,
                onPressed: onOzel,
              ),
            ),
          ],
        ),
        if (busy) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }
}

class _DailyReportPeriodButton extends StatelessWidget {
  const _DailyReportPeriodButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.primary;
    final bg = AppColors.electricBlue.withValues(alpha: 0.08);
    final border = AppColors.electricBlue.withValues(alpha: 0.35);

    return Material(
      color: bg,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: AppRadii.sm,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      onTap: onTap,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
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
                  maxLines: 1,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.statusInkOnCard(color),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: child,
      ),
    );
  }
}
