import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../domain/catalogs/task_tags.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';

/// Görev dışa aktarma — etiket / durum filtresi.
class TaskReportData {
  const TaskReportData({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
    required this.fileStem,
    required this.tagLabel,
    required this.taskCount,
  });

  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final String fileStem;
  final String tagLabel;
  final int taskCount;
}

/// Görünür saha görevlerinden PDF/Excel satırları üretir.
abstract final class TaskReportBuilder {
  static const headers = [
    '#',
    'Başlık',
    'Etiket',
    'Kategori',
    'Atanan',
    'Başlangıç',
    'Planlanan bitiş',
    'Durum',
    'Açıklama',
  ];

  /// [tagFilter] null → tüm etiketler; aksi halde katalog etiketi (ör. İnşaat).
  /// [statusFilter] null → tüm durumlar.
  static TaskReportData build({
    required String projectName,
    required List<SiteTask> tasks,
    String? tagFilter,
    TaskStatus? statusFilter,
  }) {
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

    final rows = <List<String>>[
      for (var i = 0; i < list.length; i++)
        [
          '${i + 1}',
          sentenceCaseTr(list[i].title),
          list[i].tag.trim().isEmpty
              ? '—'
              : TaskTagCatalog.cardLabel(list[i].tag),
          list[i].category.trim().isEmpty
              ? '—'
              : titleCaseTr(list[i].category),
          list[i].assignee.trim().isEmpty
              ? '—'
              : titleCaseTr(list[i].assignee),
          list[i].earliestStart.isEmpty ? '—' : list[i].earliestStart,
          list[i].dueDate.isEmpty ? '—' : list[i].dueDate,
          list[i].status.label,
          list[i].description.trim().isEmpty
              ? '—'
              : list[i].description.trim(),
        ],
    ];

    return TaskReportData(
      title: 'Saha Görevleri — $tagLabel',
      subtitle: '$projectName · $statusLabel · $today',
      headers: headers,
      rows: rows,
      fileStem: 'gorev-$stemTag-${today.replaceAll('.', '')}',
      tagLabel: tagLabel,
      taskCount: list.length,
    );
  }
}
