import 'package:equatable/equatable.dart';

import '../../core/utils/puantaj_date.dart';
import '../enums/task_status.dart';
import '../permissions/role_degree.dart';
import 'person.dart';

/// Görev fotoğrafı — iş öncesi / sonrası.
enum TaskPhotoPhase {
  before,
  after;

  String get label => switch (this) {
        TaskPhotoPhase.before => 'Önce',
        TaskPhotoPhase.after => 'Sonra',
      };

  static TaskPhotoPhase fromStorage(String? raw) => switch (raw) {
        'after' => TaskPhotoPhase.after,
        _ => TaskPhotoPhase.before,
      };

  String get storage => name;
}

/// Göreve eklenen fotoğraf — Hive’da base64.
class TaskPhoto extends Equatable {
  const TaskPhoto({
    required this.id,
    required this.dataBase64,
    this.mimeType = 'image/jpeg',
    this.createdAt,
    this.previousDataBase64,
    this.previousMimeType,
    this.phase = TaskPhotoPhase.before,
  });

  static const maxTotal = 8;
  static const maxPerPhase = 4;

  final String id;
  final String dataBase64;
  final String mimeType;
  final DateTime? createdAt;

  /// Son düzenlemeden önceki görüntü — geri alma için.
  final String? previousDataBase64;
  final String? previousMimeType;

  /// Önce / sonra — PDF’de ayrı satırlar.
  final TaskPhotoPhase phase;

  bool get canRevertEdit =>
      previousDataBase64 != null && previousDataBase64!.trim().isNotEmpty;

  TaskPhoto copyWith({
    String? dataBase64,
    String? mimeType,
    DateTime? createdAt,
    String? previousDataBase64,
    String? previousMimeType,
    TaskPhotoPhase? phase,
    bool clearPrevious = false,
  }) {
    return TaskPhoto(
      id: id,
      dataBase64: dataBase64 ?? this.dataBase64,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      previousDataBase64: clearPrevious
          ? null
          : (previousDataBase64 ?? this.previousDataBase64),
      previousMimeType: clearPrevious
          ? null
          : (previousMimeType ?? this.previousMimeType),
      phase: phase ?? this.phase,
    );
  }

  /// Düzenlenmiş görüntüyü kaydeder; mevcut hali geri alma için saklar.
  TaskPhoto withEditedBase64(
    String editedBase64, {
    String mimeType = 'image/png',
  }) {
    return copyWith(
      dataBase64: editedBase64,
      mimeType: mimeType,
      previousDataBase64: dataBase64,
      previousMimeType: this.mimeType,
    );
  }

  /// Son düzenlemeyi geri alır (tek seviye).
  TaskPhoto revertEdit() {
    if (!canRevertEdit) return this;
    return copyWith(
      dataBase64: previousDataBase64!,
      mimeType: previousMimeType ?? 'image/jpeg',
      clearPrevious: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataBase64': dataBase64,
        'mimeType': mimeType,
        'createdAt': createdAt?.toIso8601String(),
        'phase': phase.storage,
        if (previousDataBase64 != null) 'previousDataBase64': previousDataBase64,
        if (previousMimeType != null) 'previousMimeType': previousMimeType,
      };

  factory TaskPhoto.fromJson(Map<String, dynamic> json) => TaskPhoto(
        id: json['id'] as String? ?? '',
        dataBase64: json['dataBase64'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? 'image/jpeg',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        previousDataBase64: json['previousDataBase64'] as String?,
        previousMimeType: json['previousMimeType'] as String?,
        phase: TaskPhotoPhase.fromStorage(json['phase'] as String?),
      );

  /// PDF/Excel: önce satırı + sonra satırı (en fazla 4’er).
  /// Eski kayıtlarda hepsi “önce” ve 4’ten fazlaysa ilk 4 / kalan 4 bölünür.
  static List<(String label, List<TaskPhoto>)> reportRows(
    List<TaskPhoto> photos,
  ) {
    final list = [
      for (final p in photos)
        if (p.dataBase64.trim().isNotEmpty) p,
    ];
    if (list.isEmpty) return const [];

    final before = list
        .where((p) => p.phase == TaskPhotoPhase.before)
        .toList();
    final after =
        list.where((p) => p.phase == TaskPhotoPhase.after).toList();

    if (after.isEmpty && before.length > maxPerPhase) {
      return [
        ('Önce', before.take(maxPerPhase).toList()),
        ('Sonra', before.skip(maxPerPhase).take(maxPerPhase).toList()),
      ];
    }

    return [
      if (before.isNotEmpty) ('Önce', before.take(maxPerPhase).toList()),
      if (after.isNotEmpty) ('Sonra', after.take(maxPerPhase).toList()),
    ];
  }

  @override
  List<Object?> get props => [
        id,
        dataBase64,
        mimeType,
        createdAt,
        previousDataBase64,
        previousMimeType,
        phase,
      ];
}

/// Proje kapsamındaki saha görevi — atayan + atanan görünür.
class SiteTask extends Equatable {
  const SiteTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.category = '',
    this.tag = '',
    this.assignee = '',
    this.assigneePersonId = '',
    this.assignerPersonId = '',
    this.assignerName = '',
    this.earliestStart = '',
    this.dueDate = '',
    this.actualStartDate = '',
    this.actualDeliveryDate = '',
    this.status = TaskStatus.todo,
    this.pendingStatusRaw = '',
    this.pendingActualStartDate = '',
    this.pendingActualDeliveryDate = '',
    this.photos = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;

  /// Kullanıcı tanımlı kategori (ör. Satın Alma, Saha, Ofis).
  final String category;

  /// Disiplin etiketi — İnşaat, Elektrik veya Mekanik.
  final String tag;

  /// Atanan personel görünen adı (önbellek).
  final String assignee;

  /// Atanan personel id — görünürlük için zorunlu.
  final String assigneePersonId;

  /// Görevi oluşturup atayan 1. derece personel id.
  final String assignerPersonId;

  /// Atayan görünen adı (önbellek).
  final String assignerName;

  /// Planlanan başlangıç — TR `dd.MM.yyyy`.
  final String earliestStart;

  /// Planlanan bitiş — TR `dd.MM.yyyy`.
  final String dueDate;

  /// Gerçekleşen başlangıç — Başlandı işaretlenince (TR `dd.MM.yyyy`).
  final String actualStartDate;

  /// Gerçekleşen bitiş — tamamlanınca (TR `dd.MM.yyyy`).
  final String actualDeliveryDate;
  final TaskStatus status;

  /// Atananın onay bekleyen durum değişikliği (`''` = yok).
  final String pendingStatusRaw;
  final String pendingActualStartDate;
  final String pendingActualDeliveryDate;

  /// Görev atanırken eklenen fotoğraflar.
  final List<TaskPhoto> photos;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskStatus? get pendingStatus => pendingStatusRaw.trim().isEmpty
      ? null
      : TaskStatus.fromStorage(pendingStatusRaw);

  bool get hasPendingStatusChange => pendingStatus != null;

  DateTime? get earliestStartDate => PuantajDate.tryParse(earliestStart);
  DateTime? get latestDeliveryDate => PuantajDate.tryParse(dueDate);
  DateTime? get actualStartDateTime => PuantajDate.tryParse(actualStartDate);
  DateTime? get actualDeliveryDateTime =>
      PuantajDate.tryParse(actualDeliveryDate);

  /// Görüntüleyen yalnızca atayan veya atanan ise görür.
  bool isVisibleTo(Person viewer) {
    if (assigneePersonId.isNotEmpty || assignerPersonId.isNotEmpty) {
      return viewer.id == assigneePersonId || viewer.id == assignerPersonId;
    }
    return RoleDegree.isFirstDegree(viewer);
  }

  bool isAssigner(Person person) =>
      assignerPersonId.isNotEmpty && person.id == assignerPersonId;

  bool isAssignee(Person person) =>
      assigneePersonId.isNotEmpty && person.id == assigneePersonId;

  SiteTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? category,
    String? tag,
    String? assignee,
    String? assigneePersonId,
    String? assignerPersonId,
    String? assignerName,
    String? earliestStart,
    String? dueDate,
    String? actualStartDate,
    String? actualDeliveryDate,
    TaskStatus? status,
    String? pendingStatusRaw,
    String? pendingActualStartDate,
    String? pendingActualDeliveryDate,
    List<TaskPhoto>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SiteTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tag: tag ?? this.tag,
      assignee: assignee ?? this.assignee,
      assigneePersonId: assigneePersonId ?? this.assigneePersonId,
      assignerPersonId: assignerPersonId ?? this.assignerPersonId,
      assignerName: assignerName ?? this.assignerName,
      earliestStart: earliestStart ?? this.earliestStart,
      dueDate: dueDate ?? this.dueDate,
      actualStartDate: actualStartDate ?? this.actualStartDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      status: status ?? this.status,
      pendingStatusRaw: pendingStatusRaw ?? this.pendingStatusRaw,
      pendingActualStartDate:
          pendingActualStartDate ?? this.pendingActualStartDate,
      pendingActualDeliveryDate:
          pendingActualDeliveryDate ?? this.pendingActualDeliveryDate,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  SiteTask clearPending() => copyWith(
        pendingStatusRaw: '',
        pendingActualStartDate: '',
        pendingActualDeliveryDate: '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'category': category,
        'tag': tag,
        'assignee': assignee,
        'assigneePersonId': assigneePersonId,
        'assignerPersonId': assignerPersonId,
        'assignerName': assignerName,
        'earliestStart': earliestStart,
        'dueDate': dueDate,
        'actualStartDate': actualStartDate,
        'actualDeliveryDate': actualDeliveryDate,
        'status': status.storage,
        if (pendingStatusRaw.isNotEmpty) 'pendingStatus': pendingStatusRaw,
        if (pendingActualStartDate.isNotEmpty)
          'pendingActualStartDate': pendingActualStartDate,
        if (pendingActualDeliveryDate.isNotEmpty)
          'pendingActualDeliveryDate': pendingActualDeliveryDate,
        'photos': photos.map((p) => p.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory SiteTask.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final photos = <TaskPhoto>[];
    if (rawPhotos is List) {
      for (final e in rawPhotos) {
        if (e is Map) {
          photos.add(TaskPhoto.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return SiteTask(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      assignee: json['assignee'] as String? ?? '',
      assigneePersonId: json['assigneePersonId'] as String? ?? '',
      assignerPersonId: json['assignerPersonId'] as String? ?? '',
      assignerName: json['assignerName'] as String? ?? '',
      earliestStart: json['earliestStart'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      actualStartDate: json['actualStartDate'] as String? ?? '',
      actualDeliveryDate: json['actualDeliveryDate'] as String? ?? '',
      status: TaskStatus.fromStorage(json['status'] as String?),
      pendingStatusRaw: json['pendingStatus'] as String? ?? '',
      pendingActualStartDate: json['pendingActualStartDate'] as String? ?? '',
      pendingActualDeliveryDate:
          json['pendingActualDeliveryDate'] as String? ?? '',
      photos: photos,
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
        title,
        description,
        category,
        tag,
        assignee,
        assigneePersonId,
        assignerPersonId,
        assignerName,
        earliestStart,
        dueDate,
        actualStartDate,
        actualDeliveryDate,
        status,
        pendingStatusRaw,
        pendingActualStartDate,
        pendingActualDeliveryDate,
        photos,
        createdAt,
        updatedAt,
      ];
}
