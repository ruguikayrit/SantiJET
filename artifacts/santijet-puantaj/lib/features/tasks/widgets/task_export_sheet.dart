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

/// Görev AL — etiket / durum (çoklu) / sütun / fotoğraf + PDF / Excel.
class TaskExportSheet extends ConsumerStatefulWidget {
  const TaskExportSheet({
    required this.projectName,
    required this.tasks,
    this.initialTag,
    super.key,
  });

  final String projectName;
  final List<SiteTask> tasks;

  /// null = tüm etiketler (varsayılan); doluysa başlangıçta o etiket seçili.
  final String? initialTag;

  @override
  ConsumerState<TaskExportSheet> createState() => _TaskExportSheetState();
}

class _TaskExportSheetState extends ConsumerState<TaskExportSheet> {
  /// Boş = tüm etiketler.
  late Set<String> _tags = widget.initialTag == null ||
          widget.initialTag!.trim().isEmpty
      ? <String>{}
      : {TaskTagCatalog.normalize(widget.initialTag!)};

  /// Boş = tüm durumlar.
  Set<TaskStatus> _statuses = {};
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
      tagFilters: _tags,
      statusFilters: _statuses,
      options: _options,
    ).taskCount;
  }

  void _onTagSelectionChanged(Set<String> next) {
    final wasAll = _tags.isEmpty;
    final nextHasAll = next.contains('all');
    final specifics = next.where((e) => e != 'all').toSet();

    setState(() {
      if (nextHasAll && !wasAll) {
        _tags = {};
      } else if (nextHasAll && wasAll && specifics.isNotEmpty) {
        _tags = specifics;
      } else if (!nextHasAll && specifics.isEmpty) {
        _tags = {};
      } else {
        _tags = specifics;
      }
      _error = null;
    });
  }

  void _onStatusSelectionChanged(Set<String> next) {
    final wasAll = _statuses.isEmpty;
    final nextHasAll = next.contains('all');
    final specifics = <TaskStatus>{
      for (final v in next)
        if (v == 'todo')
          TaskStatus.todo
        else if (v == 'started')
          TaskStatus.started
        else if (v == 'doing')
          TaskStatus.doing
        else if (v == 'done')
          TaskStatus.done,
    };

    setState(() {
      if (nextHasAll && !wasAll) {
        _statuses = {};
      } else if (nextHasAll && wasAll && specifics.isNotEmpty) {
        _statuses = specifics;
      } else if (!nextHasAll && specifics.isEmpty) {
        _statuses = {};
      } else {
        _statuses = specifics;
      }
      _error = null;
    });
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
      tagFilters: _tags,
      statusFilters: _statuses,
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

  ButtonStyle _filterSegStyle(ThemeData theme) {
    return SegmentedButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurfaceVariant,
      selectedForegroundColor: theme.colorScheme.onSecondary,
      selectedBackgroundColor: theme.colorScheme.secondary,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontSize: (theme.textTheme.labelLarge?.fontSize ?? 14) - 2,
        height: 1.1,
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _previewCount;
    final tagSelected =
        _tags.isEmpty ? {'all'} : Set<String>.from(_tags);
    final statusSelected = _statuses.isEmpty
        ? {'all'}
        : {for (final s in _statuses) s.name};

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
          'Son sütun seçimleri hatırlanır. Etiket ve durumda birden fazla seçebilirsiniz.',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Etiket', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<String>(
          multiSelectionEnabled: true,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          style: _filterSegStyle(theme),
          segments: [
            ButtonSegment(
              value: 'all',
              label: Text('Tümü', style: _segLabelStyle(theme), maxLines: 1),
            ),
            for (final t in TaskTagCatalog.all)
              ButtonSegment(
                value: t,
                label: Text(
                  TaskTagCatalog.cardLabel(t),
                  style: _segLabelStyle(theme),
                  maxLines: 1,
                ),
              ),
          ],
          selected: tagSelected,
          onSelectionChanged: _busy ? null : _onTagSelectionChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Durum', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<String>(
          multiSelectionEnabled: true,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          style: _filterSegStyle(theme),
          segments: [
            ButtonSegment(
              value: 'all',
              label: Text('Tümü', style: _segLabelStyle(theme), maxLines: 1),
            ),
            ButtonSegment(
              value: 'todo',
              label: Text(
                'Yapılacak',
                style: _segLabelStyle(theme),
                maxLines: 1,
              ),
            ),
            ButtonSegment(
              value: 'started',
              label: Text(
                'Başladı',
                style: _segLabelStyle(theme),
                maxLines: 1,
              ),
            ),
            ButtonSegment(
              value: 'doing',
              label: Text('Devam', style: _segLabelStyle(theme), maxLines: 1),
            ),
            ButtonSegment(
              value: 'done',
              label: Text('Bitti', style: _segLabelStyle(theme), maxLines: 1),
            ),
          ],
          selected: statusSelected,
          onSelectionChanged: _busy ? null : _onStatusSelectionChanged,
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
        const SizedBox(height: AppSpacing.md),
        Text('Ek içerik', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: _options.includePhotos
              ? AppColors.electricBlue.withValues(alpha: 0.10)
              : AppColors.surfaceElevated,
          borderRadius: AppRadii.sm,
          child: InkWell(
            borderRadius: AppRadii.sm,
            onTap: _busy
                ? null
                : () => setState(() {
                      _options = _options.copyWith(
                        includePhotos: !_options.includePhotos,
                      );
                      _error = null;
                    }),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (_options.includePhotos
                              ? AppColors.electricBlue
                              : theme.colorScheme.onSurfaceVariant)
                          .withValues(alpha: 0.14),
                      borderRadius: AppRadii.sm,
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: _options.includePhotos
                          ? AppColors.electricBlue
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fotoğraflar',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'PDF / Excel çıktısına görev fotoğraflarını ekle',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _options.includePhotos,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                              _options =
                                  _options.copyWith(includePhotos: v);
                              _error = null;
                            }),
                  ),
                ],
              ),
            ),
          ),
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
        const SizedBox(height: AppSpacing.sm),
        SJButton(
          label: 'İptal',
          variant: SJButtonVariant.ghost,
          expanded: true,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
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

TextStyle? _segLabelStyle(ThemeData theme) {
  final base = theme.textTheme.labelLarge;
  return base?.copyWith(
    fontSize: (base.fontSize ?? 14) - 2,
    height: 1.1,
  );
}
