import 'package:equatable/equatable.dart';

import '../../core/utils/text_format.dart';
import '../enums/photo_work_category.dart';

/// Günlük saha raporu — proje + takvim günü başına tek kayıt (upsert).
class DailyReport extends Equatable {
  const DailyReport({
    required this.id,
    required this.projectId,
    required this.date,
    this.workConstruction = '',
    this.workElectrical = '',
    this.workMechanical = '',
    this.nextDayPlan = '',
    this.photos = const [],
    this.irsaliyePhotos = const [],
    this.incomingMaterials = const [],
    this.outgoingMaterials = const [],
    this.orderedMaterials = const [],
    this.machines = const [],
    this.vehicles = const [],
    this.weather,
    this.attendanceSnapshot,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;

  /// TR tarih: `dd.MM.yyyy`
  final String date;

  /// İnşaat işleri (serbest metin).
  final String workConstruction;

  /// Elektrik işleri (serbest metin).
  final String workElectrical;

  /// Mekanik işler (serbest metin).
  final String workMechanical;

  /// Planlı işler listesi (serbest metin).
  final String nextDayPlan;

  /// Özet / geriye dönük birleşik metin.
  String get workDone => _combinedWork(withPhotoCaptions: true);

  /// Sadece manuel yazılan metinlerin birleşimi.
  String get manualWorkDone => _combinedWork(withPhotoCaptions: false);

  String _combinedWork({required bool withPhotoCaptions}) {
    final parts = <String>[];
    void add(String title, String body) {
      final t = body.trim();
      if (t.isEmpty) return;
      parts.add('$title:\n$t');
    }

    add(
      'İNŞAAT İŞLERİ',
      withPhotoCaptions ? effectiveWorkConstruction : workConstruction,
    );
    add(
      'ELEKTRİK İŞLERİ',
      withPhotoCaptions ? effectiveWorkElectrical : workElectrical,
    );
    add(
      'MEKANİK İŞLER',
      withPhotoCaptions ? effectiveWorkMechanical : workMechanical,
    );
    return parts.join('\n\n');
  }

  /// Kullanıcının ilgili alana yazdığı serbest metin.
  String manualWorkFor(PhotoWorkCategory category) => switch (category) {
        PhotoWorkCategory.construction => workConstruction,
        PhotoWorkCategory.electrical => workElectrical,
        PhotoWorkCategory.mechanical => workMechanical,
        PhotoWorkCategory.none => '',
      }.trim();

  /// Manuel metinde zaten yazılmayan foto açıklamaları.
  List<String> syncedCaptionsFor(PhotoWorkCategory category) {
    final manualKeys = {
      for (final line in manualWorkFor(category).split('\n'))
        if (_lineKey(line).isNotEmpty) _lineKey(line),
    };
    return [
      for (final c in photoCaptionsFor(category))
        if (!manualKeys.contains(_lineKey(c))) c,
    ];
  }

  /// Manuel metin + ilgili kategorideki foto açıklamaları.
  String effectiveWorkFor(PhotoWorkCategory category) {
    final manual = manualWorkFor(category);
    final caps = syncedCaptionsFor(category);
    if (manual.isEmpty && caps.isEmpty) return '';
    if (caps.isEmpty) return manual;
    if (manual.isEmpty) return caps.join('\n');
    return '$manual\n${caps.join('\n')}';
  }

  String get effectiveWorkConstruction =>
      effectiveWorkFor(PhotoWorkCategory.construction);
  String get effectiveWorkElectrical =>
      effectiveWorkFor(PhotoWorkCategory.electrical);
  String get effectiveWorkMechanical =>
      effectiveWorkFor(PhotoWorkCategory.mechanical);

  List<String> photoCaptionsFor(PhotoWorkCategory category) => [
        for (final p in photos)
          if (p.hasCaption && p.workCategory == category) p.caption.trim(),
      ];

  /// İnşaat → elektrik → mekanik → seçilmemiş; aynı kategoride ekleme sırası korunur.
  List<DailyReportPhoto> get photosByWorkCategory =>
      sortPhotosByWorkCategory(photos);

  static List<DailyReportPhoto> sortPhotosByWorkCategory(
    List<DailyReportPhoto> photos,
  ) {
    final indexed = photos.asMap().entries.toList();
    indexed.sort((a, b) {
      final byCat = a.value.workCategory.sortOrder
          .compareTo(b.value.workCategory.sortOrder);
      if (byCat != 0) return byCat;
      return a.key.compareTo(b.key);
    });
    return [for (final e in indexed) e.value];
  }

  /// Geriye dönük — tüm foto açıklamaları.
  List<String> get photoCaptions => [
        for (final p in photos)
          if (p.hasCaption) p.caption.trim(),
      ];

  bool get hasWorkEntries =>
      effectiveWorkConstruction.isNotEmpty ||
      effectiveWorkElectrical.isNotEmpty ||
      effectiveWorkMechanical.isNotEmpty;

  final List<DailyReportPhoto> photos;

  /// Gelen malzeme irsaliye görselleri (Hive + base64).
  final List<DailyReportPhoto> irsaliyePhotos;
  final List<DailyReportMaterial> incomingMaterials;

  /// Giden / gönderilen malzeme.
  final List<DailyReportMaterial> outgoingMaterials;
  final List<DailyReportMaterial> orderedMaterials;
  final List<DailyReportMachine> machines;

  /// Vasıta puantajı (binek, kamyon vb.).
  final List<DailyReportMachine> vehicles;
  final DailyReportWeather? weather;
  final DailyReportAttendanceSnapshot? attendanceSnapshot;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyReport copyWith({
    String? id,
    String? projectId,
    String? date,
    String? workConstruction,
    String? workElectrical,
    String? workMechanical,
    String? nextDayPlan,
    List<DailyReportPhoto>? photos,
    List<DailyReportPhoto>? irsaliyePhotos,
    List<DailyReportMaterial>? incomingMaterials,
    List<DailyReportMaterial>? outgoingMaterials,
    List<DailyReportMaterial>? orderedMaterials,
    List<DailyReportMachine>? machines,
    List<DailyReportMachine>? vehicles,
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
      workConstruction: workConstruction ?? this.workConstruction,
      workElectrical: workElectrical ?? this.workElectrical,
      workMechanical: workMechanical ?? this.workMechanical,
      nextDayPlan: nextDayPlan ?? this.nextDayPlan,
      photos: photos ?? this.photos,
      irsaliyePhotos: irsaliyePhotos ?? this.irsaliyePhotos,
      incomingMaterials: incomingMaterials ?? this.incomingMaterials,
      outgoingMaterials: outgoingMaterials ?? this.outgoingMaterials,
      orderedMaterials: orderedMaterials ?? this.orderedMaterials,
      machines: machines ?? this.machines,
      vehicles: vehicles ?? this.vehicles,
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
        'workConstruction': workConstruction,
        'workElectrical': workElectrical,
        'workMechanical': workMechanical,
        'nextDayPlan': nextDayPlan,
        // Geriye dönük yedek alanı — foto açıklamaları hariç, aksi halde
        // tekrar okunurken manuel alana kopyalanıp mükerrer satır oluşuyor.
        'workDone': manualWorkDone,
        'photos': photos.map((e) => e.toJson()).toList(),
        'irsaliyePhotos': irsaliyePhotos.map((e) => e.toJson()).toList(),
        'incomingMaterials':
            incomingMaterials.map((e) => e.toJson()).toList(),
        'outgoingMaterials':
            outgoingMaterials.map((e) => e.toJson()).toList(),
        'orderedMaterials': orderedMaterials.map((e) => e.toJson()).toList(),
        'machines': machines.map((e) => e.toJson()).toList(),
        'vehicles': vehicles.map((e) => e.toJson()).toList(),
        'weather': weather?.toJson(),
        'attendanceSnapshot': attendanceSnapshot?.toJson(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static String _lineKey(String raw) => raw
      .trim()
      .replaceAll(RegExp(r'^[•\-*]+\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();

  static final Set<String> _generatedSectionKeys = {
    _lineKey('İNŞAAT İŞLERİ:'),
    _lineKey('ELEKTRİK İŞLERİ:'),
    _lineKey('MEKANİK İŞLER:'),
  };

  /// Manuel metne sızmış senkron satırlarını (bölüm başlıkları ve foto
  /// açıklamaları) ayıklar; bu satırlar rapora zaten fotoğraflardan geliyor.
  static String _withoutSyncedLines(String raw, Set<String> captionKeys) {
    if (raw.trim().isEmpty) return '';
    final kept = <String>[];
    for (final line in raw.split('\n')) {
      final key = _lineKey(line);
      if (key.isEmpty) {
        kept.add('');
        continue;
      }
      if (_generatedSectionKeys.contains(key)) continue;
      if (captionKeys.contains(key)) continue;
      kept.add(line);
    }
    return kept.join('\n').trim();
  }

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> asMaps(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    final photos =
        asMaps(json['photos']).map(DailyReportPhoto.fromJson).toList();

    var construction = json['workConstruction'] as String? ?? '';
    var electrical = json['workElectrical'] as String? ?? '';
    var mechanical = json['workMechanical'] as String? ?? '';
    final legacy = json['workDone'] as String? ?? '';
    if (construction.isEmpty &&
        electrical.isEmpty &&
        mechanical.isEmpty &&
        legacy.trim().isNotEmpty) {
      construction = legacy;
    }

    final captionKeys = <String>{
      for (final p in photos)
        if (p.hasCaption) _lineKey(p.caption),
    };
    construction = _withoutSyncedLines(construction, captionKeys);
    electrical = _withoutSyncedLines(electrical, captionKeys);
    mechanical = _withoutSyncedLines(mechanical, captionKeys);

    return DailyReport(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      date: json['date'] as String,
      workConstruction: construction,
      workElectrical: electrical,
      workMechanical: mechanical,
      nextDayPlan: json['nextDayPlan'] as String? ?? '',
      photos: photos,
      irsaliyePhotos:
          asMaps(json['irsaliyePhotos']).map(DailyReportPhoto.fromJson).toList(),
      incomingMaterials: asMaps(json['incomingMaterials'])
          .map(DailyReportMaterial.fromJson)
          .toList(),
      outgoingMaterials: asMaps(json['outgoingMaterials'])
          .map(DailyReportMaterial.fromJson)
          .toList(),
      orderedMaterials: asMaps(json['orderedMaterials'])
          .map(DailyReportMaterial.fromJson)
          .toList(),
      machines:
          asMaps(json['machines']).map(DailyReportMachine.fromJson).toList(),
      vehicles:
          asMaps(json['vehicles']).map(DailyReportMachine.fromJson).toList(),
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
        workConstruction,
        workElectrical,
        workMechanical,
        nextDayPlan,
        photos,
        irsaliyePhotos,
        incomingMaterials,
        outgoingMaterials,
        orderedMaterials,
        machines,
        vehicles,
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
    this.workCategory = PhotoWorkCategory.none,
    this.mimeType = 'image/jpeg',
    this.createdAt,
  });

  final String id;
  final String dataBase64;
  final String caption;
  final PhotoWorkCategory workCategory;
  final String mimeType;
  final DateTime? createdAt;

  bool get hasCaption => caption.trim().isNotEmpty;

  DailyReportPhoto copyWith({
    String? id,
    String? dataBase64,
    String? caption,
    PhotoWorkCategory? workCategory,
    String? mimeType,
    DateTime? createdAt,
  }) {
    return DailyReportPhoto(
      id: id ?? this.id,
      dataBase64: dataBase64 ?? this.dataBase64,
      caption: caption ?? this.caption,
      workCategory: workCategory ?? this.workCategory,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataBase64': dataBase64,
        'caption': caption,
        'workCategory': workCategory.storage,
        'mimeType': mimeType,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory DailyReportPhoto.fromJson(Map<String, dynamic> json) =>
      DailyReportPhoto(
        id: json['id'] as String,
        dataBase64: json['dataBase64'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        workCategory:
            PhotoWorkCategory.fromStorage(json['workCategory'] as String?),
        mimeType: json['mimeType'] as String? ?? 'image/jpeg',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props =>
      [id, dataBase64, caption, workCategory, mimeType, createdAt];
}

/// Gelen veya sipariş malzeme satırı.
class DailyReportMaterial extends Equatable {
  const DailyReportMaterial({
    required this.id,
    required this.name,
    this.quantity = '',
    this.unit = '',
    this.supplierOrOrder = '',
    this.supplyDate = '',
    this.price = '',
    this.note = '',
    this.irsaliyePhotoId = '',
    this.purchaseApproved = false,
    this.recordedAt,
  });

  final String id;
  final String name;
  final String quantity;
  final String unit;

  /// Gelen: tedarikçi · Sipariş: kime / sipariş no.
  final String supplierOrOrder;

  /// Tedarik tarihi (`dd.MM.yyyy` tercih).
  final String supplyDate;

  /// Birim fiyat (opsiyonel).
  final String price;
  final String note;

  /// İlişkili irsaliye foto id (opsiyonel).
  final String irsaliyePhotoId;

  /// Sipariş malzemede satın alma onayı.
  final bool purchaseApproved;
  final DateTime? recordedAt;

  DailyReportMaterial copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    String? supplierOrOrder,
    String? supplyDate,
    String? price,
    String? note,
    String? irsaliyePhotoId,
    bool? purchaseApproved,
    DateTime? recordedAt,
  }) {
    return DailyReportMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      supplierOrOrder: supplierOrOrder ?? this.supplierOrOrder,
      supplyDate: supplyDate ?? this.supplyDate,
      price: price ?? this.price,
      note: note ?? this.note,
      irsaliyePhotoId: irsaliyePhotoId ?? this.irsaliyePhotoId,
      purchaseApproved: purchaseApproved ?? this.purchaseApproved,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'supplierOrOrder': supplierOrOrder,
        'supplyDate': supplyDate,
        'price': price,
        'note': note,
        'irsaliyePhotoId': irsaliyePhotoId,
        'purchaseApproved': purchaseApproved,
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
        supplyDate: json['supplyDate'] as String? ?? '',
        price: json['price'] as String? ?? '',
        note: json['note'] as String? ?? '',
        irsaliyePhotoId: json['irsaliyePhotoId'] as String? ?? '',
        purchaseApproved: json['purchaseApproved'] as bool? ?? false,
        recordedAt: json['recordedAt'] != null
            ? DateTime.tryParse(json['recordedAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        quantity,
        unit,
        supplierOrOrder,
        supplyDate,
        price,
        note,
        irsaliyePhotoId,
        purchaseApproved,
        recordedAt,
      ];
}

/// İş makinesi puantaj satırı.
class DailyReportMachine extends Equatable {
  const DailyReportMachine({
    required this.id,
    required this.name,
    this.type = '',
    this.plateOrId = '',
    this.company = '',
    this.hoursWorked = 0,
    this.workDescription = '',
    this.operatorName = '',
  });

  final String id;
  final String name;
  final String type;
  final String plateOrId;

  /// İş makinesi firma adı (vasıtada kullanılmaz).
  final String company;
  final double hoursWorked;
  final String workDescription;
  final String operatorName;

  DailyReportMachine copyWith({
    String? id,
    String? name,
    String? type,
    String? plateOrId,
    String? company,
    double? hoursWorked,
    String? workDescription,
    String? operatorName,
  }) {
    return DailyReportMachine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      plateOrId: plateOrId ?? this.plateOrId,
      company: company ?? this.company,
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
        'company': company,
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
        company: json['company'] as String? ?? '',
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
        company,
        hoursWorked,
        workDescription,
        operatorName,
      ];
}

/// Hava durumu bloğu — otomatik (MGM) veya manuel.
class DailyReportWeather extends Equatable {
  const DailyReportWeather({
    this.temperatureC,
    this.nightTemperatureC,
    this.humidityPercent,
    this.maxHumidityPercent,
    this.description = '',
    this.windKmh,
    this.windGustKmh,
    this.locationLabel = '',
    this.fetchedAt,
    this.synced = true,
    this.offlineNote = '',
    this.isManual = false,
  });

  /// Anlık / gündüz sıcaklık (°C).
  final double? temperatureC;

  /// Gece (günlük minimum) sıcaklık (°C).
  final double? nightTemperatureC;

  /// Anlık bağıl nem (%).
  final double? humidityPercent;

  /// Günlük maksimum bağıl nem (%).
  final double? maxHumidityPercent;
  final String description;

  /// Anlık rüzgar (km/s).
  final double? windKmh;

  /// Ani rüzgar / maksimum rüzgar hızı (km/s).
  final double? windGustKmh;
  final String locationLabel;
  final DateTime? fetchedAt;
  final bool synced;
  final String offlineNote;

  /// true → kullanıcı girdi / müdahale etti (geçmiş günde kilit yok).
  final bool isManual;

  /// Geçmiş gün + otomatik senkron → kilitli (manuel müdahale ile açılır).
  bool isAutoLocked(String reportDate) {
    if (isManual || !synced) return false;
    final parts = reportDate.split('.');
    if (parts.length != 3) return false;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return false;
    final d = DateTime(year, month, day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return d.isBefore(today);
  }

  DailyReportWeather copyWith({
    double? temperatureC,
    double? nightTemperatureC,
    double? humidityPercent,
    double? maxHumidityPercent,
    String? description,
    double? windKmh,
    double? windGustKmh,
    String? locationLabel,
    DateTime? fetchedAt,
    bool? synced,
    String? offlineNote,
    bool? isManual,
    bool clearTemperature = false,
    bool clearNight = false,
    bool clearHumidity = false,
    bool clearMaxHumidity = false,
    bool clearWind = false,
    bool clearWindGust = false,
  }) {
    return DailyReportWeather(
      temperatureC:
          clearTemperature ? null : (temperatureC ?? this.temperatureC),
      nightTemperatureC:
          clearNight ? null : (nightTemperatureC ?? this.nightTemperatureC),
      humidityPercent:
          clearHumidity ? null : (humidityPercent ?? this.humidityPercent),
      maxHumidityPercent: clearMaxHumidity
          ? null
          : (maxHumidityPercent ?? this.maxHumidityPercent),
      description: description ?? this.description,
      windKmh: clearWind ? null : (windKmh ?? this.windKmh),
      windGustKmh:
          clearWindGust ? null : (windGustKmh ?? this.windGustKmh),
      locationLabel: locationLabel ?? this.locationLabel,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      synced: synced ?? this.synced,
      offlineNote: offlineNote ?? this.offlineNote,
      isManual: isManual ?? this.isManual,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperatureC': temperatureC,
        'nightTemperatureC': nightTemperatureC,
        'humidityPercent': humidityPercent,
        'maxHumidityPercent': maxHumidityPercent,
        'description': description,
        'windKmh': windKmh,
        'windGustKmh': windGustKmh,
        'locationLabel': locationLabel,
        'fetchedAt': fetchedAt?.toIso8601String(),
        'synced': synced,
        'offlineNote': offlineNote,
        'isManual': isManual,
      };

  factory DailyReportWeather.fromJson(Map<String, dynamic> json) =>
      DailyReportWeather(
        temperatureC: (json['temperatureC'] as num?)?.toDouble(),
        nightTemperatureC: (json['nightTemperatureC'] as num?)?.toDouble(),
        humidityPercent: (json['humidityPercent'] as num?)?.toDouble(),
        maxHumidityPercent: (json['maxHumidityPercent'] as num?)?.toDouble(),
        description: json['description'] as String? ?? '',
        windKmh: (json['windKmh'] as num?)?.toDouble(),
        windGustKmh: (json['windGustKmh'] as num?)?.toDouble(),
        locationLabel: json['locationLabel'] as String? ?? '',
        fetchedAt: json['fetchedAt'] != null
            ? DateTime.tryParse(json['fetchedAt'] as String)
            : null,
        synced: json['synced'] as bool? ?? true,
        offlineNote: json['offlineNote'] as String? ?? '',
        isManual: json['isManual'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        temperatureC,
        nightTemperatureC,
        humidityPercent,
        maxHumidityPercent,
        description,
        windKmh,
        windGustKmh,
        locationLabel,
        fetchedAt,
        synced,
        offlineNote,
        isManual,
      ];
}

class DailyReportAttendancePerson extends Equatable {
  const DailyReportAttendancePerson._({
    required this.personId,
    required this.personName,
    required this.status,
    required this.hours,
    this.team = '',
    this.profession = '',
    this.overtimeHours = 0,
    this.yevmiye = 0,
  });

  factory DailyReportAttendancePerson({
    required String personId,
    required String personName,
    required String status,
    required int hours,
    String team = '',
    String profession = '',
    double overtimeHours = 0,
    double yevmiye = 0,
  }) {
    return DailyReportAttendancePerson._(
      personId: personId,
      personName: titleCaseTr(personName),
      status: status,
      hours: hours,
      team: team,
      profession: profession,
      overtimeHours: overtimeHours,
      yevmiye: yevmiye,
    );
  }

  final String personId;
  final String personName;
  final String team;
  final String profession;
  final String status;
  final int hours;
  final double overtimeHours;
  final double yevmiye;

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'personName': personName,
        'team': team,
        'profession': profession,
        'status': status,
        'hours': hours,
        'overtimeHours': overtimeHours,
        'yevmiye': yevmiye,
      };

  factory DailyReportAttendancePerson.fromJson(Map<String, dynamic> json) =>
      DailyReportAttendancePerson(
        personId: json['personId'] as String? ?? '',
        personName: json['personName'] as String? ?? '',
        team: json['team'] as String? ?? '',
        profession: json['profession'] as String? ?? '',
        status: json['status'] as String? ?? '',
        hours: (json['hours'] as num?)?.toInt() ?? 0,
        overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
        yevmiye: (json['yevmiye'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [
        personId,
        personName,
        team,
        profession,
        status,
        hours,
        overtimeHours,
        yevmiye,
      ];
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
