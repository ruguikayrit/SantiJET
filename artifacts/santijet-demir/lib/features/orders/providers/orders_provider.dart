import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/order_repository.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/domain/permissions/app_permission.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/orders/order_imalat_balance.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(projectDataRepositoryProvider));
});

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<OrderItem>>((ref) {
  final notifier = OrdersNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) {
      notifier.loadForProject(next);
    }
  });
  return notifier;
});

final orderFilterProvider = StateProvider<int>((ref) => 0);

const orderFilterLabels = [
  'Tümü',
  'Onay Bekleyen',
  'Verildi',
  'Yolda',
  'Tamamlandı',
  'İptal',
];

const _filterStatuses = [
  OrderStatus.pendingApproval,
  OrderStatus.submitted,
  OrderStatus.inTransit,
  OrderStatus.completed,
  OrderStatus.cancelled,
];

const _individualOrderFilterLabels = [
  'Tümü',
  'Verildi',
  'Yolda',
  'Tamamlandı',
  'İptal',
];

const _individualFilterStatuses = [
  OrderStatus.submitted,
  OrderStatus.inTransit,
  OrderStatus.completed,
  OrderStatus.cancelled,
];

bool _isIndividualMembership(Ref ref) {
  return ref.read(authProvider).user?.membershipType !=
      MembershipType.corporate;
}

final orderFilterLabelsProvider = Provider<List<String>>((ref) {
  final membership =
      ref.watch(authProvider).user?.membershipType ?? MembershipType.individual;
  return membership == MembershipType.individual
      ? _individualOrderFilterLabels
      : orderFilterLabels;
});

final filteredOrdersProvider = Provider<List<OrderItem>>((ref) {
  final orders = ref.watch(ordersProvider);
  final filterIndex = ref.watch(orderFilterProvider);
  final membership =
      ref.watch(authProvider).user?.membershipType ?? MembershipType.individual;
  final statuses = membership == MembershipType.individual
      ? _individualFilterStatuses
      : _filterStatuses;

  if (filterIndex == 0) return orders;
  if (filterIndex < 1 || filterIndex > statuses.length) return orders;

  final status = statuses[filterIndex - 1];
  return orders.where((order) => order.status == status).toList();
});

class OrdersDashboardSummary {
  const OrdersDashboardSummary({
    required this.pendingApprovalTonnage,
    required this.inTransitTonnage,
  });

  final double pendingApprovalTonnage;
  final double inTransitTonnage;
}

final ordersDashboardSummaryProvider = Provider<OrdersDashboardSummary>((ref) {
  final orders = ref.watch(ordersProvider);

  var pendingApprovalTonnage = 0.0;
  var inTransitTonnage = 0.0;

  for (final order in orders) {
    if (order.status == OrderStatus.pendingApproval) {
      pendingApprovalTonnage += order.tonnage;
    } else if (order.status == OrderStatus.inTransit) {
      inTransitTonnage += order.tonnage;
    }
  }

  return OrdersDashboardSummary(
    pendingApprovalTonnage: pendingApprovalTonnage,
    inTransitTonnage: inTransitTonnage,
  );
});

final imalatOrderBalanceProvider = Provider<List<ImalatOrderBalance>>((ref) {
  final survey = ref.watch(surveyProjectProvider);
  final orders = ref.watch(ordersProvider);

  return buildImalatOrderBalances(
    surveyTotalsByName: {
      for (final imalat in survey.imalats) imalat.name: imalat.planned,
    },
    orders: orders,
  );
});

class OrdersNotifier extends StateNotifier<List<OrderItem>> {
  OrdersNotifier(this._ref) : super(const []) {
    loadForProject(_ref.read(activeProjectIdProvider));
    _ref.listen(authProvider, (previous, next) {
      final wasCorporate =
          previous?.user?.membershipType == MembershipType.corporate;
      final isIndividual =
          next.user?.membershipType == MembershipType.individual;
      if (wasCorporate && isIndividual) {
        promotePendingApprovalsForIndividual();
      }
    });
  }

  final Ref _ref;
  String? _loadedProjectId;

  OrderRepository get _repo => _ref.read(orderRepositoryProvider);

  bool get _isIndividual => _isIndividualMembership(_ref);

  void loadForProject(String? projectId) {
    _loadedProjectId = projectId;
    if (projectId == null) {
      state = [];
      return;
    }
    state = _repo.read(projectId);
    if (_isIndividual) {
      // Fire-and-forget: bireysel hesapta bekleyen onayları Verildi'ye çek.
      promotePendingApprovalsForIndividual();
    }
  }

  Future<void> _persist() async {
    final projectId = _loadedProjectId;
    if (projectId == null) return;
    await _repo.write(projectId, state);
  }

  String _nextOrderNo() {
    final year = DateTime.now().year;
    final prefix = 'SP-$year-';
    final existing = state
        .where((order) => order.orderNo.startsWith(prefix))
        .length;
    return '$prefix${(existing + 1).toString().padLeft(4, '0')}';
  }

  /// Bireysel kullanımda onay bekleyen siparişleri doğrudan Verildi yapar.
  Future<void> promotePendingApprovalsForIndividual() async {
    if (!_isIndividual) return;

    final pending = state
        .where((order) => order.status == OrderStatus.pendingApproval)
        .toList();
    if (pending.isEmpty) return;

    final updated = [
      for (final order in state)
        if (order.status == OrderStatus.pendingApproval)
          order.copyWith(status: OrderStatus.submitted)
        else
          order,
    ];
    state = updated;
    await _persist();

    for (final order in pending) {
      if (order.imalatTonnages.isEmpty) continue;
      await _ref
          .read(surveyProjectProvider.notifier)
          .addOrderedTonnages(order.imalatTonnages);
    }
  }

  Future<OrderItem?> createOrder(NewOrderDraft draft) async {
    final projectId = _loadedProjectId;
    final supplier = draft.selectedSupplier;
    if (projectId == null || supplier == null) return null;

    final imalatTonnages = {
      for (final name in draft.selectedImalats.keys)
        name: draft.imalatOrderTonnage(name),
    };

    final skipApproval = _isIndividual;
    final order = OrderItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      orderNo: _nextOrderNo(),
      date: DateTime.now(),
      imalatTypes: draft.selectedImalats.keys.toList(),
      tonnage: draft.finalOrderTonnage,
      status: skipApproval ? OrderStatus.submitted : OrderStatus.pendingApproval,
      supplier: supplier.name,
      imalatTonnages: imalatTonnages,
    );

    state = [order, ...state];
    await _persist();

    if (skipApproval && imalatTonnages.isNotEmpty) {
      await _ref
          .read(surveyProjectProvider.notifier)
          .addOrderedTonnages(imalatTonnages);
    }

    return order;
  }

  Future<OrderApprovalResult> approveOrderRole(
    String orderId,
    OrderApproverRole role,
  ) async {
    final user = _ref.read(authProvider).user;
    final permissions = AppPermissionMatrix.forMembership(
      membershipType: user?.membershipType ??
          MembershipType.individual,
      corporateRole: user?.corporateRole,
    );
    if (!AppPermissionMatrix.canApproveOrderRole(permissions, role)) {
      return OrderApprovalResult.notPending;
    }

    final index = state.indexWhere((order) => order.id == orderId);
    if (index < 0) return OrderApprovalResult.notFound;

    final order = state[index];
    if (order.status != OrderStatus.pendingApproval) {
      return OrderApprovalResult.notPending;
    }
    if (order.approvals.isApproved(role)) {
      return OrderApprovalResult.alreadyApproved;
    }

    final approvals = order.approvals.approve(role);
    final updated = List<OrderItem>.from(state);
    final completed = approvals.isComplete;
    updated[index] = order.copyWith(
      approvals: approvals,
      status: completed ? OrderStatus.submitted : order.status,
    );
    state = updated;
    await _persist();

    if (completed && order.imalatTonnages.isNotEmpty) {
      await _ref
          .read(surveyProjectProvider.notifier)
          .addOrderedTonnages(order.imalatTonnages);
    }

    return OrderApprovalResult.success(
      completed: completed,
      role: role,
    );
  }

  Future<void> advanceStatus(String orderId) async {
    final index = state.indexWhere((order) => order.id == orderId);
    if (index < 0) return;

    final order = state[index];
    final next = order.status.nextStatus;
    if (next == null) return;

    final updated = List<OrderItem>.from(state);
    updated[index] = order.copyWith(status: next);
    state = updated;
    await _persist();
  }

  Future<void> completeDelivery(String orderId) async {
    final index = state.indexWhere((order) => order.id == orderId);
    if (index < 0) return;

    final order = state[index];
    if (order.status != OrderStatus.inTransit) return;

    final updated = List<OrderItem>.from(state);
    updated[index] = order.copyWith(status: OrderStatus.completed);
    state = updated;
    await _persist();
  }

  Future<OrderCancelResult> cancelOrder({
    required String orderId,
    required String cancelledByName,
    required String cancellationReason,
  }) async {
    final index = state.indexWhere((order) => order.id == orderId);
    if (index < 0) return OrderCancelResult.notFound;

    final order = state[index];
    if (!order.status.canCancel) return OrderCancelResult.notCancellable;

    final name = cancelledByName.trim();
    final reason = cancellationReason.trim();
    if (name.isEmpty || reason.isEmpty) {
      return OrderCancelResult.invalidInput;
    }

    final cancellation = OrderCancellation(
      cancelledByName: name,
      cancellationReason: reason,
      cancelledAt: DateTime.now(),
    );

    final updated = List<OrderItem>.from(state);
    updated[index] = order.copyWith(
      status: OrderStatus.cancelled,
      cancellation: cancellation,
    );
    state = updated;
    await _persist();

    if (order.imalatTonnages.isNotEmpty) {
      await _ref
          .read(surveyProjectProvider.notifier)
          .subtractOrderedTonnages(order.imalatTonnages);
    }

    return OrderCancelResult.success;
  }

  /// Onay sürecinde red — siparişi iptal eder. Açıklama zorunlu.
  Future<OrderRejectResult> rejectOrderRole({
    required String orderId,
    required OrderApproverRole role,
    required String rejectedByName,
    required String rejectionReason,
  }) async {
    final user = _ref.read(authProvider).user;
    final permissions = AppPermissionMatrix.forMembership(
      membershipType: user?.membershipType ?? MembershipType.individual,
      corporateRole: user?.corporateRole,
    );
    if (!AppPermissionMatrix.canApproveOrderRole(permissions, role)) {
      return OrderRejectResult.notAllowed;
    }

    final index = state.indexWhere((order) => order.id == orderId);
    if (index < 0) return OrderRejectResult.notFound;

    final order = state[index];
    if (order.status != OrderStatus.pendingApproval) {
      return OrderRejectResult.notPending;
    }

    final name = rejectedByName.trim();
    final reason = rejectionReason.trim();
    if (reason.isEmpty) return OrderRejectResult.invalidInput;

    final displayName = name.isEmpty ? role.label : name;

    final updated = List<OrderItem>.from(state);
    updated[index] = order.copyWith(
      status: OrderStatus.cancelled,
      cancellation: OrderCancellation(
        cancelledByName: displayName,
        cancellationReason: reason,
        cancelledAt: DateTime.now(),
        rejectedByRole: role,
      ),
    );
    state = updated;
    await _persist();
    // Onay tamamlanmadan sipariş tonajı keşfe yazılmadığı için geri alma yok.
    return OrderRejectResult.success;
  }
}

enum OrderApprovalResultType {
  success,
  alreadyApproved,
  notPending,
  notFound,
}

enum OrderCancelResult {
  success,
  notFound,
  notCancellable,
  invalidInput,
}

enum OrderRejectResult {
  success,
  notFound,
  notPending,
  notAllowed,
  invalidInput,
}

class OrderApprovalResult {
  const OrderApprovalResult._({
    required this.type,
    this.completed = false,
    this.role,
  });

  factory OrderApprovalResult.success({
    required bool completed,
    required OrderApproverRole role,
  }) {
    return OrderApprovalResult._(
      type: OrderApprovalResultType.success,
      completed: completed,
      role: role,
    );
  }

  static const alreadyApproved =
      OrderApprovalResult._(type: OrderApprovalResultType.alreadyApproved);
  static const notPending =
      OrderApprovalResult._(type: OrderApprovalResultType.notPending);
  static const notFound =
      OrderApprovalResult._(type: OrderApprovalResultType.notFound);

  final OrderApprovalResultType type;
  final bool completed;
  final OrderApproverRole? role;
}

final newOrderDraftProvider =
    StateNotifierProvider<NewOrderDraftNotifier, NewOrderDraft>(
  (ref) => NewOrderDraftNotifier(ref),
);

class NewOrderDraftNotifier extends StateNotifier<NewOrderDraft> {
  NewOrderDraftNotifier(this._ref) : super(NewOrderDraft());

  final Ref _ref;

  Map<int, double> _surveyPlannedForSelection() {
    return computeSurveyPlannedByDiameterForImalats(
      _ref.read(surveyProjectProvider).imalats,
      state.selectedImalats.keys,
    );
  }

  List<DiameterOrderLine> _defaultDiameterLines() {
    return calculateDiameterLinesFromSurvey(
      totalTonnage: state.totalTonnage,
      surveyPlannedByDiameter: _surveyPlannedForSelection(),
    );
  }

  void toggleImalat(String name, double tonnage) {
    final updatedImalats = Map<String, double>.from(state.selectedImalats);
    final updatedRatios = Map<String, int>.from(state.imalatRatios);

    if (updatedImalats.containsKey(name)) {
      updatedImalats.remove(name);
      updatedRatios.remove(name);
    } else {
      updatedImalats[name] = tonnage;
      updatedRatios[name] = 100;
    }

    state = state.copyWith(
      selectedImalats: updatedImalats,
      imalatRatios: updatedRatios,
      clearDiameterAmounts: true,
    );
  }

  void setImalatRatio(String name, int ratio) {
    if (!state.selectedImalats.containsKey(name)) return;

    final clamped = ratio.clamp(1, 100);
    final updatedRatios = Map<String, int>.from(state.imalatRatios)
      ..[name] = clamped;

    state = state.copyWith(
      imalatRatios: updatedRatios,
      clearDiameterAmounts: true,
    );
  }

  void syncDiameterLinesFromTotal() {
    final surveyPlanned = _surveyPlannedForSelection();
    final lines = calculateDiameterLinesFromSurvey(
      totalTonnage: state.totalTonnage,
      surveyPlannedByDiameter: surveyPlanned,
    );
    state = state.copyWith(
      surveyPlannedByDiameter: surveyPlanned,
      diameterOrderAmounts: {
        for (final line in lines) line.diameter: line.orderAmount,
      },
    );
  }

  void setDiameterOrderAmount(int diameter, double amount) {
    if (amount < 0) return;

    final updated = Map<int, double>.from(state.diameterOrderAmounts);
    if (updated.isEmpty) {
      for (final line in _defaultDiameterLines()) {
        updated[line.diameter] = line.orderAmount;
      }
    }
    updated[diameter] = amount;

    state = state.copyWith(diameterOrderAmounts: updated);
  }

  void resetDiameterAdjustments() {
    syncDiameterLinesFromTotal();
  }

  void selectSupplier(SupplierOption supplier) {
    state = state.copyWith(selectedSupplier: supplier);
  }

  void reset() {
    state = NewOrderDraft();
  }
}
