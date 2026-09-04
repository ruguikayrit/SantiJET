import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/task_export_options_provider.dart';
import '../../../data/services/task_export_options.dart';
import '../../../data/services/task_export_service.dart';
import '../../../data/services/task_report_builder.dart';
import '../../../domain/catalogs/task_tags.dart';
import '../../../domain/entities/site_task.dart';
import '../../../domain/enums/task_status.dart';

/// Görev AL — etiket / durum / sütun / fotoğraf + PDF / Excel.
class TaskExportSheet extends ConsumerStatefulWidget {
  const TaskExportSheet({
    required this.projectName,
    required this.tasks,
    this.initialTag,
    super.key,
  });

  final String projectName;
  final List<SiteTask> tasks;

  /// null = tüm etiketler (varsayılan).
  final String? initialTag;

  @override
  ConsumerState<TaskExportSheet> createState() => _TaskExportSheetState();
}

class _TaskExportSheetState extends ConsumerState<TaskExportSheet> {
  late String? _tag = widget.initialTag;
  TaskStatus? _status;
  late TaskExportOptions _options;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _options = ref.read(taskExportOptionsProvider);
  }

  int get _previewCount {
    return TaskReportBuilder.build(
      projectName: widget.projectName,
      tasks: widget.tasks,
      tagFilter: _tag,
      statusFilter: _status,
      options: _options,
    ).taskCount;
  }

  Future<void> _showExportBusyDialog({required bool pdf}) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  pdf ? 'PDF hazırlanıyor…' : 'Excel hazırlanıyor…',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Dosya boyutu (görev sayısı ve fotoğraflar) nedeniyle '
                  'bu işlem biraz sürebilir. Uygulama donmadı; lütfen bekleyin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _export({required bool pdf}) async {
    if (_busy) return;
    if (!_options.hasAnyColumn) {
      setState(() => _error = 'En az bir sütun seçin.');
      return;
    }
    final report = TaskReportBuilder.build(
      projectName: widget.projectName,
      tasks: widget.tasks,
      tagFilter: _tag,
      statusFilter: _status,
      options: _options,
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
    // Önce buton/loading durumunun çizilmesi için bir kare bekle.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    // ignore: unawaited_futures
    _showExportBusyDialog(pdf: pdf);

    var exported = false;
    try {
      ref.read(taskExportOptionsProvider.notifier).save(_options);
      if (pdf) {
        await taskExportService.exportPdf(report);
      } else {
        await taskExportService.exportExcel(report);
      }
      exported = true;
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
        setState(() => _busy = false);
      }
    }

    if (!exported || !mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pdf ? 'PDF dışa aktarıldı.' : 'Excel dışa aktarıldı.',
        ),
      ),
    );
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Son seçimler hatırlanır.',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Etiket', style: theme.textTheme.labelLarge),
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
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            selectedForegroundColor: theme.colorScheme.onSecondary,
            selectedBackgroundColor: theme.colorScheme.secondary,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontSize: (theme.textTheme.labelLarge?.fontSize ?? 14) - 2,
              height: 1.1,
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          segments: [
            ButtonSegment(
              value: 'all',
              label: Text('Tümü', style: _statusSegStyle(theme), maxLines: 1),
            ),
            ButtonSegment(
              value: 'todo',
              label:
                  Text('Yapılacak', style: _statusSegStyle(theme), maxLines: 1),
            ),
            ButtonSegment(
              value: 'started',
              label:
                  Text('Başlandı', style: _statusSegStyle(theme), maxLines: 1),
            ),
            ButtonSegment(
              value: 'doing',
              label: Text('Devam', style: _statusSegStyle(theme), maxLines: 1),
            ),
            ButtonSegment(
              value: 'done',
              label: Text('Bitti', style: _statusSegStyle(theme), maxLines: 1),
            ),
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
        Row(
          children: [
            Expanded(
              child: Text('Sütunlar', style: theme.textTheme.labelLarge),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _options = TaskExportOptions.all()
                            .copyWith(includePhotos: _options.includePhotos);
                        _error = null;
                      }),
              child: const Text('Tümü'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _options = _options.copyWith(columns: {});
                        _error = null;
                      }),
              child: const Text('Temizle'),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.28,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final column in TaskExportColumn.all)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(column.label),
                  value: _options.columns.contains(column),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                            _options =
                                _options.toggleColumn(column, v ?? false);
                            _error = null;
                          }),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Fotoğraflar'),
          value: _options.includePhotos,
          onChanged: _busy
              ? null
              : (v) => setState(() {
                    _options = _options.copyWith(includePhotos: v ?? false);
                    _error = null;
                  }),
          controlAffinity: ListTileControlAffinity.leading,
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
                onPressed: _busy ? null : () => _export(pdf: true),
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
                onPressed: _busy ? null : () => _export(pdf: false),
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

TextStyle? _statusSegStyle(ThemeData theme) {
  final base = theme.textTheme.labelLarge;
  return base?.copyWith(
    fontSize: (base.fontSize ?? 14) - 2,
    height: 1.1,
  );
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
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
