import 'package:equatable/equatable.dart';

class ArchiveFile extends Equatable {
  const ArchiveFile({
    required this.id,
    required this.projectId,
    required this.name,
    required this.ext,
    required this.mime,
    required this.size,
    required this.storageKey,
    required this.addedAt,
    required this.note,
  });

  final String id;
  final String projectId;
  final String name;
  final String ext;
  final String mime;
  final int size;
  final String storageKey;
  final String addedAt;
  final String note;

  ArchiveFile copyWith({
    String? id,
    String? projectId,
    String? name,
    String? ext,
    String? mime,
    int? size,
    String? storageKey,
    String? addedAt,
    String? note,
  }) {
    return ArchiveFile(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      ext: ext ?? this.ext,
      mime: mime ?? this.mime,
      size: size ?? this.size,
      storageKey: storageKey ?? this.storageKey,
      addedAt: addedAt ?? this.addedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'ext': ext,
        'mime': mime,
        'size': size,
        'storageKey': storageKey,
        'addedAt': addedAt,
        'note': note,
      };

  factory ArchiveFile.fromJson(Map<String, dynamic> json) {
    return ArchiveFile(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ext: json['ext']?.toString() ?? '',
      mime: json['mime']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      storageKey: json['storageKey']?.toString() ?? '',
      addedAt: json['addedAt']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, name, ext, mime, size, storageKey, addedAt, note];
}
