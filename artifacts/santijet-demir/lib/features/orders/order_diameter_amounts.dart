import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';

/// Kayıtlı çap tonajı varsa onu, yoksa keşif dağılımını döner.
Map<int, double> resolvedOrderDiameterAmounts(
  OrderItem order,
  List<SurveyImalat> imalats,
) {
  if (order.diameterAmounts.isNotEmpty) {
    return Map<int, double>.from(order.diameterAmounts);
  }
  if (order.status == OrderStatus.cancelled) return const {};

  final totals = <int, double>{};
  final imalatByName = {for (final imalat in imalats) imalat.name: imalat};

  for (final entry in order.imalatTonnages.entries) {
    final tonnage = entry.value;
    if (tonnage <= 0) continue;
    final imalat = imalatByName[entry.key];
    if (imalat == null || imalat.planned <= 0) continue;

    for (final line in imalat.diameterLines) {
      if (line.planned <= 0) continue;
      final share = line.planned / imalat.planned;
      totals[line.diameter] = (totals[line.diameter] ?? 0) + tonnage * share;
    }
  }

  return totals;
}
