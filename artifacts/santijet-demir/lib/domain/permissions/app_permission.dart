import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/domain/entities/order.dart';

/// Uygulama özellik / sayfa yetkileri.
enum AppPermission {
  viewDashboard,
  viewOrders,
  createOrder,
  approveOrderPurchasing,
  approveOrderProjectManager,
  approveOrderEmployer,
  viewIncomingRebar,
  createDelivery,
  viewFieldCount,
  editFieldCount,
  viewSurvey,
  editSurvey,
  viewAnalysis,
  runAnalysis,
}

/// Rol → yetki matrisi.
///
/// Sipariş oluşturma: Proje Müdürü, İşveren, Şantiye Şefi.
/// Sipariş onayı: Satın Alma zorunlu + (Proje Müdürü veya İşveren).
abstract final class AppPermissionMatrix {
  static const _all = AppPermission.values;

  static Set<AppPermission> forMembership({
    required MembershipType membershipType,
    CorporateRole? corporateRole,
  }) {
    if (membershipType == MembershipType.individual) {
      // Bireysel: onay süreci yok — onay yetkileri kurumsal rolleredir.
      return {
        for (final permission in _all)
          if (permission != AppPermission.approveOrderPurchasing &&
              permission != AppPermission.approveOrderProjectManager &&
              permission != AppPermission.approveOrderEmployer)
            permission,
      };
    }

    return switch (corporateRole) {
      null => {AppPermission.viewDashboard},
      CorporateRole.employer => _all.toSet(),
      // Satın Alma: yalnızca onay + gelen demir / sipariş görüntüleme.
      CorporateRole.purchasing => {
          AppPermission.viewDashboard,
          AppPermission.viewOrders,
          AppPermission.approveOrderPurchasing,
          AppPermission.viewIncomingRebar,
        },
      // Muhasebe: sipariş + gelen demir görüntüleme.
      CorporateRole.accounting => {
          AppPermission.viewDashboard,
          AppPermission.viewOrders,
          AppPermission.viewIncomingRebar,
        },
      CorporateRole.projectManager => {
          AppPermission.viewDashboard,
          AppPermission.viewOrders,
          AppPermission.createOrder,
          AppPermission.approveOrderProjectManager,
          AppPermission.viewIncomingRebar,
          AppPermission.createDelivery,
          AppPermission.viewFieldCount,
          AppPermission.editFieldCount,
          AppPermission.viewSurvey,
          AppPermission.editSurvey,
          AppPermission.viewAnalysis,
          AppPermission.runAnalysis,
        },
      CorporateRole.siteManager => {
          AppPermission.viewDashboard,
          AppPermission.viewOrders,
          AppPermission.createOrder,
          AppPermission.viewIncomingRebar,
          AppPermission.createDelivery,
          AppPermission.viewFieldCount,
          AppPermission.editFieldCount,
          AppPermission.viewSurvey,
          AppPermission.editSurvey,
          AppPermission.viewAnalysis,
        },
    };
  }

  static bool canAccessTab(
    Set<AppPermission> permissions,
    BottomNavTab tab,
  ) {
    return switch (tab) {
      BottomNavTab.dashboard =>
        permissions.contains(AppPermission.viewDashboard),
      BottomNavTab.orders => permissions.contains(AppPermission.viewOrders),
      BottomNavTab.incomingRebar =>
        permissions.contains(AppPermission.viewIncomingRebar),
      BottomNavTab.fieldCount =>
        permissions.contains(AppPermission.viewFieldCount),
      BottomNavTab.analysis => permissions.contains(AppPermission.viewAnalysis),
    };
  }

  static bool canApproveOrderRole(
    Set<AppPermission> permissions,
    OrderApproverRole role,
  ) {
    return switch (role) {
      OrderApproverRole.purchasing =>
        permissions.contains(AppPermission.approveOrderPurchasing),
      OrderApproverRole.projectManager =>
        permissions.contains(AppPermission.approveOrderProjectManager),
      OrderApproverRole.employer =>
        permissions.contains(AppPermission.approveOrderEmployer),
    };
  }

  static List<BottomNavTab> visibleTabs(Set<AppPermission> permissions) {
    return BottomNavTab.values
        .where((tab) => canAccessTab(permissions, tab))
        .toList();
  }
}
