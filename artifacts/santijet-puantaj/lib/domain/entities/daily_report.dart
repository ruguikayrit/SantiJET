import 'package:equatable/equatable.dart';

/// Günlük saha raporu — proje + takvim günü başına tek kayıt (upsert).
class DailyReport extends Equatable {
  const DailyReport({
    required this.id,
    required this.projectId,
    required this.date,
    this.workDone = '',
    this.photos = const [],
    this.incomingMaterials = const [],
    this.orderedMaterials = const [],
    this.machines = const [],
    this.weather,
    this.attendanceSnapshot,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;

  /// TR tarih: `dd.MM.yyyy`
  final String date;

  /// Gün içinde yapılan işler (serbest metin / satır satır).
  final String workDone;
  final List<DailyReportPhoto> photos;
  final List<DailyReportMaterial> incomingMaterials;
  final List<DailyReportMaterial> orderedMaterials;
  final List<DailyReportMachine> machines;
  final DailyReportWeather? weather;
  final DailyReportAttendanceSnapshot? attendanceSnapshot;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyReport copyWith({
    String? id,
    String? projectId,
    String? date,
    String? workDone,
    List<DailyReportPhoto>? photos,
    List<DailyReportMaterial>? incomingMaterials,
    List<DailyReportMaterial>? orderedMaterials,
    List<DailyReportMachine>? machines,
    DailyReportWeather? weather,
    DailyReportAttendanceSnapshot? attendanceSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearWeather = false,
    bool clearAttendance = false,
  }) {
    return DailyReport(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      workDone: workDone ?? this.workDone,
      photos: photos ?? this.photos,
      incomingMaterials: incomingMaterials ?? this.incomingMaterials,
      orderedMaterials: orderedMaterials ?? this.orderedMaterials,
      machines: machines ?? this.machines,
      weather: clearWeather ? null : (weather ?? this.weather),
      attendanceSnapshot: clearAttendance
          ? null
          : (attendanceSnapshot ?? this.attendanceSnapshot),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'workDone': workDone,
        'photos': photos.map((e) => e.toJson()).toList(),
        'incomingMaterials':
            incomingMaterials.map((e) => e.toJson()).toList(),
        'orderedMaterials': orderedMaterials.map((e) => e.toJson()).toList(),
        'machines': machines.map((e) => e.toJson()).toList(),
        'weather': weather?.toJson(),
        'attendanceSnapshot': attendanceSnapshot?.toJson(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> asMaps(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return DailyReport(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      date: json['date'] as String,
      workDone: json['workDone'] as String? ?? '',
      photos: asMaps(json['photos']).map(DailyReportPhoto.fromJson).toList(),
      incomingMaterials: asMaps(json['incomingMaterials'])
          .map(DailyReportMaterial.fromJson)
          .toList(),
      orderedMaterials: asMaps(json['orderedMaterials'])
          .map(DailyReportMaterial.fromJson)
          .toList(),
      machines:
          asMaps(json['machines']).map(DailyReportMachine.fromJson).toList(),
      weather: json['weather'] is Map
          ? DailyReportWeather.fromJson(
              Map<String, dynamic>.from(json['weather'] as Map),
            )
          : null,
      attendanceSnapshot: json['attendanceSnapshot'] is Map
          ? DailyReportAttendanceSnapshot.fromJson(
              Map<String, dynamic>.from(json['attendanceSnapshot'] as Map),
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        workDone,
        photos,
        incomingMaterials,
        orderedMaterials,
        machines,
        weather,
        attendanceSnapshot,
        createdAt,
        updatedAt,
      ];
}

/// Fotoğraf — Hive’da base64; web + mobil ortak (dosya yolu yok).
///
/// Açıklama kuralı: **önerilen**. Boş kayda izin var; UI uyarı gösterir.
class DailyReportPhoto extends Equatable {
  const DailyReportPhoto({
    required this.id,
    required this.dataBase64,
    this.caption = '',
    this.mimeType = 'image/jpeg',
    this.createdAt,
  });

  final String id;
  final String dataBase64;
  final String caption;
  final String mimeType;
  final DateTime? createdAt;

  bool get hasCaption => caption.trim().isNotEmpty;

  DailyReportPhoto copyWith({
    String? id,
    String? dataBase64,
    String? caption,
    String? mimeType,
    DateTime? createdAt,
  }) {
    return DailyReportPhoto(
      id: id ?? this.id,
      dataBase64: dataBase64 ?? this.dataBase64,
      caption: caption ?? this.caption,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataBase64': dataBase64,
        'caption': caption,
        'mimeType': mimeType,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory DailyReportPhoto.fromJson(Map<String, dynamic> json) =>
      DailyReportPhoto(
        id: json['id'] as String,
        dataBase64: json['dataBase64'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? 'image/jpeg',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, dataBase64, caption, mimeType, createdAt];
}

/// Gelen veya sipariş malzeme satırı.
class DailyReportMaterial extends Equatable {
  const DailyReportMaterial({
    required this.id,
    required this.name,
    this.quantity = '',
    this.unit = '',
    this.supplierOrOrder = '',
    this.note = '',
    this.recordedAt,
  });

  final String id;
  final String name;
  final String quantity;
  final String unit;

  /// Gelen: tedarikçi · Sipariş: kime / sipariş no.
  final String supplierOrOrder;
  final String note;
  final DateTime? recordedAt;

  DailyReportMaterial copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    String? supplierOrOrder,
    String? note,
    DateTime? recordedAt,
  }) {
    return DailyReportMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      supplierOrOrder: supplierOrOrder ?? this.supplierOrOrder,
      note: note ?? this.note,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'supplierOrOrder': supplierOrOrder,
        'note': note,
        'recordedAt': recordedAt?.toIso8601String(),
      };

  factory DailyReportMaterial.fromJson(Map<String, dynamic> json) =>
      DailyReportMaterial(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        supplierOrOrder: json['supplierOrOrder'] as String? ??
            json['supplier'] as String? ??
            '',
        note: json['note'] as String? ?? '',
        recordedAt: json['recordedAt'] != null
            ? DateTime.tryParse(json['recordedAt'] as String)
            : null,
      );

  @override
  List<Object?> get props =>
      [id, name, quantity, unit, supplierOrOrder, note, recordedAt];
}

/// İş makinesi puantaj satırı.
class DailyReportMachine extends Equatable {
  const DailyReportMachine({
    required this.id,
    required this.name,
    this.type = '',
    this.plateOrId = '',
    this.hoursWorked = 0,
    this.workDescription = '',
    this.operatorName = '',
  });

  final String id;
  final String name;
  final String type;
  final String plateOrId;
  final double hoursWorked;
  final String workDescription;
  final String operatorName;

  DailyReportMachine copyWith({
    String? id,
    String? name,
    String? type,
    String? plateOrId,
    double? hoursWorked,
    String? workDescription,
    String? operatorName,
  }) {
    return DailyReportMachine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      plateOrId: plateOrId ?? this.plateOrId,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      workDescription: workDescription ?? this.workDescription,
      operatorName: operatorName ?? this.operatorName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'plateOrId': plateOrId,
        'hoursWorked': hoursWorked,
        'workDescription': workDescription,
        'operatorName': operatorName,
      };

  factory DailyReportMachine.fromJson(Map<String, dynamic> json) =>
      DailyReportMachine(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        plateOrId: json['plateOrId'] as String? ?? '',
        hoursWorked: (json['hoursWorked'] as num?)?.toDouble() ?? 0,
        workDescription: json['workDescription'] as String? ?? '',
        operatorName: json['operatorName'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        plateOrId,
        hoursWorked,
        workDescription,
        operatorName,
      ];
}

/// Otomatik hava durumu bloğu (Open-Meteo).
class DailyReportWeather extends Equatable {
  const DailyReportWeather({
    this.temperatureC,
    this.description = '',
    this.windKmh,
    this.locationLabel = '',
    this.fetchedAt,
    this.synced = true,
    this.offlineNote = '',
  });

  final double? temperatureC;
  final String description;
  final double? windKmh;
  final String locationLabel;
  final DateTime? fetchedAt;
  final bool synced;
  final String offlineNote;

  DailyReportWeather copyWith({
    double? temperatureC,
    String? description,
    double? windKmh,
    String? locationLabel,
    DateTime? fetchedAt,
    bool? synced,
    String? offlineNote,
  }) {
    return DailyReportWeather(
      temperatureC: temperatureC ?? this.temperatureC,
      description: description ?? this.description,
      windKmh: windKmh ?? this.windKmh,
      locationLabel: locationLabel ?? this.locationLabel,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      synced: synced ?? this.synced,
      offlineNote: offlineNote ?? this.offlineNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperatureC': temperatureC,
        'description': description,
        'windKmh': windKmh,
        'locationLabel': locationLabel,
        'fetchedAt': fetchedAt?.toIso8601String(),
        'synced': synced,
        'offlineNote': offlineNote,
      };

  factory DailyReportWeather.fromJson(Map<String, dynamic> json) =>
      DailyReportWeather(
        temperatureC: (json['temperatureC'] as num?)?.toDouble(),
        description: json['description'] as String? ?? '',
        windKmh: (json['windKmh'] as num?)?.toDouble(),
        locationLabel: json['locationLabel'] as String? ?? '',
        fetchedAt: json['fetchedAt'] != null
            ? DateTime.tryParse(json['fetchedAt'] as String)
            : null,
        synced: json['synced'] as bool? ?? true,
        offlineNote: json['offlineNote'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        temperatureC,
        description,
        windKmh,
        locationLabel,
        fetchedAt,
        synced,
        offlineNote,
      ];
}

class DailyReportAttendancePerson extends Equatable {
  const DailyReportAttendancePerson({
    required this.personId,
    required this.personName,
    required this.status,
    required this.hours,
    this.overtimeHours = 0,
    this.yevmiye = 0,
  });

  final String personId;
  final String personName;
  final String status;
  final int hours;
  final double overtimeHours;
  final double yevmiye;

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'personName': personName,
        'status': status,
        'hours': hours,
        'overtimeHours': overtimeHours,
        'yevmiye': yevmiye,
      };

  factory DailyReportAttendancePerson.fromJson(Map<String, dynamic> json) =>
      DailyReportAttendancePerson(
        personId: json['personId'] as String? ?? '',
        personName: json['personName'] as String? ?? '',
        status: json['status'] as String? ?? '',
        hours: (json['hours'] as num?)?.toInt() ?? 0,
        overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
        yevmiye: (json['yevmiye'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props =>
      [personId, personName, status, hours, overtimeHours, yevmiye];
}

/// Aynı proje + gün puantaj özeti (bağlamsal snapshot).
class DailyReportAttendanceSnapshot extends Equatable {
  const DailyReportAttendanceSnapshot({
    this.present = 0,
    this.half = 0,
    this.leave = 0,
    this.absent = 0,
    this.totalAdamSaat = 0,
    this.totalYevmiye = 0,
    this.people = const [],
    this.capturedAt,
  });

  final int present;
  final int half;
  final int leave;
  final int absent;
  final double totalAdamSaat;
  final double totalYevmiye;
  final List<DailyReportAttendancePerson> people;
  final DateTime? capturedAt;

  Map<String, dynamic> toJson() => {
        'present': present,
        'half': half,
        'leave': leave,
        'absent': absent,
        'totalAdamSaat': totalAdamSaat,
        'totalYevmiye': totalYevmiye,
        'people': people.map((e) => e.toJson()).toList(),
        'capturedAt': capturedAt?.toIso8601String(),
      };

  factory DailyReportAttendanceSnapshot.fromJson(Map<String, dynamic> json) {
    final rawPeople = json['people'];
    final people = <DailyReportAttendancePerson>[];
    if (rawPeople is List) {
      for (final e in rawPeople) {
        people.add(
          DailyReportAttendancePerson.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        );
      }
    }
    return DailyReportAttendanceSnapshot(
      present: (json['present'] as num?)?.toInt() ?? 0,
      half: (json['half'] as num?)?.toInt() ?? 0,
      leave: (json['leave'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      totalAdamSaat: (json['totalAdamSaat'] as num?)?.toDouble() ?? 0,
      totalYevmiye: (json['totalYevmiye'] as num?)?.toDouble() ?? 0,
      people: people,
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        present,
        half,
        leave,
        absent,
        totalAdamSaat,
        totalYevmiye,
        people,
        capturedAt,
      ];
}
