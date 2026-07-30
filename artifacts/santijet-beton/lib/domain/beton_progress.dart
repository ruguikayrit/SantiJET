import '../entities/concrete_discovery.dart';
import '../entities/concrete_order.dart';
import '../entities/concrete_pour.dart';

/// Keşif / döküm / sipariş özet hesapları.
abstract final class BetonProgress {
  static double sumPlanned(List<ConcreteDiscoveryItem> items) =>
      items.fold(0, (s, e) => s + e.plannedM3);

  static double sumPoured(List<ConcretePour> pours) =>
      pours.fold(0, (s, e) => s + e.volumeM3);

  static double sumOrdered(List<ConcreteOrder> orders) =>
      orders.fold(0, (s, e) => s + e.plannedM3);

  static double progressPercent({
    required double plannedM3,
    required double pouredM3,
  }) {
    if (plannedM3 <= 0) return pouredM3 > 0 ? 100 : 0;
    return ((pouredM3 / plannedM3) * 100).clamp(0, 999);
  }

  static double orderGap({
    required double orderedM3,
    required double pouredM3,
  }) =>
      pouredM3 - orderedM3;

  static double remaining({
    required double plannedM3,
    required double pouredM3,
  }) =>
      (plannedM3 - pouredM3).clamp(0, double.infinity);

  static String fmtM3(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    if (v.abs() >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}

class ElementProgressRow {
  const ElementProgressRow({
    required this.elementName,
    required this.plannedM3,
    required this.pouredM3,
    this.location = '',
    this.concreteClass = '',
  });

  final String elementName;
  final double plannedM3;
  final double pouredM3;
  final String location;
  final String concreteClass;

  double get remainingM3 => BetonProgress.remaining(
        plannedM3: plannedM3,
        pouredM3: pouredM3,
      );

  double get progressPct => BetonProgress.progressPercent(
        plannedM3: plannedM3,
        pouredM3: pouredM3,
      );
}
