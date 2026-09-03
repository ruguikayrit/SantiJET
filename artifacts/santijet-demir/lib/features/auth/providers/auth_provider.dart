import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/core/config/supabase_config.dart';
import 'package:santijet_demir/data/remote/supabase_service.dart';
import 'package:santijet_demir/data/repositories/auth_repository.dart';
import 'package:santijet_demir/data/repositories/supabase_auth_repository.dart';
import 'package:santijet_demir/domain/entities/user_account.dart';
import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/domain/enums/subscription_plan.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

final accountsBoxProvider = Provider<Box>((ref) {
  return Hive.box('accounts');
});

final localAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(accountsBoxProvider));
});

final supabaseAuthRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(accountsBoxProvider));
});

class AuthState {
  const AuthState({
    this.user,
    this.sessionId,
    this.isSessionValid = false,
    this.isInitialized = false,
    this.usesSupabase = false,
    this.error,
  });

  final UserAccount? user;
  final String? sessionId;
  final bool isSessionValid;
  final bool isInitialized;
  final bool usesSupabase;
  final String? error;

  bool get isAuthenticated => user != null && isSessionValid;

  AuthState copyWith({
    UserAccount? user,
    String? sessionId,
    bool? isSessionValid,
    bool? isInitialized,
    bool? usesSupabase,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      sessionId: sessionId ?? this.sessionId,
      isSessionValid: isSessionValid ?? this.isSessionValid,
      isInitialized: isInitialized ?? this.isInitialized,
      usesSupabase: usesSupabase ?? this.usesSupabase,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;

  bool get _usesSupabase => SupabaseService.isReady;

  AuthRepository get _localAuth => _ref.read(localAuthRepositoryProvider);
  SupabaseAuthRepository get _supabaseAuth =>
      _ref.read(supabaseAuthRepositoryProvider);

  Future<void> restoreSession() async {
    try {
      if (SupabaseConfig.isConfigured) {
        await SupabaseService.waitUntilReady(
          timeout: const Duration(seconds: 8),
        );
      }

      if (_usesSupabase) {
        await _supabaseAuth.restoreSession();
        final session = _supabaseAuth.getActiveSession();
        if (session == null) {
          final guest = _tryRestoreLocalGuest();
          if (guest != null) {
            state = guest;
            return;
          }
          state = AuthState(isInitialized: true, usesSupabase: true);
          return;
        }

        final valid = await _supabaseAuth.isSessionValid(session);
        final user = await _supabaseAuth.fetchCurrentUser();
        state = AuthState(
          user: user,
          sessionId: session.sessionId,
          isSessionValid: valid,
          isInitialized: true,
          usesSupabase: true,
        );
        return;
      }

      final session = _localAuth.getActiveSession();
      if (session == null) {
        state = const AuthState(isInitialized: true);
        return;
      }

      final valid = _localAuth.isSessionValid(session);
      final user = _localAuth.findById(session.userId);
      state = AuthState(
        user: user,
        sessionId: session.sessionId,
        isSessionValid: valid,
        isInitialized: true,
      );
    } catch (_) {
      state = AuthState(
        isInitialized: true,
        usesSupabase: _usesSupabase,
      );
    }
  }

  void markBootstrapComplete() {
    if (!state.isInitialized) {
      state = state.copyWith(isInitialized: true);
    }
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
  }

  Future<String?> _ensureCloudReachable() async {
    if (!SupabaseConfig.isConfigured) return null;
    final ready = await SupabaseService.waitUntilReady();
    if (!ready) {
      return 'Bulut bağlantısı kurulamadı. Sayfayı yenileyip tekrar deneyin.';
    }
    if (!_usesSupabase) return null;
    return SupabaseService.verifyReachable();
  }

  Future<bool> register({
    required String email,
    required String displayName,
    required String password,
    MembershipType membershipType = MembershipType.individual,
    CorporateRole? corporateRole,
  }) async {
    if (!_isValidEmail(email)) {
      state = state.copyWith(error: 'Geçerli bir e-posta adresi girin');
      return false;
    }
    if (password.trim().length < 6) {
      state = state.copyWith(error: 'Şifre en az 6 karakter olmalı');
      return false;
    }
    if (membershipType == MembershipType.corporate && corporateRole == null) {
      state = state.copyWith(error: 'Kurumsal üyelik için rol seçin');
      return false;
    }

    try {
      final reachError = await _ensureCloudReachable();
      if (reachError != null) {
        state = state.copyWith(error: reachError, isInitialized: true);
        return false;
      }

      final sessionId = _newSessionId();
      final UserAccount user;

      if (_usesSupabase) {
        user = await _supabaseAuth.register(
          email: email,
          displayName: displayName,
          password: password,
          sessionId: sessionId,
          membershipType: membershipType,
          corporateRole: corporateRole,
        );
      } else {
        user = await _localAuth.register(
          id: _newUserId(),
          email: email,
          displayName: displayName,
          password: password,
          sessionId: sessionId,
          membershipType: membershipType,
          corporateRole: corporateRole,
        );
      }

      // Profil görevinde kurumsal rol etiketini yansıt.
      final roleLabel = membershipType == MembershipType.corporate
          ? (corporateRole?.label ?? '')
          : 'Bireysel';
      await _ref.read(appSettingsProvider.notifier).updateProfile(
            profileName: displayName.trim(),
            profileProfession: '',
            profileRole: roleLabel,
          );

      state = AuthState(
        user: user,
        sessionId: sessionId,
        isSessionValid: true,
        isInitialized: true,
        usesSupabase: _usesSupabase,
      );
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(error: e.message, isInitialized: true);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Kayıt başarısız: $e',
        isInitialized: true,
      );
      return false;
    }
  }

  /// Yerel misafir oturumu — buluta yazılmaz; demo ile uygulamayı test eder.
  Future<bool> loginAsGuest() async {
    try {
      final sessionId = _newSessionId();
      final user = await _localAuth.loginAsGuest(sessionId: sessionId);

      await _ref.read(appSettingsProvider.notifier).updateProfile(
            profileName: 'Misafir',
            profileProfession: '',
            profileRole: 'Misafir · Demo',
          );

      state = AuthState(
        user: user,
        sessionId: sessionId,
        isSessionValid: true,
        isInitialized: true,
        usesSupabase: _usesSupabase,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Misafir girişi başarısız: $e',
        isInitialized: true,
      );
      return false;
    }
  }

  AuthState? _tryRestoreLocalGuest() {
    final session = _localAuth.getActiveSession();
    if (session == null) return null;
    final user = _localAuth.findById(session.userId);
    if (user == null || !user.isGuest) return null;
    if (!_localAuth.isSessionValid(session)) return null;
    return AuthState(
      user: user,
      sessionId: session.sessionId,
      isSessionValid: true,
      isInitialized: true,
      usesSupabase: _usesSupabase,
    );
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (!_isValidEmail(email)) {
      state = state.copyWith(error: 'Geçerli bir e-posta adresi girin');
      return false;
    }

    try {
      final reachError = await _ensureCloudReachable();
      if (reachError != null) {
        state = state.copyWith(error: reachError, isInitialized: true);
        return false;
      }

      final sessionId = _newSessionId();
      final UserAccount user;

      if (_usesSupabase) {
        user = await _supabaseAuth.login(
          email: email,
          password: password,
          sessionId: sessionId,
        );
      } else {
        user = await _localAuth.login(
          email: email,
          password: password,
          sessionId: sessionId,
        );
      }

      state = AuthState(
        user: user,
        sessionId: sessionId,
        isSessionValid: true,
        isInitialized: true,
        usesSupabase: _usesSupabase,
      );
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(error: e.message, isInitialized: true);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Giriş başarısız: $e',
        isInitialized: true,
      );
      return false;
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(error: 'E-posta adresi girin');
      return false;
    }

    if (!_usesSupabase) {
      state = state.copyWith(
        error: 'Şifre sıfırlama yalnızca bulut hesaplarında kullanılabilir',
      );
      return false;
    }

    try {
      await _supabaseAuth.requestPasswordReset(email: normalized);
      state = state.copyWith(clearError: true);
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    if (_usesSupabase) {
      await _supabaseAuth.logout();
    } else {
      await _localAuth.logout();
    }
    state = AuthState(isInitialized: true, usesSupabase: _usesSupabase);
  }

  Future<bool> updateProfile({
    required String displayName,
    required String profession,
    required String role,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(error: 'Ad soyad boş olamaz');
      return false;
    }

    try {
      await _ref.read(appSettingsProvider.notifier).updateProfile(
            profileName: trimmedName,
            profileProfession: profession.trim(),
            profileRole: role.trim(),
          );

      final user = state.user;
      if (user != null) {
        if (_usesSupabase) {
          await _supabaseAuth.updateDisplayName(
            userId: user.id,
            displayName: trimmedName,
          );
        } else {
          await _localAuth.updateDisplayName(
            userId: user.id,
            displayName: trimmedName,
          );
        }

        state = state.copyWith(
          user: user.copyWith(displayName: trimmedName),
          clearError: true,
        );

        await _ref.read(projectRepositoryProvider).updateUserDisplayName(
              userId: user.id,
              displayName: trimmedName,
            );
        _ref.invalidate(userProjectsProvider);
      }

      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Profil güncellenemedi: $e');
      return false;
    }
  }

  Future<bool> updateMembership({
    required MembershipType membershipType,
    CorporateRole? corporateRole,
  }) async {
    final user = state.user;
    if (user == null) {
      state = state.copyWith(error: 'Oturum bulunamadı');
      return false;
    }
    if (membershipType == MembershipType.corporate && corporateRole == null) {
      state = state.copyWith(error: 'Kurumsal üyelik için rol seçin');
      return false;
    }

    try {
      final UserAccount updated;
      if (_usesSupabase) {
        updated = await _supabaseAuth.updateMembership(
          membershipType: membershipType,
          corporateRole: corporateRole,
        );
        // Yerel önbelleğe de yaz (Hive hesapları).
        try {
          await _localAuth.updateMembership(
            userId: user.id,
            membershipType: membershipType,
            corporateRole: corporateRole,
          );
        } catch (_) {}
      } else {
        updated = await _localAuth.updateMembership(
          userId: user.id,
          membershipType: membershipType,
          corporateRole: corporateRole,
        );
      }

      final roleLabel = membershipType == MembershipType.corporate
          ? (corporateRole?.label ?? '')
          : 'Bireysel';
      await _ref.read(appSettingsProvider.notifier).updateProfile(
            profileName: updated.displayName.isEmpty
                ? user.displayName
                : updated.displayName,
            profileProfession:
                _ref.read(appSettingsProvider).profileProfession,
            profileRole: roleLabel,
          );

      state = state.copyWith(
        user: user.copyWith(
          membershipType: membershipType,
          corporateRole: corporateRole,
          clearCorporateRole: membershipType == MembershipType.individual,
        ),
        clearError: true,
      );
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Üyelik güncellenemedi: $e');
      return false;
    }
  }

  /// Mock satın alma — gerçek ödeme sonra bağlanacak.
  Future<bool> setSubscriptionPlan(SubscriptionPlan plan) async {
    final user = state.user;
    if (user == null) {
      state = state.copyWith(error: 'Oturum bulunamadı');
      return false;
    }
    if (user.isGuest) {
      state = state.copyWith(
        error:
            'Misafir hesapla premium paket alınamaz. Üyelik açarak devam edin.',
      );
      return false;
    }

    try {
      final UserAccount updated;
      if (_usesSupabase) {
        updated = await _supabaseAuth.updateSubscriptionPlan(
          subscriptionPlan: plan,
        );
        try {
          await _localAuth.updateSubscriptionPlan(
            userId: user.id,
            subscriptionPlan: plan,
          );
        } catch (_) {}
      } else {
        updated = await _localAuth.updateSubscriptionPlan(
          userId: user.id,
          subscriptionPlan: plan,
        );
      }

      state = state.copyWith(
        user: user.copyWith(subscriptionPlan: updated.subscriptionPlan),
        clearError: true,
      );
      return true;
    } on AppAuthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Abonelik güncellenemedi: $e');
      return false;
    }
  }

  String _newSessionId() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  String _newUserId() {
    return 'user-${DateTime.now().microsecondsSinceEpoch}';
  }
}
