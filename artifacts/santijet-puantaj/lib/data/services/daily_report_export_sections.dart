/// Günlük şantiye raporu PDF — hangi başlıkların çıktıya gireceği.
class DailyReportExportSections {
  const DailyReportExportSections({
    this.weather = true,
    this.puantajCounts = true,
    this.personel = true,
    this.ekip = true,
    this.yevmiyeli = true,
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
        personel: false,
        ekip: false,
        yevmiyeli: false,
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
  /// Durum sayıları · adam-saat · yevmiye (eski “Puantaj — sayılar”).
  final bool puantajCounts;
  final bool personel;
  final bool ekip;
  final bool yevmiyeli;
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
      personel ||
      ekip ||
      yevmiyeli ||
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
    bool? personel,
    bool? ekip,
    bool? yevmiyeli,
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
      personel: personel ?? this.personel,
      ekip: ekip ?? this.ekip,
      yevmiyeli: yevmiyeli ?? this.yevmiyeli,
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
        'personel': personel,
        'ekip': ekip,
        'yevmiyeli': yevmiyeli,
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
    bool flag(String key, {bool? fallback}) {
      final v = json[key];
      if (v is bool) return v;
      if (fallback != null) return fallback;
      return true;
    }

    // Eski “Puantaj — isimler” → personel + ekip.
    final legacyNames = json['puantajNames'];
    final namesFallback = legacyNames is bool ? legacyNames : true;

    return DailyReportExportSections(
      weather: flag('weather'),
      puantajCounts: flag('puantajCounts'),
      personel: flag('personel', fallback: namesFallback),
      ekip: flag('ekip', fallback: namesFallback),
      yevmiyeli: flag('yevmiyeli'),
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
