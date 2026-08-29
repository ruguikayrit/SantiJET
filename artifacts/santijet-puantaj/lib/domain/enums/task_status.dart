/// Saha görevi durumu.
enum TaskStatus {
  todo,
  started,
  doing,
  done;

  String get label => switch (this) {
        TaskStatus.todo => 'Yapılacak',
        TaskStatus.started => 'Başlandı',
        TaskStatus.doing => 'Devam ediyor',
        TaskStatus.done => 'Tamamlandı',
      };

  /// Kartta kısa etiket (dar düzen).
  String get shortLabel => switch (this) {
        TaskStatus.todo => 'Yapılacak',
        TaskStatus.started => 'Başlandı',
        TaskStatus.doing => 'Devam',
        TaskStatus.done => 'Bitti',
      };

  static TaskStatus fromStorage(String? raw) {
    return switch (raw) {
      'started' => TaskStatus.started,
      'doing' => TaskStatus.doing,
      'done' => TaskStatus.done,
      _ => TaskStatus.todo,
    };
  }

  String get storage => name;
}

/// Zorunlu sıra ve tarih kuralları.
abstract final class TaskStatusRules {
  /// [from] → [to] geçişi izinli mi?
  static bool canTransition(TaskStatus from, TaskStatus to) {
    if (from == to) return false;
    return switch ((from, to)) {
      (TaskStatus.todo, TaskStatus.started) => true,
      (TaskStatus.started, TaskStatus.todo) => true,
      (TaskStatus.started, TaskStatus.doing) => true,
      (TaskStatus.started, TaskStatus.done) => true,
      (TaskStatus.doing, TaskStatus.todo) => true,
      (TaskStatus.doing, TaskStatus.done) => true,
      (TaskStatus.done, TaskStatus.todo) => true,
      _ => false,
    };
  }

  /// Gerçekleşen tarih seçimi gerekir mi?
  static bool needsActualDate(TaskStatus to) =>
      to == TaskStatus.started || to == TaskStatus.done;

  static String dateSheetTitle(TaskStatus to) => switch (to) {
        TaskStatus.started => 'Gerçekleşen başlangıç tarihi',
        TaskStatus.done => 'Gerçekleşen bitiş tarihi',
        _ => 'Tarih',
      };
}
