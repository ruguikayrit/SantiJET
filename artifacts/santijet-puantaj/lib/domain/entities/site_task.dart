import 'package:equatable/equatable.dart';

import '../../core/utils/puantaj_date.dart';
import '../enums/task_status.dart';
import '../permissions/role_degree.dart';
import 'person.dart';

/// Göreve eklenen fotoğraf — Hive’da base64.
class TaskPhoto extends Equatable {
  const TaskPhoto({
    required this.id,
    required this.dataBase64,
    this.mimeType = 'image/jpeg',
    this.createdAt,
  });

  final String id;
  final String dataBase64;
  final String mimeType;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataBase64': dataBase64,
        'mimeType': mimeType,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory TaskPhoto.fromJson(Map<String, dynamic> json) => TaskPhoto(
        id: json['id'] as String? ?? '',
        dataBase64: json['dataBase64'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? 'image/jpeg',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, dataBase64, mimeType, createdAt];
}

/// Proje kapsamındaki saha görevi — atayan + atanan görünür.
class SiteTask extends Equatable {
  const SiteTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.category = '',
    this.assignee = '',
    this.assigneePersonId = '',
    this.assignerPersonId = '',
    this.assignerName = '',
    this.earliestStart = '',
    this.dueDate = '',
    this.actualDeliveryDate = '',
    this.status = TaskStatus.todo,
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

  /// Atanan personel görünen adı (önbellek).
  final String assignee;

  /// Atanan personel id — görünürlük için zorunlu.
  final String assigneePersonId;

  /// Görevi oluşturup atayan 1. derece personel id.
  final String assignerPersonId;

  /// Atayan görünen adı (önbellek).
  final String assignerName;

  /// En erken başlangıç — TR `dd.MM.yyyy`.
  final String earliestStart;

  /// En geç planlanan bitiş — TR `dd.MM.yyyy` (eski ad: dueDate).
  final String dueDate;

  /// Gerçekleşen bitiş tarihi — tamamlanınca kaydedilir (TR `dd.MM.yyyy`).
  final String actualDeliveryDate;
  final TaskStatus status;

  /// Görev atanırken eklenen fotoğraflar.
  final List<TaskPhoto> photos;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime? get earliestStartDate => PuantajDate.tryParse(earliestStart);
  DateTime? get latestDeliveryDate => PuantajDate.tryParse(dueDate);
  DateTime? get actualDeliveryDateTime =>
      PuantajDate.tryParse(actualDeliveryDate);

  /// Görüntüleyen yalnızca atayan veya atanan ise görür.
  /// Eski kayıtlarda id yoksa yalnızca 1. derece görür (yeniden atama için).
  bool isVisibleTo(Person viewer) {
    if (assigneePersonId.isNotEmpty || assignerPersonId.isNotEmpty) {
      return viewer.id == assigneePersonId || viewer.id == assignerPersonId;
    }
    return RoleDegree.isFirstDegree(viewer);
  }

  SiteTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? category,
    String? assignee,
    String? assigneePersonId,
    String? assignerPersonId,
    String? assignerName,
    String? earliestStart,
    String? dueDate,
    String? actualDeliveryDate,
    TaskStatus? status,
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
      assignee: assignee ?? this.assignee,
      assigneePersonId: assigneePersonId ?? this.assigneePersonId,
      assignerPersonId: assignerPersonId ?? this.assignerPersonId,
      assignerName: assignerName ?? this.assignerName,
      earliestStart: earliestStart ?? this.earliestStart,
      dueDate: dueDate ?? this.dueDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'category': category,
        'assignee': assignee,
        'assigneePersonId': assigneePersonId,
        'assignerPersonId': assignerPersonId,
        'assignerName': assignerName,
        'earliestStart': earliestStart,
        'dueDate': dueDate,
        'actualDeliveryDate': actualDeliveryDate,
        'status': status.storage,
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
      assignee: json['assignee'] as String? ?? '',
      assigneePersonId: json['assigneePersonId'] as String? ?? '',
      assignerPersonId: json['assignerPersonId'] as String? ?? '',
      assignerName: json['assignerName'] as String? ?? '',
      earliestStart: json['earliestStart'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      actualDeliveryDate: json['actualDeliveryDate'] as String? ?? '',
      status: TaskStatus.fromStorage(json['status'] as String?),
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
        assignee,
        assigneePersonId,
        assignerPersonId,
        assignerName,
        earliestStart,
        dueDate,
        actualDeliveryDate,
        status,
        photos,
        createdAt,
        updatedAt,
      ];
}
