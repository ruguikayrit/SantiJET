import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../domain/entities/user_account.dart';
import '../remote/supabase_service.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isInitialized = false,
    this.error,
  });

  final UserAccount? user;
  final bool isInitialized;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserAccount? user,
    bool? isInitialized,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isInitialized: isInitialized ?? this.isInitialized,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> restoreSession() async {
    try {
      if (!SupabaseConfig.isConfigured) {
        state = const AuthState(isInitialized: true);
        return;
      }
      await SupabaseService.waitUntilReady(timeout: const Duration(seconds: 8));
      if (!SupabaseService.isReady) {
        state = AuthState(
          isInitialized: true,
          error: SupabaseService.initError,
        );
        return;
      }

      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        state = const AuthState(isInitialized: true);
        return;
      }

      state = AuthState(
        user: _userFromSession(session),
        isInitialized: true,
      );
    } catch (e) {
      state = AuthState(isInitialized: true, error: e.toString());
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _ensureReady();
    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final session = res.session;
      if (session == null) {
        state = state.copyWith(error: 'Giriş başarısız');
        return;
      }
      state = AuthState(user: _userFromSession(session), isInitialized: true);
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _ensureReady();
    try {
      final res = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      final session = res.session;
      if (session == null) {
        state = state.copyWith(
          error:
              'Kayıt alındı. E-posta onayı açıksa gelen kutunuzu kontrol edin.',
        );
        return;
      }
      state = AuthState(user: _userFromSession(session), isInitialized: true);
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (SupabaseService.isReady) {
      await SupabaseService.client.auth.signOut();
    }
    state = const AuthState(isInitialized: true);
  }

  Future<void> _ensureReady() async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Bulut hesabı için SUPABASE_URL / SUPABASE_ANON_KEY gerekir.',
      );
    }
    final ok = await SupabaseService.waitUntilReady();
    if (!ok) {
      throw StateError(
        SupabaseService.initError ?? 'Supabase bağlantısı kurulamadı',
      );
    }
  }

  UserAccount _userFromSession(Session session) {
    final user = session.user;
    final meta = user.userMetadata ?? {};
    final displayName = (meta['display_name'] as String?)?.trim();
    return UserAccount(
      id: user.id,
      email: user.email ?? '',
      displayName: (displayName == null || displayName.isEmpty)
          ? (user.email ?? 'Kullanıcı')
          : displayName,
    );
  }
}
