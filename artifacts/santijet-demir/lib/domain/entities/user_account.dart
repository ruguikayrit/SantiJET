import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';

class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.currentSessionId,
    this.membershipType = MembershipType.individual,
    this.corporateRole,
  });

  final String id;
  final String email;
  final String displayName;
  final String passwordHash;
  final String currentSessionId;
  final MembershipType membershipType;
  final CorporateRole? corporateRole;

  bool get isCorporate => membershipType == MembershipType.corporate;

  String get membershipSummary {
    if (!isCorporate) return MembershipType.individual.label;
    final role = corporateRole?.label;
    if (role == null) return MembershipType.corporate.label;
    return '${MembershipType.corporate.label} · $role';
  }

  UserAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? passwordHash,
    String? currentSessionId,
    MembershipType? membershipType,
    CorporateRole? corporateRole,
    bool clearCorporateRole = false,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      membershipType: membershipType ?? this.membershipType,
      corporateRole:
          clearCorporateRole ? null : (corporateRole ?? this.corporateRole),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'passwordHash': passwordHash,
        'currentSessionId': currentSessionId,
        'membershipType': membershipType.storageValue,
        'corporateRole': corporateRole?.storageValue,
      };

  factory UserAccount.fromJson(Map<dynamic, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      currentSessionId: json['currentSessionId'] as String? ?? '',
      membershipType: MembershipType.fromStorage(
        json['membershipType'] as String?,
      ),
      corporateRole: CorporateRole.fromStorage(
        json['corporateRole'] as String?,
      ),
    );
  }
}
