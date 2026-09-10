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
    this.plannedCrew = 1,
    required this.progress,
    required this.status,
    required this.responsible,
    this.notes,
    this.isStatusManual = false,
    this.wbs,
    this.outlineLevel = 1,
    this.isMilestone = false,
    this.msProjectUid,
    this.predecessors,
    this.actualStart,
    this.actualFinish,
    this.actualDuration,
    this.remainingDuration,
    this.actualWork,
    this.remainingWork,
  });

  final String id;
  final String santiyeId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int? plannedDays;

  /// Planlanan günlük ekip. Adam-gün = süre × ekip.
  final int plannedCrew;
  final int progress;
  final ProgramStatus status;
  final String responsible;
  final String? notes;

  /// Otomatik gecikme kararını kullanıcının durum seçimiyle ezmeye yarar.
  final bool isStatusManual;

  /// MS Project WBS / anahat kodu, ör. `1.2`.
  final String? wbs;

  /// MS Project anahat düzeyi. Kök faaliyetler 1'dir.
  final int outlineLevel;

  /// Süresi sıfır olan kilometre taşı faaliyeti.
  final bool isMilestone;

  /// İçe aktarılan dosyadaki görev kimliği; dışa aktarımda korunur.
  final int? msProjectUid;

  /// MS Project öncül metni, ör. `2FS+3 gün`. Uygulama hesaplamaz,
  /// yalnız dosyalar arasında taşır.
  final String? predecessors;

  /// İzleme tablosu — Project Actual Start / Finish / Duration / Work.
  final DateTime? actualStart;
  final DateTime? actualFinish;
  final int? actualDuration;
  final int? remainingDuration;
  final int? actualWork;
  final int? remainingWork;

  int get calculatedDays =>
      plannedDays ?? endDate.difference(startDate).inDays + 1;

  /// İş programının birimi: süre × ekip.
  int get plannedManDays =>
      isMilestone ? 0 : calculatedDays * (plannedCrew < 1 ? 1 : plannedCrew);

  /// Süre değişince bitiş, başlangıç + süre − 1 olur. Süre 0 ise bitiş
  /// başlangıçtır (kilometre taşı).
  static DateTime endDateFromDuration(DateTime start, int days) {
    final day = DateTime(start.year, start.month, start.day);
    if (days <= 0) return day;
    return day.add(Duration(days: days - 1));
  }

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
    int? plannedCrew,
    int? progress,
    ProgramStatus? status,
    String? responsible,
    String? notes,
    bool? isStatusManual,
    String? wbs,
    int? outlineLevel,
    bool? isMilestone,
    int? msProjectUid,
    String? predecessors,
    Object? actualStart = _keep,
    Object? actualFinish = _keep,
    Object? actualDuration = _keep,
    Object? remainingDuration = _keep,
    Object? actualWork = _keep,
    Object? remainingWork = _keep,
  }) => ProgramItem(
    id: id ?? this.id,
    santiyeId: santiyeId ?? this.santiyeId,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    plannedDays: plannedDays ?? this.plannedDays,
    plannedCrew: plannedCrew ?? this.plannedCrew,
    progress: progress ?? this.progress,
    status: status ?? this.status,
    responsible: responsible ?? this.responsible,
    notes: notes ?? this.notes,
    isStatusManual: isStatusManual ?? this.isStatusManual,
    wbs: wbs ?? this.wbs,
    outlineLevel: outlineLevel ?? this.outlineLevel,
    isMilestone: isMilestone ?? this.isMilestone,
    msProjectUid: msProjectUid ?? this.msProjectUid,
    predecessors: predecessors ?? this.predecessors,
    actualStart: identical(actualStart, _keep)
        ? this.actualStart
        : actualStart as DateTime?,
    actualFinish: identical(actualFinish, _keep)
        ? this.actualFinish
        : actualFinish as DateTime?,
    actualDuration: identical(actualDuration, _keep)
        ? this.actualDuration
        : actualDuration as int?,
    remainingDuration: identical(remainingDuration, _keep)
        ? this.remainingDuration
        : remainingDuration as int?,
    actualWork: identical(actualWork, _keep)
        ? this.actualWork
        : actualWork as int?,
    remainingWork: identical(remainingWork, _keep)
        ? this.remainingWork
        : remainingWork as int?,
  );

  static const _keep = Object();

  Map<String, dynamic> toJson() => {
    'id': id,
    'santiyeId': santiyeId,
    'name': name,
    'startDate': _date(startDate),
    'endDate': _date(endDate),
    'plannedDays': plannedDays,
    'plannedCrew': plannedCrew,
    'progress': progress,
    'status': status.storageValue,
    'responsible': responsible,
    'notes': notes,
    'isStatusManual': isStatusManual,
    'wbs': wbs,
    'outlineLevel': outlineLevel,
    'isMilestone': isMilestone,
    'msProjectUid': msProjectUid,
    'predecessors': predecessors,
    'actualStart': actualStart == null ? null : _date(actualStart!),
    'actualFinish': actualFinish == null ? null : _date(actualFinish!),
    'actualDuration': actualDuration,
    'remainingDuration': remainingDuration,
    'actualWork': actualWork,
    'remainingWork': remainingWork,
  };

  factory ProgramItem.fromJson(Map<String, dynamic> json) => ProgramItem(
    id: json['id'] as String,
    santiyeId: json['santiyeId'] as String,
    name: json['name'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    plannedDays: json['plannedDays'] as int?,
    plannedCrew: json['plannedCrew'] as int? ?? 1,
    progress: json['progress'] as int,
    status: ProgramStatus.fromStorage(json['status'] as String),
    responsible: json['responsible'] as String? ?? '',
    notes: json['notes'] as String?,
    isStatusManual: json['isStatusManual'] as bool? ?? false,
    wbs: json['wbs'] as String?,
    outlineLevel: json['outlineLevel'] as int? ?? 1,
    isMilestone: json['isMilestone'] as bool? ?? false,
    msProjectUid: json['msProjectUid'] as int?,
    predecessors: json['predecessors'] as String?,
    actualStart: json['actualStart'] == null
        ? null
        : DateTime.tryParse(json['actualStart'] as String),
    actualFinish: json['actualFinish'] == null
        ? null
        : DateTime.tryParse(json['actualFinish'] as String),
    actualDuration: json['actualDuration'] as int?,
    remainingDuration: json['remainingDuration'] as int?,
    actualWork: json['actualWork'] as int?,
    remainingWork: json['remainingWork'] as int?,
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

  static String? duration(int value, {bool milestone = false}) {
    if (milestone) {
      return value < 0 ? 'Süre negatif olamaz.' : null;
    }
    return value < 1 ? 'Süre en az 1 gün olmalıdır.' : null;
  }

  static String? crew(int value) =>
      value < 1 ? 'Ekip en az 1 adam olmalıdır.' : null;
}
