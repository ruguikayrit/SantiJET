/// Günlük şantiye raporu PDF — hangi başlıkların çıktıya gireceği.
class DailyReportExportSections {
  const DailyReportExportSections({
    this.weather = true,
    this.puantajCounts = true,
    this.puantajNames = true,
    this.photos = true,
    this.workDone = true,
    this.incomingMaterials = true,
    this.outgoingMaterials = true,
    this.orderedMaterials = true,
    this.machines = true,
    this.vehicles = true,
    this.nextDayPlan = true,
    this.signatures = true,
  });

  /// Tüm başlıklar seçili.
  factory DailyReportExportSections.all() => const DailyReportExportSections();

  /// Hiçbiri seçili değil (en az birini işaretlemesi gerekir).
  factory DailyReportExportSections.none() => const DailyReportExportSections(
        weather: false,
        puantajCounts: false,
        puantajNames: false,
        photos: false,
        workDone: false,
        incomingMaterials: false,
        outgoingMaterials: false,
        orderedMaterials: false,
        machines: false,
        vehicles: false,
        nextDayPlan: false,
        signatures: false,
      );

  final bool weather;
  final bool puantajCounts;
  final bool puantajNames;
  final bool photos;
  final bool workDone;
  final bool incomingMaterials;
  final bool outgoingMaterials;
  final bool orderedMaterials;
  final bool machines;
  final bool vehicles;
  final bool nextDayPlan;
  final bool signatures;

  bool get hasAny =>
      weather ||
      puantajCounts ||
      puantajNames ||
      photos ||
      workDone ||
      incomingMaterials ||
      outgoingMaterials ||
      orderedMaterials ||
      machines ||
      vehicles ||
      nextDayPlan ||
      signatures;

  DailyReportExportSections copyWith({
    bool? weather,
    bool? puantajCounts,
    bool? puantajNames,
    bool? photos,
    bool? workDone,
    bool? incomingMaterials,
    bool? outgoingMaterials,
    bool? orderedMaterials,
    bool? machines,
    bool? vehicles,
    bool? nextDayPlan,
    bool? signatures,
  }) {
    return DailyReportExportSections(
      weather: weather ?? this.weather,
      puantajCounts: puantajCounts ?? this.puantajCounts,
      puantajNames: puantajNames ?? this.puantajNames,
      photos: photos ?? this.photos,
      workDone: workDone ?? this.workDone,
      incomingMaterials: incomingMaterials ?? this.incomingMaterials,
      outgoingMaterials: outgoingMaterials ?? this.outgoingMaterials,
      orderedMaterials: orderedMaterials ?? this.orderedMaterials,
      machines: machines ?? this.machines,
      vehicles: vehicles ?? this.vehicles,
      nextDayPlan: nextDayPlan ?? this.nextDayPlan,
      signatures: signatures ?? this.signatures,
    );
  }

  Map<String, dynamic> toJson() => {
        'weather': weather,
        'puantajCounts': puantajCounts,
        'puantajNames': puantajNames,
        'photos': photos,
        'workDone': workDone,
        'incomingMaterials': incomingMaterials,
        'outgoingMaterials': outgoingMaterials,
        'orderedMaterials': orderedMaterials,
        'machines': machines,
        'vehicles': vehicles,
        'nextDayPlan': nextDayPlan,
        'signatures': signatures,
      };

  factory DailyReportExportSections.fromJson(Map<String, dynamic> json) {
    bool flag(String key, {bool fallback = true}) {
      final v = json[key];
      if (v is bool) return v;
      return fallback;
    }

    return DailyReportExportSections(
      weather: flag('weather'),
      puantajCounts: flag('puantajCounts'),
      puantajNames: flag('puantajNames'),
      photos: flag('photos'),
      workDone: flag('workDone'),
      incomingMaterials: flag('incomingMaterials'),
      outgoingMaterials: flag('outgoingMaterials'),
      orderedMaterials: flag('orderedMaterials'),
      machines: flag('machines'),
      vehicles: flag('vehicles'),
      nextDayPlan: flag('nextDayPlan'),
      signatures: flag('signatures'),
    );
  }
}
