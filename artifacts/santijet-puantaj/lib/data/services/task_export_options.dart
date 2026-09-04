/// Görev PDF/Excel — sütun ve fotoğraf seçimleri.
enum TaskExportColumn {
  number,
  title,
  tag,
  category,
  assignee,
  plannedStart,
  actualStart,
  plannedEnd,
  actualEnd,
  status,
  description;

  /// PDF/Excel hücre başlığı (`\\n` = 2 satır).
  String get header => switch (this) {
        number => '#',
        title => 'Başlık',
        tag => 'Etiket',
        category => 'Kategori',
        assignee => 'Atanan',
        plannedStart => 'Planlanan\nBaşlangıç',
        actualStart => 'Gerçekleşen\nBaşlangıç',
        plannedEnd => 'Planlanan\nBitiş',
        actualEnd => 'Gerçekleşen\nBitiş',
        status => 'Durum',
        description => 'Açıklama',
      };

  /// Seçim listesinde gösterilen kısa ad.
  String get label => header.replaceAll('\n', ' ');

  bool get centerAlign => switch (this) {
        title || description => false,
        _ => true,
      };

  /// PDF sütun genişliği anahtarı — export servisinde çözülür.
  String get widthKind => switch (this) {
        number => 'number',
        title => 'title',
        tag => 'tag',
        category => 'category',
        assignee => 'assignee',
        plannedStart ||
        actualStart ||
        plannedEnd ||
        actualEnd =>
          'date',
        status => 'status',
        description => 'description',
      };

  double get excelWidth => switch (this) {
        number => 4,
        title => 22,
        tag => 11,
        category => 14,
        assignee => 16,
        plannedStart ||
        actualStart ||
        plannedEnd ||
        actualEnd =>
          14,
        status => 16,
        description => 36,
      };

  static const List<TaskExportColumn> all = TaskExportColumn.values;
}

class TaskExportOptions {
  const TaskExportOptions({
    required this.columns,
    this.includePhotos = true,
  });

  /// Seçili sütunlar — [TaskExportColumn.all] sırası korunur.
  final Set<TaskExportColumn> columns;
  final bool includePhotos;

  factory TaskExportOptions.all() => TaskExportOptions(
        columns: Set<TaskExportColumn>.from(TaskExportColumn.all),
        includePhotos: true,
      );

  factory TaskExportOptions.none() => const TaskExportOptions(
        columns: {},
        includePhotos: false,
      );

  bool get hasAnyColumn => columns.isNotEmpty;

  List<TaskExportColumn> get orderedColumns => [
        for (final c in TaskExportColumn.all)
          if (columns.contains(c)) c,
      ];

  TaskExportOptions copyWith({
    Set<TaskExportColumn>? columns,
    bool? includePhotos,
  }) {
    return TaskExportOptions(
      columns: columns ?? this.columns,
      includePhotos: includePhotos ?? this.includePhotos,
    );
  }

  TaskExportOptions toggleColumn(TaskExportColumn column, bool enabled) {
    final next = Set<TaskExportColumn>.from(columns);
    if (enabled) {
      next.add(column);
    } else {
      next.remove(column);
    }
    return copyWith(columns: next);
  }

  Map<String, dynamic> toJson() => {
        'columns': [for (final c in orderedColumns) c.name],
        'includePhotos': includePhotos,
      };

  factory TaskExportOptions.fromJson(Map<String, dynamic> json) {
    final raw = json['columns'];
    final parsed = <TaskExportColumn>{};
    if (raw is List) {
      for (final e in raw) {
        final name = e?.toString() ?? '';
        for (final c in TaskExportColumn.all) {
          if (c.name == name) {
            parsed.add(c);
            break;
          }
        }
      }
    }
    return TaskExportOptions(
      columns: parsed.isEmpty
          ? Set<TaskExportColumn>.from(TaskExportColumn.all)
          : parsed,
      includePhotos: json['includePhotos'] as bool? ?? true,
    );
  }
}
