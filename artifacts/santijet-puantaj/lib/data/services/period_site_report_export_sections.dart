/// Haftalık / aylık saha raporu PDF/Excel — hangi başlıkların çıktıya gireceği.
class PeriodSiteReportExportSections {
  const PeriodSiteReportExportSections({
    this.puantajCounts = true,
    this.personel = true,
    this.ekip = true,
    this.yevmiyeli = true,
    this.machines = true,
    this.vehicles = true,
    this.imalat = true,
    this.verim = true,
  });

  factory PeriodSiteReportExportSections.all() =>
      const PeriodSiteReportExportSections();

  factory PeriodSiteReportExportSections.none() =>
      const PeriodSiteReportExportSections(
        puantajCounts: false,
        personel: false,
        ekip: false,
        yevmiyeli: false,
        machines: false,
        vehicles: false,
        imalat: false,
        verim: false,
      );

  final bool puantajCounts;
  final bool personel;
  final bool ekip;
  final bool yevmiyeli;
  final bool machines;
  final bool vehicles;
  final bool imalat;
  final bool verim;

  bool get hasAny =>
      puantajCounts ||
      personel ||
      ekip ||
      yevmiyeli ||
      machines ||
      vehicles ||
      imalat ||
      verim;

  PeriodSiteReportExportSections copyWith({
    bool? puantajCounts,
    bool? personel,
    bool? ekip,
    bool? yevmiyeli,
    bool? machines,
    bool? vehicles,
    bool? imalat,
    bool? verim,
  }) {
    return PeriodSiteReportExportSections(
      puantajCounts: puantajCounts ?? this.puantajCounts,
      personel: personel ?? this.personel,
      ekip: ekip ?? this.ekip,
      yevmiyeli: yevmiyeli ?? this.yevmiyeli,
      machines: machines ?? this.machines,
      vehicles: vehicles ?? this.vehicles,
      imalat: imalat ?? this.imalat,
      verim: verim ?? this.verim,
    );
  }

  Map<String, dynamic> toJson() => {
        'puantajCounts': puantajCounts,
        'personel': personel,
        'ekip': ekip,
        'yevmiyeli': yevmiyeli,
        'machines': machines,
        'vehicles': vehicles,
        'imalat': imalat,
        'verim': verim,
      };

  factory PeriodSiteReportExportSections.fromJson(Map<String, dynamic> json) {
    bool flag(String key, {bool fallback = true}) {
      final v = json[key];
      if (v is bool) return v;
      return fallback;
    }

    return PeriodSiteReportExportSections(
      puantajCounts: flag('puantajCounts'),
      personel: flag('personel'),
      ekip: flag('ekip'),
      yevmiyeli: flag('yevmiyeli'),
      machines: flag('machines'),
      vehicles: flag('vehicles'),
      imalat: flag('imalat'),
      verim: flag('verim'),
    );
  }
}
