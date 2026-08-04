/// Saha görevi durumu.
enum TaskStatus {
  todo,
  doing,
  done;

  String get label => switch (this) {
        TaskStatus.todo => 'Yapılacak',
        TaskStatus.doing => 'Devam ediyor',
        TaskStatus.done => 'Tamamlandı',
      };

  static TaskStatus fromStorage(String? raw) {
    return switch (raw) {
      'doing' => TaskStatus.doing,
      'done' => TaskStatus.done,
      _ => TaskStatus.todo,
    };
  }

  String get storage => name;
}
