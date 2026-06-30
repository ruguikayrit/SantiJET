import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';

class DeliveryRepository {
  DeliveryRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'deliveries';

  List<DeliveryItem> read(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    final items = raw?['items'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(DeliveryItem.fromJson)
        .where((delivery) => delivery.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> write(String projectId, List<DeliveryItem> deliveries) async {
    await _projectDataRepository.writeDomain(projectId, _domain, {
      'items': deliveries.map((delivery) => delivery.toJson()).toList(),
    });
  }
}
