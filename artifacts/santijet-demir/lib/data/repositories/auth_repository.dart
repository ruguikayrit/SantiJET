import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/domain/enums/subscription_plan.dart';
import 'package:santijet_demir/domain/entities/user_account.dart';
import 'package:santijet_demir/core/security/pin_hasher.dart';
import 'package:hive/hive.dart';

const _accountsKey = 'accounts';
const _activeSessionKey = 'active_session';

class AuthRepository {
  AuthRepository(this._box);

  final Box _box;

  List<UserAccount> getAllAccounts() {
    final raw = _box.get(_accountsKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => UserAccount.fromJson(e))
        .toList();
  }

  UserAccount? findByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final account in getAllAccounts()) {
      if (account.email.toLowerCase() == normalized) return account;
    }
    return null;
  }

  UserAccount? findById(String id) {
    for (final account in getAllAccounts()) {
      if (account.id == id) return account;
    }
    return null;
  }

  Future<UserAccount> register({
    required String id,
    required String email,
    required String displayName,
    required String password,
    required String sessionId,
    MembershipType membershipType = MembershipType.individual,
    CorporateRole? corporateRole,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (findByEmail(normalizedEmail) != null) {
      throw AppAuthException('Bu e-posta zaten kayıtlı');
    }

    final account = UserAccount(
      id: id,
      email: normalizedEmail,
      displayName: displayName.trim(),
      passwordHash: PinHasher.hash(password),
      currentSessionId: sessionId,
      membershipType: membershipType,
      corporateRole: membershipType == MembershipType.corporate
          ? corporateRole
          : null,
    );

    final accounts = getAllAccounts()..add(account);
    await _saveAccounts(accounts);
    await _saveActiveSession(
      userId: account.id,
      sessionId: sessionId,
      email: account.email,
    );
    return account;
  }

  Future<UserAccount> login({
    required String email,
    required String password,
    required String sessionId,
  }) async {
    final account = findByEmail(email);
    if (account == null || !PinHasher.verify(password, account.passwordHash)) {
      throw AppAuthException('E-posta veya şifre hatalı');
    }

    final updated = account.copyWith(currentSessionId: sessionId);
    await _upsertAccount(updated);
    await _saveActiveSession(
      userId: updated.id,
      sessionId: sessionId,
      email: updated.email,
    );
    return updated;
  }

  Future<UserAccount> loginAsGuest({required String sessionId}) async {
    final existing = findById(UserAccount.guestId);
    final account = UserAccount(
      id: UserAccount.guestId,
      email: UserAccount.guestEmail,
      displayName: 'Misafir',
      passwordHash: '',
      currentSessionId: sessionId,
      membershipType: MembershipType.individual,
      // Demo sürümde tüm sekmeleri (Analiz dahil) test edebilsin.
      subscriptionPlan: SubscriptionPlan.demirTakipAnaliz,
      isGuest: true,
    );

    if (existing == null) {
      final accounts = getAllAccounts()..add(account);
      await _saveAccounts(accounts);
    } else {
      await _upsertAccount(account);
    }

    await _saveActiveSession(
      userId: account.id,
      sessionId: sessionId,
      email: account.email,
    );
    return account;
  }

  Future<void> logout() async {
    await _box.delete(_activeSessionKey);
  }

  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    final account = findById(userId);
    if (account == null) {
      throw AppAuthException('Kullanıcı bulunamadı');
    }
    await _upsertAccount(account.copyWith(displayName: displayName.trim()));
  }

  Future<UserAccount> updateMembership({
    required String userId,
    required MembershipType membershipType,
    CorporateRole? corporateRole,
  }) async {
    final account = findById(userId);
    if (account == null) {
      throw AppAuthException('Kullanıcı bulunamadı');
    }
    if (membershipType == MembershipType.corporate && corporateRole == null) {
      throw AppAuthException('Kurumsal üyelik için rol seçin');
    }
    final updated = account.copyWith(
      membershipType: membershipType,
      corporateRole: membershipType == MembershipType.corporate
          ? corporateRole
          : null,
      clearCorporateRole: membershipType == MembershipType.individual,
    );
    await _upsertAccount(updated);
    return updated;
  }

  Future<UserAccount> updateSubscriptionPlan({
    required String userId,
    required SubscriptionPlan subscriptionPlan,
  }) async {
    final account = findById(userId);
    if (account == null) {
      throw AppAuthException('Kullanıcı bulunamadı');
    }
    final updated = account.copyWith(subscriptionPlan: subscriptionPlan);
    await _upsertAccount(updated);
    return updated;
  }

  ActiveSession? getActiveSession() {
    final raw = _box.get(_activeSessionKey);
    if (raw is! Map) return null;
    return ActiveSession.fromJson(raw);
  }

  bool isSessionValid(ActiveSession session) {
    final account = findById(session.userId);
    if (account == null) return false;
    return account.currentSessionId == session.sessionId;
  }

  Future<void> _saveAccounts(List<UserAccount> accounts) async {
    await _box.put(_accountsKey, accounts.map((e) => e.toJson()).toList());
  }

  Future<void> _upsertAccount(UserAccount account) async {
    final accounts = getAllAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    await _saveAccounts(accounts);
  }

  Future<void> _saveActiveSession({
    required String userId,
    required String sessionId,
    required String email,
  }) async {
    await _box.put(
      _activeSessionKey,
      ActiveSession(
        userId: userId,
        sessionId: sessionId,
        email: email,
      ).toJson(),
    );
  }
}

class ActiveSession {
  const ActiveSession({
    required this.userId,
    required this.sessionId,
    required this.email,
  });

  final String userId;
  final String sessionId;
  final String email;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'sessionId': sessionId,
        'email': email,
      };

  factory ActiveSession.fromJson(Map<dynamic, dynamic> json) {
    return ActiveSession(
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      email: json['email'] as String? ?? '',
    );
  }
}

class AppAuthException implements Exception {
  AppAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
