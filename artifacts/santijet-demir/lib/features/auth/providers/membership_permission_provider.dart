import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/permissions/app_permission.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

/// Hesap + aktif projedeki kurumsal rol atamasına göre yetkiler.
final userPermissionsProvider = Provider<Set<AppPermission>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return {};

  var membershipType = user.membershipType;
  var corporateRole = user.corporateRole;

  final membership = ref.watch(activeProjectMembershipProvider);
  if (membership?.corporateRole != null) {
    membershipType = MembershipType.corporate;
    corporateRole = membership!.corporateRole;
  }

  return AppPermissionMatrix.forMembership(
    membershipType: membershipType,
    corporateRole: corporateRole,
  );
});

final visibleBottomNavTabsProvider = Provider<List<BottomNavTab>>((ref) {
  final permissions = ref.watch(userPermissionsProvider);
  final tabs = AppPermissionMatrix.visibleTabs(permissions);
  if (tabs.isEmpty) return [BottomNavTab.dashboard];
  return tabs;
});

final canCreateOrderProvider = Provider<bool>((ref) {
  final permissions = ref.watch(userPermissionsProvider);
  final projectEdit = ref.watch(canEditActiveProjectProvider);
  return projectEdit && permissions.contains(AppPermission.createOrder);
});

final canCreateDeliveryProvider = Provider<bool>((ref) {
  final permissions = ref.watch(userPermissionsProvider);
  final projectEdit = ref.watch(canEditActiveProjectProvider);
  return projectEdit && permissions.contains(AppPermission.createDelivery);
});

final canEditFieldCountProvider = Provider<bool>((ref) {
  final permissions = ref.watch(userPermissionsProvider);
  final projectEdit = ref.watch(canEditActiveProjectProvider);
  return projectEdit && permissions.contains(AppPermission.editFieldCount);
});

final canEditSurveyProvider = Provider<bool>((ref) {
  final permissions = ref.watch(userPermissionsProvider);
  final projectEdit = ref.watch(canEditActiveProjectProvider);
  return projectEdit && permissions.contains(AppPermission.editSurvey);
});

final canRunAnalysisProvider = Provider<bool>((ref) {
  final permissions = ref.watch(userPermissionsProvider);
  final projectEdit = ref.watch(canEditActiveProjectProvider);
  return projectEdit && permissions.contains(AppPermission.runAnalysis);
});

bool userCanApproveOrderRole(
  Set<AppPermission> permissions,
  OrderApproverRole role,
) {
  return AppPermissionMatrix.canApproveOrderRole(permissions, role);
}

String membershipRoleLabel({
  required MembershipType membershipType,
  CorporateRole? corporateRole,
}) {
  if (membershipType == MembershipType.individual) {
    return MembershipType.individual.label;
  }
  return corporateRole?.label ?? MembershipType.corporate.label;
}
