import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/domain/permissions/app_permission.dart';

void main() {
  group('AppPermissionMatrix', () {
    test('bireysel üyelik tüm yetkilere sahip', () {
      final perms = AppPermissionMatrix.forMembership(
        membershipType: MembershipType.individual,
        corporateRole: null,
      );
      expect(perms, containsAll(AppPermission.values));
    });

    test('satın alma yalnızca sipariş onayı ve gelen demir görür', () {
      final perms = AppPermissionMatrix.forMembership(
        membershipType: MembershipType.corporate,
        corporateRole: CorporateRole.purchasing,
      );

      expect(perms, contains(AppPermission.viewOrders));
      expect(perms, contains(AppPermission.approveOrderPurchasing));
      expect(perms, contains(AppPermission.viewIncomingRebar));
      expect(perms, isNot(contains(AppPermission.createOrder)));
      expect(perms, isNot(contains(AppPermission.createDelivery)));
      expect(perms, isNot(contains(AppPermission.viewFieldCount)));
      expect(perms, isNot(contains(AppPermission.viewAnalysis)));

      expect(
        AppPermissionMatrix.canApproveOrderRole(
          perms,
          OrderApproverRole.purchasing,
        ),
        isTrue,
      );
      expect(
        AppPermissionMatrix.canApproveOrderRole(
          perms,
          OrderApproverRole.employer,
        ),
        isFalse,
      );

      final tabs = AppPermissionMatrix.visibleTabs(perms);
      expect(tabs, contains(BottomNavTab.orders));
      expect(tabs, contains(BottomNavTab.incomingRebar));
      expect(tabs, isNot(contains(BottomNavTab.fieldCount)));
    });

    test('sipariş oluşturma PM / işveren / şantiye şefi; satın alma oluşturamaz',
        () {
      expect(
        AppPermissionMatrix.forMembership(
          membershipType: MembershipType.corporate,
          corporateRole: CorporateRole.purchasing,
        ),
        isNot(contains(AppPermission.createOrder)),
      );
      for (final role in [
        CorporateRole.projectManager,
        CorporateRole.employer,
        CorporateRole.siteManager,
      ]) {
        expect(
          AppPermissionMatrix.forMembership(
            membershipType: MembershipType.corporate,
            corporateRole: role,
          ),
          contains(AppPermission.createOrder),
        );
      }
    });

    test('muhasebe gelen demir ve sipariş görüntüler, onay veremez', () {
      final perms = AppPermissionMatrix.forMembership(
        membershipType: MembershipType.corporate,
        corporateRole: CorporateRole.accounting,
      );

      expect(perms, contains(AppPermission.viewIncomingRebar));
      expect(perms, contains(AppPermission.viewOrders));
      expect(perms, isNot(contains(AppPermission.approveOrderPurchasing)));
      expect(perms, isNot(contains(AppPermission.createDelivery)));
    });
  });
}
