import 'package:equatable/equatable.dart';

import '../enums/main_discipline.dart';
import 'kesif_line.dart';

/// Hive typeId plan: 1
/// Keşif anlık görüntüsü — ileride Maliyet keşfine `kesifProjectId` ile bağlanır.
class KesifSnapshot extends Equatable {
  const KesifSnapshot({
    required this.id,
    required this.projectId,
    required this.name,
    this.kesifProjectId,
    this.source = 'mock',
    this.importedAt,
    this.lines = const [],
  });

  final String id;
  final String projectId;
  final String name;

  /// Gelecekte Maliyet/BFA keşif projesi kimliği.
  final String? kesifProjectId;

  /// mock | json | manual | cloud
  final String source;
  final DateTime? importedAt;
  final List<KesifLine> lines;

  KesifSnapshot copyWith({
    String? id,
    String? projectId,
    String? name,
    String? kesifProjectId,
    String? source,
    DateTime? importedAt,
    List<KesifLine>? lines,
  }) {
    return KesifSnapshot(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      kesifProjectId: kesifProjectId ?? this.kesifProjectId,
      source: source ?? this.source,
      importedAt: importedAt ?? this.importedAt,
      lines: lines ?? this.lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'kesifProjectId': kesifProjectId,
        'source': source,
        'importedAt': importedAt?.toIso8601String(),
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  factory KesifSnapshot.fromJson(Map<String, dynamic> json) => KesifSnapshot(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        kesifProjectId: json['kesifProjectId'] as String?,
        source: json['source'] as String? ?? 'mock',
        importedAt: json['importedAt'] != null
            ? DateTime.tryParse(json['importedAt'] as String)
            : null,
        lines: (json['lines'] as List? ?? const [])
            .map((e) => KesifLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  /// Ana → alt → poz ağacı için yardımcı.
  Map<MainDiscipline, Map<String, List<KesifLine>>> groupedTree() {
    final tree = <MainDiscipline, Map<String, List<KesifLine>>>{};
    for (final line in lines) {
      final sub = tree.putIfAbsent(line.anaGrup, () => {});
      sub.putIfAbsent(line.altGrup, () => []).add(line);
    }
    return tree;
  }

  @override
  List<Object?> get props =>
      [id, projectId, name, kesifProjectId, source, importedAt, lines];
}
