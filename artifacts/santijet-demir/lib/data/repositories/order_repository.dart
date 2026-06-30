import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/domain/entities/order.dart';

class OrderRepository {
  OrderRepository(this._projectDataRepository);

  final ProjectDataRepository _projectDataRepository;
  static const _domain = 'orders';

  List<OrderItem> read(String projectId) {
    final raw = _projectDataRepository.readDomain(projectId, _domain);
    final items = raw?['items'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(OrderItem.fromJson)
        .where((order) => order.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> write(String projectId, List<OrderItem> orders) async {
    await _projectDataRepository.writeDomain(projectId, _domain, {
      'items': orders.map((order) => order.toJson()).toList(),
    });
  }
}
