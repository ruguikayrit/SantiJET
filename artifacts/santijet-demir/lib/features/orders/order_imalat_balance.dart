import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

class ImalatOrderBalance {
  const ImalatOrderBalance({
    required this.name,
    required this.surveyTotal,
    required this.orderedSoFar,
  });

  final String name;
  final double surveyTotal;
  final double orderedSoFar;

  double get remaining =>
      (surveyTotal - orderedSoFar).clamp(0.0, double.infinity);

  bool get hasRemaining => remaining > 0.05;
}

bool orderCountsTowardImalatBalance(OrderStatus status) {
  return status == OrderStatus.pendingApproval ||
      status == OrderStatus.submitted ||
      status == OrderStatus.inTransit ||
      status == OrderStatus.completed;
}

double orderedTonnageForImalat(List<OrderItem> orders, String imalatName) {
  return orders
      .where((order) => orderCountsTowardImalatBalance(order.status))
      .fold(0.0, (sum, order) => sum + _tonnageForImalat(order, imalatName));
}

double _tonnageForImalat(OrderItem order, String imalatName) {
  if (order.imalatTonnages.isNotEmpty) {
    return order.imalatTonnages[imalatName] ?? 0;
  }

  if (!order.imalatTypes.contains(imalatName)) return 0;
  if (order.imalatTypes.length == 1) return order.tonnage;
  return order.tonnage / order.imalatTypes.length;
}

List<ImalatOrderBalance> buildImalatOrderBalances({
  required Map<String, double> surveyTotalsByName,
  required List<OrderItem> orders,
}) {
  return surveyTotalsByName.entries
      .map(
        (entry) => ImalatOrderBalance(
          name: entry.key,
          surveyTotal: entry.value,
          orderedSoFar: orderedTonnageForImalat(orders, entry.key),
        ),
      )
      .toList();
}

ImalatOrderBalance? findImalatBalance(
  List<ImalatOrderBalance> balances,
  String name,
) {
  for (final balance in balances) {
    if (balance.name == name) return balance;
  }
  return null;
}
