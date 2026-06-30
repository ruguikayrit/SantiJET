import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/mock/mock_deliveries.dart';
import 'package:santijet_demir/data/repositories/delivery_repository.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/incoming_rebar/delivery_status_utils.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(ref.watch(projectDataRepositoryProvider));
});

final deliveriesProvider =
    StateNotifierProvider<DeliveriesNotifier, List<DeliveryItem>>((ref) {
  final notifier = DeliveriesNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) {
      notifier.loadForProject(next);
    }
  });
  return notifier;
});

final inTransitOrdersProvider = Provider<List<OrderItem>>((ref) {
  return ref
      .watch(ordersProvider)
      .where((order) => order.status == OrderStatus.inTransit)
      .toList();
});

class IncomingRebarDashboardSummary {
  const IncomingRebarDashboardSummary({
    required this.totalOrdered,
    required this.totalDelivered,
    required this.remainingOrder,
    required this.missing,
    required this.excess,
    required this.fulfillmentPercent,
  });

  final double totalOrdered;
  final double totalDelivered;

  /// Net kalan sipariş: toplam sipariş − toplam teslim.
  final double remainingOrder;

  /// Çap bazında teslim < sipariş farklarının toplamı.
  final double missing;

  /// Çap bazında teslim > sipariş farklarının toplamı.
  final double excess;
  final double fulfillmentPercent;
}

IncomingRebarDashboardSummary computeIncomingRebarSummary(
  List<DeliveryItem> deliveries, {
  Set<int> surveyDiameters = const {},
}) {
  var totalOrdered = 0.0;
  var totalDelivered = 0.0;
  var missing = 0.0;
  var excess = 0.0;

  for (final delivery in deliveries) {
    for (final line in delivery.diameterLines) {
      if (surveyDiameters.isNotEmpty &&
          !surveyDiameters.contains(line.diameter)) {
        continue;
      }
      totalOrdered += line.ordered;
      totalDelivered += line.delivered;
      if (line.delivered < line.ordered) {
        missing += line.ordered - line.delivered;
      } else if (line.delivered > line.ordered) {
        excess += line.delivered - line.ordered;
      }
    }
  }

  final remainingOrder = totalOrdered - totalDelivered;
  final fulfillmentPercent = totalOrdered > 0
      ? (totalDelivered / totalOrdered * 100)
      : 0.0;

  return IncomingRebarDashboardSummary(
    totalOrdered: totalOrdered,
    totalDelivered: totalDelivered,
    remainingOrder: remainingOrder,
    missing: missing,
    excess: excess,
    fulfillmentPercent: fulfillmentPercent,
  );
}

final incomingRebarDashboardSummaryProvider =
    Provider<IncomingRebarDashboardSummary>((ref) {
  final deliveries = ref.watch(deliveriesProvider);
  final surveyDiameters = surveyDiametersFromImalats(
    ref.watch(surveyProjectProvider).imalats,
  );
  return computeIncomingRebarSummary(
    deliveries,
    surveyDiameters: surveyDiameters,
  );
});

class DeliveredDiameterRow {
  const DeliveredDiameterRow({
    required this.diameter,
    required this.ordered,
    required this.delivered,
  });

  final int diameter;
  final double ordered;
  final double delivered;
}

final deliveredDiameterRowsProvider = Provider<List<DeliveredDiameterRow>>((ref) {
  final deliveries = ref.watch(deliveriesProvider);
  final surveyDiameters = surveyDiametersFromImalats(
    ref.watch(surveyProjectProvider).imalats,
  );
  final totals = <int, ({double ordered, double delivered})>{};

  for (final delivery in deliveries) {
    for (final line in delivery.diameterLines) {
      if (!surveyDiameters.contains(line.diameter)) continue;
      final current = totals[line.diameter];
      totals[line.diameter] = (
        ordered: (current?.ordered ?? 0) + line.ordered,
        delivered: (current?.delivered ?? 0) + line.delivered,
      );
    }
  }

  return totals.entries
      .where((entry) => entry.value.delivered > 0 || entry.value.ordered > 0)
      .map(
        (entry) => DeliveredDiameterRow(
          diameter: entry.key,
          ordered: entry.value.ordered,
          delivered: entry.value.delivered,
        ),
      )
      .toList()
    ..sort((a, b) => a.diameter.compareTo(b.diameter));
});

final deliveryFilterProvider = StateProvider<int>((ref) => 0);

final filteredDeliveriesProvider = Provider<List<DeliveryItem>>((ref) {
  final deliveries = ref.watch(deliveriesProvider);
  final filterIndex = ref.watch(deliveryFilterProvider);

  if (filterIndex == 0) return deliveries;

  final status = DeliveryStatus.values[filterIndex - 1];
  return deliveries.where((delivery) => delivery.status == status).toList();
});

final supplierPerformanceProvider = Provider<List<SupplierPerformance>>((ref) {
  return getMockSupplierPerformance();
});

final newDeliveryDraftProvider =
    StateNotifierProvider<NewDeliveryDraftNotifier, NewDeliveryDraft>(
  (ref) => NewDeliveryDraftNotifier(ref),
);

enum DeliverySaveResult {
  success,
  missingOrder,
  invalidOrderStatus,
  missingIrsaliye,
  missingDeliveredAmount,
  orderNotFound,
}

class DeliveriesNotifier extends StateNotifier<List<DeliveryItem>> {
  DeliveriesNotifier(this._ref) : super(const []) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _loadedProjectId;

  DeliveryRepository get _repo => _ref.read(deliveryRepositoryProvider);

  void loadForProject(String? projectId) {
    _loadedProjectId = projectId;
    if (projectId == null) {
      state = [];
      return;
    }
    state = _repo.read(projectId);
  }

  Future<void> _persist() async {
    final projectId = _loadedProjectId;
    if (projectId == null) return;
    await _repo.write(projectId, state);
  }

  Future<DeliverySaveResult> saveDelivery(NewDeliveryDraft draft) async {
    final orderId = draft.orderId;
    if (orderId == null || orderId.isEmpty) {
      return DeliverySaveResult.missingOrder;
    }

    final irsaliyeNo = draft.irsaliyeNo.trim();
    if (irsaliyeNo.isEmpty) return DeliverySaveResult.missingIrsaliye;

    final orders = _ref.read(ordersProvider);
    final order = orders.cast<OrderItem?>().firstWhere(
          (item) => item?.id == orderId,
          orElse: () => null,
        );
    if (order == null) return DeliverySaveResult.orderNotFound;
    if (order.status != OrderStatus.inTransit) {
      return DeliverySaveResult.invalidOrderStatus;
    }

    final diameterLines = draft.orderedDiameters.entries
        .map(
          (entry) => DeliveryDiameterLine(
            diameter: entry.key,
            ordered: entry.value,
            delivered: draft.diameterEntries[entry.key] ?? 0,
          ),
        )
        .where((line) => line.ordered > 0 || line.delivered > 0)
        .toList();

    final totalOrdered = draft.totalOrdered;
    final totalDelivered = draft.totalDelivered;
    if (totalDelivered <= 0) {
      return DeliverySaveResult.missingDeliveredAmount;
    }

    final fulfillmentPercent = totalOrdered > 0
        ? (totalDelivered / totalOrdered * 100).toDouble()
        : 100.0;
    final status = resolveDeliveryStatus(
      totalOrdered: totalOrdered,
      totalDelivered: totalDelivered,
      lines: diameterLines,
    );

    final delivery = DeliveryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      orderId: order.id,
      orderNo: order.orderNo,
      irsaliyeNo: irsaliyeNo,
      date: draft.date ?? DateTime.now(),
      supplier: order.supplier,
      tonnage: totalDelivered,
      fulfillmentPercent: fulfillmentPercent,
      status: status,
      diameterLines: diameterLines,
      plateNo: draft.plateNo.trim(),
    );

    state = [delivery, ...state];
    await _persist();

    await _ref.read(ordersProvider.notifier).completeDelivery(order.id);

    if (order.imalatTonnages.isNotEmpty && totalOrdered > 0) {
      final ratio = totalDelivered / totalOrdered;
      await _ref.read(surveyProjectProvider.notifier).addDeliveredTonnages(
            {
              for (final entry in order.imalatTonnages.entries)
                entry.key: entry.value * ratio,
            },
          );
    }

    return DeliverySaveResult.success;
  }
}

class NewDeliveryDraftNotifier extends StateNotifier<NewDeliveryDraft> {
  NewDeliveryDraftNotifier(this._ref)
      : super(NewDeliveryDraft(date: DateTime.now()));

  final Ref _ref;

  void loadFromOrder(String orderId) {
    final order = _ref.read(ordersProvider).cast<OrderItem?>().firstWhere(
          (item) => item?.id == orderId,
          orElse: () => null,
        );
    if (order == null) return;

    final surveyPlanned = computeSurveyPlannedByDiameterForImalats(
      _ref.read(surveyProjectProvider).imalats,
      order.imalatTypes,
    );
    final lines = calculateDiameterLinesFromSurvey(
      totalTonnage: order.tonnage,
      surveyPlannedByDiameter: surveyPlanned,
    );
    final orderedDiameters = {
      for (final line in lines) line.diameter: line.orderAmount,
    };

    state = NewDeliveryDraft(
      orderId: order.id,
      supplier: order.supplier,
      orderNo: order.orderNo,
      date: DateTime.now(),
      orderedDiameters: orderedDiameters,
      diameterEntries: {
        for (final diameter in orderedDiameters.keys) diameter: 0,
      },
    );
  }

  void setIrsaliyeNo(String value) {
    state = state.copyWith(irsaliyeNo: value);
  }

  void setPlateNo(String value) {
    state = state.copyWith(plateNo: value);
  }

  void setDiameterEntry(int diameter, double value) {
    final updated = Map<int, double>.from(state.diameterEntries);
    updated[diameter] = value;
    state = state.copyWith(diameterEntries: updated);
  }

  void reset() {
    state = NewDeliveryDraft(date: DateTime.now());
  }
}
