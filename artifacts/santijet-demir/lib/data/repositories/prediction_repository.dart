import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';

class PredictionRepository {
  PredictionRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _historyDomain = 'prediction_history';
  static const _configDomain = 'prediction_config';

  PredictionConfig readConfig(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _configDomain);
    return PredictionConfig.fromJson(raw);
  }

  Future<void> writeConfig(String projectId, PredictionConfig config) async {
    await _projectDataRepository.writeDomain(
      projectId,
      _configDomain,
      config.toJson(),
    );
  }

  List<PredictionHistoryEntry> readHistory(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _historyDomain);
    final items = raw?['items'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map(PredictionHistoryEntry.fromJson)
        .toList()
      ..sort((a, b) => b.snapshot.createdAt.compareTo(a.snapshot.createdAt));
  }

  Future<void> writeHistory(
    String projectId,
    List<PredictionHistoryEntry> entries,
  ) async {
    await _projectDataRepository.writeDomain(projectId, _historyDomain, {
      'items': entries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> appendHistory(
    String projectId,
    PredictionHistoryEntry entry, {
    int limit = 30,
  }) async {
    final list = [entry, ...readHistory(projectId)];
    await writeHistory(projectId, list.take(limit).toList());
  }
}
