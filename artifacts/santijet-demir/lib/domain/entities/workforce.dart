/// Kalfa hariç usta / düz işçi adam-saat bileşenleri.
class WorkforceCrewHours {
  const WorkforceCrewHours({
    this.tam = 0,
    this.yarim = 0,
    this.mesaiKisi = 0,
    this.mesaiSaat = 0,
  });

  /// Tam gün çalışan kişi sayısı.
  final int tam;

  /// Yarım gün çalışan kişi sayısı.
  final int yarim;

  /// Mesai yapan kişi sayısı.
  final int mesaiKisi;

  /// Mesai süresi (saat) — kişi ile çarpılır.
  final double mesaiSaat;

  /// Ham adam-saat: tam×8 + yarım×4 + mesai_saat×mesai_kişi.
  double get manHours =>
      (tam * 8) + (yarim * 4) + (mesaiSaat * mesaiKisi);

  /// Gösterim / tahmin birimi: adam-gün = adam-saat / 8.
  double get adamGun => manHours / 8.0;

  bool get isEmpty =>
      tam <= 0 && yarim <= 0 && mesaiKisi <= 0 && mesaiSaat <= 0;

  WorkforceCrewHours copyWith({
    int? tam,
    int? yarim,
    int? mesaiKisi,
    double? mesaiSaat,
  }) {
    return WorkforceCrewHours(
      tam: tam ?? this.tam,
      yarim: yarim ?? this.yarim,
      mesaiKisi: mesaiKisi ?? this.mesaiKisi,
      mesaiSaat: mesaiSaat ?? this.mesaiSaat,
    );
  }

  Map<String, dynamic> toJson() => {
        'tam': tam,
        'yarim': yarim,
        'mesaiKisi': mesaiKisi,
        'mesaiSaat': mesaiSaat,
      };

  factory WorkforceCrewHours.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const WorkforceCrewHours();
    return WorkforceCrewHours(
      tam: (json['tam'] as num?)?.toInt() ?? 0,
      yarim: (json['yarim'] as num?)?.toInt() ?? 0,
      mesaiKisi: (json['mesaiKisi'] as num?)?.toInt() ?? 0,
      mesaiSaat: (json['mesaiSaat'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Gün × imalat çalışma satırı.
class WorkforceImalatLine {
  const WorkforceImalatLine({
    required this.id,
    required this.imalatName,
    this.imalatId,
    this.usta = const WorkforceCrewHours(),
    this.duzIsci = const WorkforceCrewHours(),
  });

  final String id;

  /// Keşif imalatı id (açılır listeden); manuel ise null.
  final String? imalatId;

  /// Keşif adı veya manuel yazılan imalat adı.
  final String imalatName;

  final WorkforceCrewHours usta;
  final WorkforceCrewHours duzIsci;

  double get ustaAdamGun => usta.adamGun;
  double get duzAdamGun => duzIsci.adamGun;
  double get totalAdamGun => ustaAdamGun + duzAdamGun;
  double get totalManHours => usta.manHours + duzIsci.manHours;

  bool get hasLabor => !usta.isEmpty || !duzIsci.isEmpty;

  WorkforceImalatLine copyWith({
    String? id,
    String? imalatId,
    String? imalatName,
    WorkforceCrewHours? usta,
    WorkforceCrewHours? duzIsci,
    bool clearImalatId = false,
  }) {
    return WorkforceImalatLine(
      id: id ?? this.id,
      imalatId: clearImalatId ? null : (imalatId ?? this.imalatId),
      imalatName: imalatName ?? this.imalatName,
      usta: usta ?? this.usta,
      duzIsci: duzIsci ?? this.duzIsci,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imalatId': imalatId,
        'imalatName': imalatName,
        'usta': usta.toJson(),
        'duzIsci': duzIsci.toJson(),
      };

  factory WorkforceImalatLine.fromJson(Map<dynamic, dynamic> json) {
    return WorkforceImalatLine(
      id: json['id'] as String? ??
          'wil-${DateTime.now().millisecondsSinceEpoch}',
      imalatId: json['imalatId'] as String?,
      imalatName: json['imalatName'] as String? ?? '',
      usta: WorkforceCrewHours.fromJson(
        json['usta'] as Map<dynamic, dynamic>?,
      ),
      duzIsci: WorkforceCrewHours.fromJson(
        json['duzIsci'] as Map<dynamic, dynamic>?,
      ),
    );
  }
}

/// Günlük puantaj + imalat çalışma kaydı.
class WorkforceEntry {
  const WorkforceEntry({
    required this.id,
    required this.date,
    this.kalfa = 0,
    this.lines = const [],
    this.notes,
  });

  final String id;
  final DateTime date;

  /// Günlük kalfa sayısı — yalnızca kayıt; adam-saat hesabına girmez.
  final int kalfa;

  final List<WorkforceImalatLine> lines;
  final String? notes;

  double get ustaAdamGun =>
      lines.fold(0.0, (sum, line) => sum + line.ustaAdamGun);

  double get duzAdamGun =>
      lines.fold(0.0, (sum, line) => sum + line.duzAdamGun);

  double get totalManHours =>
      lines.fold(0.0, (sum, line) => sum + line.totalManHours);

  /// Tahmin motoru için toplam adam-gün (usta + düz; kalfa hariç).
  double get workerDayUnits => ustaAdamGun + duzAdamGun;

  double get totalAdamGun => workerDayUnits;

  bool get hasLabor =>
      lines.any((line) => line.hasLabor) || kalfa > 0;

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  WorkforceEntry copyWith({
    String? id,
    DateTime? date,
    int? kalfa,
    List<WorkforceImalatLine>? lines,
    String? notes,
  }) {
    return WorkforceEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      kalfa: kalfa ?? this.kalfa,
      lines: lines ?? this.lines,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'kalfa': kalfa,
        'lines': lines.map((line) => line.toJson()).toList(),
        'notes': notes,
        'schemaVersion': 3,
      };

  factory WorkforceEntry.fromJson(Map<dynamic, dynamic> json) {
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();

    if (json['lines'] is List) {
      final rawLines = json['lines'] as List<dynamic>;
      return WorkforceEntry(
        id: json['id'] as String? ?? '',
        date: date,
        kalfa: (json['kalfa'] as num?)?.toInt() ?? 0,
        lines: rawLines
            .whereType<Map>()
            .map((item) => WorkforceImalatLine.fromJson(item))
            .toList(),
        notes: json['notes'] as String?,
      );
    }

    return WorkforceEntry._migrateLegacy(json, date);
  }

  /// Eski şemalar → tek "Genel" imalat satırı (en iyi tahmin).
  factory WorkforceEntry._migrateLegacy(
    Map<dynamic, dynamic> json,
    DateTime date,
  ) {
    final hasClassic = json.containsKey('steelWorkers') ||
        json.containsKey('foremen') ||
        json.containsKey('hours');

    final kalfa = (json['kalfa'] as num?)?.toInt() ??
        (json['steelWorkers'] as num?)?.toInt() ??
        0;

    if (hasClassic) {
      final ustaCount = (json['usta'] as num?)?.toInt() ??
          (json['foremen'] as num?)?.toInt() ??
          0;
      final hours = (json['hours'] as num?)?.toDouble() ?? 8;
      final overtime = (json['mesaiSaati'] as num?)?.toDouble() ??
          (json['overtimeHours'] as num?)?.toDouble() ??
          0;
      final usta = WorkforceCrewHours(
        tam: hours >= 8 ? ustaCount : 0,
        yarim: hours > 0 && hours < 8 ? ustaCount : 0,
        mesaiKisi: overtime > 0 ? ustaCount : 0,
        mesaiSaat: overtime,
      );
      return WorkforceEntry(
        id: json['id'] as String? ?? '',
        date: date,
        kalfa: kalfa,
        lines: [
          if (ustaCount > 0 || overtime > 0)
            WorkforceImalatLine(
              id: 'wil-migrated',
              imalatName: 'Genel',
              usta: usta,
            ),
        ],
        notes: json['notes'] as String?,
      );
    }

    // Ara şema: kalfa / usta / duzIsci / tamGun / yarimGun / mesaiSaati
    final ustaCount = (json['usta'] as num?)?.toInt() ?? 0;
    final duzCount = (json['duzIsci'] as num?)?.toInt() ?? 0;
    final tamGun = (json['tamGun'] as num?)?.toInt() ?? 0;
    final yarimGun = (json['yarimGun'] as num?)?.toInt() ?? 0;
    final mesai = (json['mesaiSaati'] as num?)?.toDouble() ?? 0;

    final usta = WorkforceCrewHours(
      tam: ustaCount > 0
          ? (tamGun > 0 ? ustaCount : (yarimGun > 0 ? 0 : ustaCount))
          : 0,
      yarim: ustaCount > 0 && tamGun <= 0 && yarimGun > 0 ? ustaCount : 0,
      mesaiKisi: mesai > 0 ? ustaCount : 0,
      mesaiSaat: mesai,
    );
    final duz = WorkforceCrewHours(
      tam: duzCount > 0 ? duzCount : 0,
      mesaiKisi: 0,
      mesaiSaat: 0,
    );

    return WorkforceEntry(
      id: json['id'] as String? ?? '',
      date: date,
      kalfa: kalfa,
      lines: [
        if (ustaCount > 0 || duzCount > 0 || mesai > 0)
          WorkforceImalatLine(
            id: 'wil-migrated',
            imalatName: 'Genel',
            usta: usta,
            duzIsci: duz,
          ),
      ],
      notes: json['notes'] as String?,
    );
  }

  static DateTime normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
