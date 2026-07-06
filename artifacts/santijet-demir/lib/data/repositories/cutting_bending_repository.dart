import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';

class CuttingBendingRepository {
  CuttingBendingRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'cutting_bending';

  List<CuttingBendingBatch> readBatches(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    if (raw == null) return [];

    final batches = raw['batches'];
    if (batches is! List) return [];

    final parsed = <CuttingBendingBatch>[];
    for (final batch in batches) {
      if (batch is! Map) continue;
      try {
        parsed.add(CuttingBendingBatch.fromJson(batch));
      } catch (_) {
        // Bozuk kayıt tüm listeyi düşürmesin.
      }
    }

    return parsed..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String? readActiveBatchId(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    return raw?['activeBatchId'] as String?;
  }

  Future<CuttingBendingBatch> addBatch({
    required String projectId,
    required CuttingBendingBatch batch,
    bool setActive = true,
  }) async {
    final existing = readBatches(projectId);
    final updated = [batch, ...existing.where((b) => b.id != batch.id)];

    await _projectDataRepository.writeDomain(projectId, _domain, {
      'batches': updated.map((b) => b.toJson()).toList(),
      'activeBatchId': setActive ? batch.id : readActiveBatchId(projectId),
    });

    return batch;
  }

  Future<void> updateBatch({
    required String projectId,
    required CuttingBendingBatch batch,
  }) async {
    final existing = readBatches(projectId);
    final updated = existing
        .map((item) => item.id == batch.id ? batch : item)
        .toList();

    await _projectDataRepository.writeDomain(projectId, _domain, {
      'batches': updated.map((b) => b.toJson()).toList(),
      'activeBatchId': readActiveBatchId(projectId) ?? batch.id,
    });
  }

  Future<void> setActiveBatch({
    required String projectId,
    required String batchId,
  }) async {
    final existing = readBatches(projectId);
    await _projectDataRepository.writeDomain(projectId, _domain, {
      'batches': existing.map((b) => b.toJson()).toList(),
      'activeBatchId': batchId,
    });
  }

  Future<void> deleteBatch({
    required String projectId,
    required String batchId,
  }) async {
    await deleteBatches(projectId: projectId, batchIds: {batchId});
  }

  Future<void> deleteBatches({
    required String projectId,
    required Set<String> batchIds,
  }) async {
    if (batchIds.isEmpty) return;

    final existing =
        readBatches(projectId).where((batch) => !batchIds.contains(batch.id)).toList();
    final activeId = readActiveBatchId(projectId);
    String? nextActiveId = activeId;
    if (activeId != null && batchIds.contains(activeId)) {
      nextActiveId = existing.firstOrNull?.id;
    } else if (activeId != null && !existing.any((batch) => batch.id == activeId)) {
      nextActiveId = existing.firstOrNull?.id;
    }

    await _projectDataRepository.writeDomain(projectId, _domain, {
      'batches': existing.map((batch) => batch.toJson()).toList(),
      if (nextActiveId != null) 'activeBatchId': nextActiveId,
    });
  }
}
