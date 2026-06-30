import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

DeliveryStatus resolveDeliveryStatus({
  required double totalOrdered,
  required double totalDelivered,
  required List<DeliveryDiameterLine> lines,
}) {
  if (totalDelivered <= 0.05) return DeliveryStatus.pending;
  if (lines.every((line) => line.isMatch)) return DeliveryStatus.received;
  if (lines.any((line) => line.isExcess)) return DeliveryStatus.excess;

  final ratio = totalOrdered > 0 ? totalDelivered / totalOrdered : 0;
  if (ratio >= 0.99) return DeliveryStatus.received;
  if (ratio > 0) return DeliveryStatus.partial;
  return DeliveryStatus.missing;
}
