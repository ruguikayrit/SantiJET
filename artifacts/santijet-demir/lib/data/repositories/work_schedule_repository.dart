import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';

class WorkScheduleRepository {
  WorkScheduleRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'work_schedule';
  static const _schemaVersion = 2;

  List<WorkScheduleImalat> read(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    if (raw == null) return [];

    final version = (raw['version'] as num?)?.toInt() ?? 1;
    final items = raw['items'];
    if (items is! List) return [];

    if (version >= _schemaVersion) {
      return items
          .whereType<Map>()
          .map(WorkScheduleImalat.fromJson)
          .where((item) => item.imalatId.isNotEmpty)
          .toList()
        ..sort((a, b) => a.imalatName.compareTo(b.imalatName));
    }

    // Eski günlük format — imalat adlarını tarih olmadan taşı.
    final migrated = <String, WorkScheduleImalat>{};
    for (final rawItem in items.whereType<Map>()) {
      if (rawItem.containsKey('startDate') || rawItem.containsKey('imalatId')) {
        final item = WorkScheduleImalat.fromJson(rawItem);
        if (item.imalatId.isEmpty) continue;
        migrated[item.imalatId] = item;
        continue;
      }
      final day = WorkScheduleDay.fromJson(rawItem);
      for (final activity in day.activities) {
        final imalatId = activity.imalatId;
        if (imalatId == null || imalatId.isEmpty) continue;
        migrated.putIfAbsent(
          imalatId,
          () => WorkScheduleImalat(
            id: 'ws-$imalatId',
            imalatId: imalatId,
            imalatName: activity.imalatName,
          ),
        );
      }
    }
    return migrated.values.toList()
      ..sort((a, b) => a.imalatName.compareTo(b.imalatName));
  }

  Future<void> write(String projectId, List<WorkScheduleImalat> items) async {
    await _projectDataRepository.writeDomain(projectId, _domain, {
      'version': _schemaVersion,
      'items': items.map((item) => item.toJson()).toList(),
    });
  }
}
