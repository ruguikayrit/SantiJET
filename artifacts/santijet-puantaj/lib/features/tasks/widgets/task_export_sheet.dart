import 'package:flutter/material.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/task_export_service.dart';
import '../../../data/services/task_report_builder.dart';
import '../../../domain/catalogs/task_tags.dart';
import '../../../domain/entities/site_task.dart';
import '../../../domain/enums/task_status.dart';

/// Puantaj AL ile aynı kurgu — etiket filtresi + PDF / Excel.
class TaskExportSheet extends StatefulWidget {
  const TaskExportSheet({
    required this.projectName,
    required this.tasks,
    this.initialTag,
    super.key,
  });

  final String projectName;
  final List<SiteTask> tasks;

  /// null = tüm etiketler; verilmezse İnşaat seçili açılır.
  final String? initialTag;

  @override
  State<TaskExportSheet> createState() => _TaskExportSheetState();
}

class _TaskExportSheetState extends State<TaskExportSheet> {
  late String? _tag = widget.initialTag ?? TaskTagCatalog.insaat;
  TaskStatus? _status;
  bool _busy = false;
  String? _error;

  int get _previewCount {
    return TaskReportBuilder.build(
      projectName: widget.projectName,
      tasks: widget.tasks,
      tagFilter: _tag,
      statusFilter: _status,
    ).taskCount;
  }

  Future<void> _export({required bool pdf}) async {
    final report = TaskReportBuilder.build(
      projectName: widget.projectName,
      tasks: widget.tasks,
      tagFilter: _tag,
      statusFilter: _status,
    );
    if (report.taskCount == 0) {
      setState(() {
        _error = 'Seçilen filtrede dışa aktarılacak görev yok.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (pdf) {
        await taskExportService.exportPdf(report);
      } else {
        await taskExportService.exportExcel(report);
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
    final count = _previewCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.projectName} · $count görev',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Etiket (disiplin)', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Örnek: yalnızca İnşaat saha görevlerini seçip PDF veya Excel alın.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _TagChoice(
              label: 'Tümü',
              selected: _tag == null,
              color: theme.colorScheme.primary,
              onTap: _busy ? null : () => setState(() => _tag = null),
            ),
            ...TaskTagCatalog.all.map(
              (t) => _TagChoice(
                label: TaskTagCatalog.cardLabel(t),
                selected: _tag == t,
                color: TaskTagCatalog.accentFor(t),
                onTap: _busy ? null : () => setState(() => _tag = t),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Durum', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<String>(
          style: SegmentedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            selectedForegroundColor: theme.colorScheme.onSecondary,
            selectedBackgroundColor: theme.colorScheme.secondary,
          ),
          segments: const [
            ButtonSegment(value: 'all', label: Text('Tümü')),
            ButtonSegment(value: 'todo', label: Text('Yapılacak')),
            ButtonSegment(value: 'started', label: Text('Başlandı')),
            ButtonSegment(value: 'doing', label: Text('Devam')),
            ButtonSegment(value: 'done', label: Text('Bitti')),
          ],
          selected: {_status == null ? 'all' : _status!.name},
          onSelectionChanged: _busy
              ? null
              : (s) {
                  final v = s.first;
                  setState(() {
                    _status = switch (v) {
                      'todo' => TaskStatus.todo,
                      'started' => TaskStatus.started,
                      'doing' => TaskStatus.doing,
                      'done' => TaskStatus.done,
                      _ => null,
                    };
                    _error = null;
                  });
                },
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

class _TagChoice extends StatelessWidget {
  const _TagChoice({
    required this.label,
    required this.selected,
    required this.color,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.08),
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.75 : 0.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 16, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
