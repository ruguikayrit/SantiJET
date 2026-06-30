import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
/// Satır bazında planlanan kullanım: keşif × ilerleme %.
double computeLinePlannedUsage({
  required double planned,
  required double progressPercent,
}) {
  final ratio = (progressPercent / 100).clamp(0.0, 1.0);
  return planned * ratio;
}

/// Keşif imalat satırlarının ilerleme oranına göre çap bazında planlanan kullanım.
///
/// Her çap satırı için: `line.planned × (line.progressPercent / 100)`
Map<int, double> computePlannedUsageByDiameter(List<SurveyImalat> imalats) {
  final totals = <int, double>{};

  for (final imalat in imalats) {
    for (final line in imalat.diameterLines) {
      if (line.planned <= 0) continue;
      totals[line.diameter] = (totals[line.diameter] ?? 0) +
          computeLinePlannedUsage(
            planned: line.planned,
            progressPercent: line.progressPercent,
          );
    }
  }

  return totals;
}

/// Seçili imalatların keşif metrajından çap bazında plan toplamı.
Map<int, double> computeSurveyPlannedByDiameterForImalats(
  List<SurveyImalat> imalats,
  Iterable<String> imalatNames,
) {
  final names = imalatNames.toSet();
  final totals = <int, double>{};

  for (final imalat in imalats) {
    if (!names.contains(imalat.name)) continue;
    for (final line in imalat.diameterLines) {
      if (line.planned <= 0) continue;
      totals[line.diameter] = (totals[line.diameter] ?? 0) + line.planned;
    }
  }

  return totals;
}

/// Keşifte tanımlı çap seti.
Set<int> surveyDiametersFromImalats(List<SurveyImalat> imalats) {
  return computeSurveyPlannedByDiameter(imalats).keys.toSet();
}

/// Keşifteki toplam planlanan metraj — çap bazında.
Map<int, double> computeSurveyPlannedByDiameter(List<SurveyImalat> imalats) {
  final totals = <int, double>{};

  for (final imalat in imalats) {
    for (final line in imalat.diameterLines) {
      if (line.planned <= 0) continue;
      totals[line.diameter] = (totals[line.diameter] ?? 0) + line.planned;
    }
  }

  return totals;
}

/// Keşifteki sipariş edilen miktar — çap bazında.
Map<int, double> computeSurveyOrderedByDiameter(List<SurveyImalat> imalats) {
  final totals = <int, double>{};

  for (final imalat in imalats) {
    for (final line in imalat.diameterLines) {
      if (line.ordered <= 0) continue;
      totals[line.diameter] = (totals[line.diameter] ?? 0) + line.ordered;
    }
  }

  return totals;
}

/// Teslimat kayıtlarından çap bazında teslim alınan miktar.
Map<int, double> computeDeliveredByDiameterFromDeliveries(
  List<DeliveryItem> deliveries, {
  Set<int>? limitToDiameters,
}) {
  final totals = <int, double>{};

  for (final delivery in deliveries) {
    for (final line in delivery.diameterLines) {
      if (limitToDiameters != null && !limitToDiameters.contains(line.diameter)) {
        continue;
      }
      if (line.delivered <= 0) continue;
      totals[line.diameter] = (totals[line.diameter] ?? 0) + line.delivered;
    }
  }

  return totals;
}

/// Teslimat kayıtlarından çap bazında sipariş edilen miktar.
Map<int, double> computeOrderedByDiameterFromDeliveries(
  List<DeliveryItem> deliveries, {
  Set<int>? limitToDiameters,
}) {
  final totals = <int, double>{};

  for (final delivery in deliveries) {
    for (final line in delivery.diameterLines) {
      if (limitToDiameters != null && !limitToDiameters.contains(line.diameter)) {
        continue;
      }
      if (line.ordered <= 0) continue;
      totals[line.diameter] = (totals[line.diameter] ?? 0) + line.ordered;
    }
  }

  return totals;
}

/// Siparişlerden çap bazında sipariş — keşif imalat/çap oranına göre dağıtılır.
Map<int, double> computeOrderedByDiameterFromOrders(
  List<OrderItem> orders,
  List<SurveyImalat> imalats,
) {
  final totals = <int, double>{};
  final imalatByName = {for (final imalat in imalats) imalat.name: imalat};

  for (final order in orders) {
    if (order.status == OrderStatus.cancelled) continue;

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
  }

  return totals;
}

List<ReconciliationRow> buildReconciliationRows({
  required List<SurveyImalat> imalats,
  required Map<int, double> deliveredByDiameter,
  required Map<int, double> plannedUsageByDiameter,
  required Map<int, double> expectedStockByDiameter,
  required Map<int, double> countedByDiameter,
  required Map<int, double> usedByDiameter,
  Map<int, double> orderedByDiameterFromDeliveries = const {},
  Map<int, double> orderedByDiameterFromOrders = const {},
}) {
  final surveyPlanned = computeSurveyPlannedByDiameter(imalats);
  final surveyOrdered = computeSurveyOrderedByDiameter(imalats);

  final diameters = surveyPlanned.isNotEmpty
      ? (surveyPlanned.keys.toList()..sort())
      : ({
          ...surveyPlanned.keys,
          ...surveyOrdered.keys,
          ...deliveredByDiameter.keys,
          ...plannedUsageByDiameter.keys,
          ...countedByDiameter.keys,
          ...orderedByDiameterFromDeliveries.keys,
          ...orderedByDiameterFromOrders.keys,
        }.toList()
          ..sort());

  return diameters
      .map((diameter) {
        final delivered = deliveredByDiameter[diameter] ?? 0.0;
        final counted = countedByDiameter[diameter] ?? 0.0;
        final plannedUsage = plannedUsageByDiameter[diameter] ?? 0.0;
        final expectedStockValue = delivered > 0
            ? (expectedStockByDiameter[diameter] ?? (delivered - plannedUsage))
            : 0.0;
        final ordered = surveyOrdered[diameter] ??
            orderedByDiameterFromOrders[diameter] ??
            orderedByDiameterFromDeliveries[diameter] ??
            0.0;
        final usedValue = usedByDiameter.containsKey(diameter)
            ? usedByDiameter[diameter]!
            : (counted > 0 ? delivered - counted : 0.0);

        return ReconciliationRow(
          diameter: diameter,
          survey: surveyPlanned[diameter] ?? 0.0,
          ordered: ordered,
          delivered: delivered,
          plannedUsage: plannedUsage,
          expectedStock: expectedStockValue,
          counted: counted,
          used: usedValue,
        );
      })
      .toList();
}

/// Mukayese satırlarından özet toplamlar — dashboard kartları ve tablo alt satırı.
class ReconciliationTotals {
  const ReconciliationTotals({
    required this.survey,
    required this.ordered,
    required this.delivered,
    required this.plannedUsage,
    required this.plannedStock,
    required this.fieldCount,
    required this.actualUsage,
    required this.fire,
  });

  final double survey;
  final double ordered;
  final double delivered;
  final double plannedUsage;
  final double plannedStock;
  final double fieldCount;
  final double actualUsage;
  final double fire;
}

ReconciliationTotals computeReconciliationTotals(List<ReconciliationRow> rows) {
  return ReconciliationTotals(
    survey: rows.fold(0.0, (sum, row) => sum + row.survey),
    ordered: rows.fold(0.0, (sum, row) => sum + row.ordered),
    delivered: rows.fold(0.0, (sum, row) => sum + row.delivered),
    plannedUsage: rows.fold(0.0, (sum, row) => sum + row.plannedUsage),
    plannedStock: rows.fold(0.0, (sum, row) => sum + row.expectedStock),
    fieldCount: rows.fold(0.0, (sum, row) => sum + row.counted),
    actualUsage: rows.fold(0.0, (sum, row) => sum + row.used),
    fire: rows.fold(0.0, (sum, row) => sum + row.fire),
  );
}

String computeFieldCountStatus(List<FieldCountLineRecord> lines) {
  if (lines.isEmpty) return 'completed';

  final maxVariance = lines
      .map((line) => (line.expectedStock - line.actual).abs())
      .fold(0.0, (max, value) => value > max ? value : max);

  if (maxVariance > 8) return 'critical';
  if (maxVariance > 2) return 'warning';
  return 'completed';
}

/// Planlanan kullanıma göre beklenen stok: teslim − plan kullanım.
Map<int, double> computeExpectedStockByDiameter({
  required Map<int, double> deliveredByDiameter,
  required Map<int, double> plannedUsageByDiameter,
}) {
  return {
    for (final entry in deliveredByDiameter.entries)
      entry.key: entry.value - (plannedUsageByDiameter[entry.key] ?? 0),
  };
}
