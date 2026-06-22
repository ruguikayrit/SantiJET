import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/data/remote/supabase_service.dart';
import 'package:santijet_demir/data/repositories/auth_repository.dart';
import 'package:santijet_demir/data/repositories/supabase_auth_repository.dart';
import 'package:santijet_demir/domain/entities/user_account.dart';

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
    if (_usesSupabase) {
      await _supabaseAuth.restoreSession();
      final session = _supabaseAuth.getActiveSession();
      if (session == null) {
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
  }

  Future<bool> register({
    required String email,
    required String displayName,
    required String password,
  }) async {
    if (password.trim().length < 6) {
      state = state.copyWith(error: 'Şifre en az 6 karakter olmalı');
      return false;
    }

    try {
      final sessionId = _newSessionId();
      final UserAccount user;

      if (_usesSupabase) {
        user = await _supabaseAuth.register(
          email: email,
          displayName: displayName,
          password: password,
          sessionId: sessionId,
        );
      } else {
        user = await _localAuth.register(
          id: _newUserId(),
          email: email,
          displayName: displayName,
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
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
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

  String _newSessionId() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  String _newUserId() {
    return 'user-${DateTime.now().microsecondsSinceEpoch}';
  }
}
