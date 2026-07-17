import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';

class WorkScheduleRepository {
  WorkScheduleRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'work_schedule';

  List<WorkScheduleDay> read(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    final items = raw?['items'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(WorkScheduleDay.fromJson)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> write(String projectId, List<WorkScheduleDay> days) async {
    await _projectDataRepository.writeDomain(projectId, _domain, {
      'items': days.map((d) => d.toJson()).toList(),
    });
  }
}
