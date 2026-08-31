import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../domain/catalogs/task_tags.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import 'task_export_options.dart';

/// PDF’te listenin altında gösterilecek görev fotoğraf grubu.
class TaskReportPhotoGroup {
  const TaskReportPhotoGroup({
    required this.index,
    required this.title,
    required this.photos,
  });

  final int index;
  final String title;
  final List<TaskPhoto> photos;
}

/// Görev dışa aktarma — etiket / durum / sütun filtresi.
class TaskReportData {
  const TaskReportData({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.columns,
    required this.rows,
    required this.fileStem,
    required this.tagLabel,
    required this.taskCount,
    this.photoGroups = const [],
  });

  final String title;
  final String subtitle;
  final List<String> headers;
  final List<TaskExportColumn> columns;
  final List<List<String>> rows;
  final String fileStem;
  final String tagLabel;
  final int taskCount;
  final List<TaskReportPhotoGroup> photoGroups;
}

/// Görünür saha görevlerinden PDF/Excel satırları üretir.
abstract final class TaskReportBuilder {
  /// [tagFilter] null → tüm etiketler; aksi halde katalog etiketi (ör. İnşaat).
  /// [statusFilter] null → tüm durumlar.
  static TaskReportData build({
    required String projectName,
    required List<SiteTask> tasks,
    String? tagFilter,
    TaskStatus? statusFilter,
    TaskExportOptions? options,
  }) {
    final opts = options ?? TaskExportOptions.all();
    final columns = opts.orderedColumns;

    final tag = tagFilter == null || tagFilter.isEmpty
        ? null
        : TaskTagCatalog.normalize(tagFilter);

    var list = List<SiteTask>.from(tasks);
    if (tag != null) {
      list = list
          .where((t) => TaskTagCatalog.normalize(t.tag) == tag)
          .toList();
    }
    if (statusFilter != null) {
      list = list.where((t) => t.status == statusFilter).toList();
    }

    list.sort((a, b) {
      final byStatus = a.status.index.compareTo(b.status.index);
      if (byStatus != 0) return byStatus;
      final ad = PuantajDate.tryParse(a.dueDate);
      final bd = PuantajDate.tryParse(b.dueDate);
      if (ad != null && bd != null) return ad.compareTo(bd);
      if (ad != null) return -1;
      if (bd != null) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    final tagLabel = tag == null
        ? 'Tüm etiketler'
        : TaskTagCatalog.cardLabel(tag);
    final statusLabel =
        statusFilter == null ? 'Tüm durumlar' : statusFilter.label;
    final today = PuantajDate.today();
    final stemTag = tag == null
        ? 'tum'
        : switch (tag) {
            TaskTagCatalog.insaat => 'insaat',
            TaskTagCatalog.elektrik => 'elektrik',
            TaskTagCatalog.mekanik => 'mekanik',
            _ => 'etiket',
          };

    final headers = [for (final c in columns) c.header];
    final rows = <List<String>>[
      for (var i = 0; i < list.length; i++)
        [
          for (final c in columns) _cellValue(list[i], c, i + 1),
        ],
    ];

    final photoGroups = !opts.includePhotos
        ? const <TaskReportPhotoGroup>[]
        : <TaskReportPhotoGroup>[
            for (var i = 0; i < list.length; i++)
              if (list[i].photos.any((p) => p.dataBase64.trim().isNotEmpty))
                TaskReportPhotoGroup(
                  index: i + 1,
                  title: sentenceCaseTr(list[i].title),
                  photos: [
                    for (final p in list[i].photos)
                      if (p.dataBase64.trim().isNotEmpty) p,
                  ],
                ),
          ];

    return TaskReportData(
      title: 'Saha Görevleri — $tagLabel',
      subtitle: '$projectName · $statusLabel · $today',
      headers: headers,
      columns: columns,
      rows: rows,
      fileStem: 'gorev-$stemTag-${today.replaceAll('.', '')}',
      tagLabel: tagLabel,
      taskCount: list.length,
      photoGroups: photoGroups,
    );
  }

  static String _cellValue(SiteTask task, TaskExportColumn column, int index) {
    return switch (column) {
      TaskExportColumn.number => '$index',
      TaskExportColumn.title => sentenceCaseTr(task.title),
      TaskExportColumn.tag => task.tag.trim().isEmpty
          ? '—'
          : TaskTagCatalog.cardLabel(task.tag),
      TaskExportColumn.category => task.category.trim().isEmpty
          ? '—'
          : titleCaseTr(task.category),
      TaskExportColumn.assignee => task.assignee.trim().isEmpty
          ? '—'
          : titleCaseTr(task.assignee),
      TaskExportColumn.plannedStart =>
        task.earliestStart.isEmpty ? '—' : task.earliestStart,
      TaskExportColumn.actualStart => task.actualStartDate.trim().isEmpty
          ? '—'
          : task.actualStartDate.trim(),
      TaskExportColumn.plannedEnd =>
        task.dueDate.isEmpty ? '—' : task.dueDate,
      TaskExportColumn.actualEnd => task.actualDeliveryDate.trim().isEmpty
          ? '—'
          : task.actualDeliveryDate.trim(),
      TaskExportColumn.status => task.status.label,
      TaskExportColumn.description => task.description.trim().isEmpty
          ? '—'
          : task.description.trim(),
    };
  }
}
