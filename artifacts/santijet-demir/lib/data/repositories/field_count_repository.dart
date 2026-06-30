import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';

class FieldCountRepository {
  FieldCountRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'field_counts';

  List<FieldCountRecord> read(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    final items = raw?['items'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(FieldCountRecord.fromJson)
        .where((record) => record.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> write(String projectId, List<FieldCountRecord> records) async {
    await _projectDataRepository.writeDomain(projectId, _domain, {
      'items': records.map((record) => record.toJson()).toList(),
    });
  }
}
