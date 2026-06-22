import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/data/repositories/auth_repository.dart';
import 'package:santijet_demir/domain/entities/user_account.dart';

final accountsBoxProvider = Provider<Box>((ref) {
  return Hive.box('accounts');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(accountsBoxProvider));
});

class AuthState {
  const AuthState({
    this.user,
    this.sessionId,
    this.isSessionValid = false,
    this.error,
  });

  final UserAccount? user;
  final String? sessionId;
  final bool isSessionValid;
  final String? error;

  bool get isAuthenticated => user != null && isSessionValid;

  AuthState copyWith({
    UserAccount? user,
    String? sessionId,
    bool? isSessionValid,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      sessionId: sessionId ?? this.sessionId,
      isSessionValid: isSessionValid ?? this.isSessionValid,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState()) {
    _restoreSession();
  }

  final AuthRepository _repository;

  void _restoreSession() {
    final session = _repository.getActiveSession();
    if (session == null) return;

    final valid = _repository.isSessionValid(session);
    final user = _repository.findById(session.userId);
    state = AuthState(
      user: user,
      sessionId: session.sessionId,
      isSessionValid: valid,
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
      final user = await _repository.register(
        id: _newUserId(),
        email: email,
        displayName: displayName,
        password: password,
        sessionId: sessionId,
      );
      state = AuthState(
        user: user,
        sessionId: sessionId,
        isSessionValid: true,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final sessionId = _newSessionId();
      final user = await _repository.login(
        email: email,
        password: password,
        sessionId: sessionId,
      );
      state = AuthState(
        user: user,
        sessionId: sessionId,
        isSessionValid: true,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  String _newSessionId() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  String _newUserId() {
    return 'user-${DateTime.now().microsecondsSinceEpoch}';
  }
}
