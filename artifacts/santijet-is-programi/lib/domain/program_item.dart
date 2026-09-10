enum ProgramStatus {
  planned('Planlandı'),
  inProgress('Devam Ediyor'),
  completed('Tamamlandı'),
  delayed('Gecikti');

  const ProgramStatus(this.label);
  final String label;

  static ProgramStatus fromStorage(String value) => switch (value) {
    'in_progress' => inProgress,
    'completed' => completed,
    'delayed' => delayed,
    _ => planned,
  };

  String get storageValue => switch (this) {
    planned => 'planned',
    inProgress => 'in_progress',
    completed => 'completed',
    delayed => 'delayed',
  };
}

class ProgramItem {
  const ProgramItem({
    required this.id,
    required this.santiyeId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.plannedDays,
    required this.progress,
    required this.status,
    required this.responsible,
    this.notes,
    this.isStatusManual = false,
  });

  final String id;
  final String santiyeId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int? plannedDays;
  final int progress;
  final ProgramStatus status;
  final String responsible;
  final String? notes;

  /// Otomatik gecikme kararını kullanıcının durum seçimiyle ezmeye yarar.
  final bool isStatusManual;

  int get calculatedDays =>
      plannedDays ?? endDate.difference(startDate).inDays + 1;

  ProgramStatus effectiveStatus({DateTime? today}) {
    if (isStatusManual) return status;
    final day = _dateOnly(today ?? DateTime.now());
    if (progress >= 100) return ProgramStatus.completed;
    if (day.isAfter(_dateOnly(endDate))) {
      return ProgramStatus.delayed;
    }
    return status;
  }

  ProgramItem copyWith({
    String? id,
    String? santiyeId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    int? plannedDays,
    int? progress,
    ProgramStatus? status,
    String? responsible,
    String? notes,
    bool? isStatusManual,
  }) => ProgramItem(
    id: id ?? this.id,
    santiyeId: santiyeId ?? this.santiyeId,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    plannedDays: plannedDays ?? this.plannedDays,
    progress: progress ?? this.progress,
    status: status ?? this.status,
    responsible: responsible ?? this.responsible,
    notes: notes ?? this.notes,
    isStatusManual: isStatusManual ?? this.isStatusManual,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'santiyeId': santiyeId,
    'name': name,
    'startDate': _date(startDate),
    'endDate': _date(endDate),
    'plannedDays': plannedDays,
    'progress': progress,
    'status': status.storageValue,
    'responsible': responsible,
    'notes': notes,
    'isStatusManual': isStatusManual,
  };

  factory ProgramItem.fromJson(Map<String, dynamic> json) => ProgramItem(
    id: json['id'] as String,
    santiyeId: json['santiyeId'] as String,
    name: json['name'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    plannedDays: json['plannedDays'] as int?,
    progress: json['progress'] as int,
    status: ProgramStatus.fromStorage(json['status'] as String),
    responsible: json['responsible'] as String? ?? '',
    notes: json['notes'] as String?,
    isStatusManual: json['isStatusManual'] as bool? ?? false,
  );

  static String _date(DateTime value) =>
      value.toIso8601String().substring(0, 10);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class ProgramItemValidator {
  static String? name(String? value) =>
      value == null || value.trim().isEmpty ? 'Faaliyet adı zorunludur.' : null;

  static String? dates(DateTime start, DateTime end) =>
      end.isBefore(start) ? 'Bitiş, başlangıçtan önce olamaz.' : null;

  static String? progress(int value) =>
      value < 0 || value > 100 ? 'İlerleme 0–100 arasında olmalıdır.' : null;
}
