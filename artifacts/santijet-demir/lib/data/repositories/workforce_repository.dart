import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/workforce.dart';

class WorkforceRepository {
  WorkforceRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'workforce';

  List<WorkforceEntry> read(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    final items = raw?['items'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(WorkforceEntry.fromJson)
        .where((e) => e.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> write(String projectId, List<WorkforceEntry> entries) async {
    await _projectDataRepository.writeDomain(projectId, _domain, {
      'items': entries.map((e) => e.toJson()).toList(),
    });
  }
}
