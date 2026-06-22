import 'package:hive/hive.dart';
import 'package:santijet_demir/data/remote/supabase_service.dart';
import 'package:santijet_demir/data/repositories/auth_repository.dart';
import 'package:santijet_demir/domain/entities/user_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class SupabaseAuthRepository {
  SupabaseAuthRepository(this._box);

  final Box _box;
  static const _activeSessionKey = 'active_session';

  SupabaseClient get _client => SupabaseService.client;

  Future<void> restoreSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    await _ensureProfile(session.user);

    final profile = await _client
        .from('profiles')
        .select('current_session_id, email')
        .eq('id', session.user.id)
        .maybeSingle();

    var sessionId = profile?['current_session_id'] as String? ?? '';
    if (sessionId.isEmpty) {
      sessionId = _newSessionId();
      await _updateSessionId(session.user.id, sessionId);
    }
    final email = profile?['email'] as String? ?? session.user.email ?? '';

    await _saveActiveSession(
      userId: session.user.id,
      sessionId: sessionId,
      email: email,
    );
  }

  UserAccount? findById(String id) {
    final session = _client.auth.currentSession;
    if (session == null || session.user.id != id) return null;
    return _userFromSession(session);
  }

  Future<UserAccount?> fetchCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final profile = await _client
        .from('profiles')
        .select('display_name, current_session_id, email')
        .eq('id', session.user.id)
        .maybeSingle();

    if (profile == null) return _userFromSession(session);

    return UserAccount(
      id: session.user.id,
      email: profile['email'] as String? ?? session.user.email ?? '',
      displayName: profile['display_name'] as String? ?? '',
      passwordHash: '',
      currentSessionId: profile['current_session_id'] as String? ?? '',
    );
  }

  Future<UserAccount> register({
    required String email,
    required String displayName,
    required String password,
    required String sessionId,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'display_name': displayName.trim()},
      );

      final user = response.user;
      if (user == null) {
        throw AppAuthException('Kayıt tamamlanamadı');
      }

      await _waitForProfile(user.id);
      await _ensureProfile(user);
      await _updateSessionId(user.id, sessionId);
      await _saveActiveSession(
        userId: user.id,
        sessionId: sessionId,
        email: user.email ?? email,
      );

      return UserAccount(
        id: user.id,
        email: user.email ?? email.trim().toLowerCase(),
        displayName: displayName.trim(),
        passwordHash: '',
        currentSessionId: sessionId,
      );
    } on AppAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AppAuthException(_mapAuthError(e.message));
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('invalid path specified')) {
        throw AppAuthException(_mapAuthError('Invalid path specified in request URL'));
      }
      throw AppAuthException('Kayıt başarısız: $e');
    }
  }

  Future<UserAccount> login({
    required String email,
    required String password,
    required String sessionId,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw AppAuthException('Giriş başarısız');
      }

      await _ensureProfile(user);
      await _updateSessionId(user.id, sessionId);
      await _saveActiveSession(
        userId: user.id,
        sessionId: sessionId,
        email: user.email ?? email,
      );

      final profile = await _client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      return UserAccount(
        id: user.id,
        email: user.email ?? email.trim().toLowerCase(),
        displayName: profile?['display_name'] as String? ?? '',
        passwordHash: '',
        currentSessionId: sessionId,
      );
    } on AppAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AppAuthException(_mapAuthError(e.message));
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('invalid path specified')) {
        throw AppAuthException(_mapAuthError('Invalid path specified in request URL'));
      }
      throw AppAuthException('Giriş başarısız: $e');
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    await _box.delete(_activeSessionKey);
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: _passwordResetRedirectUrl,
      );
    } on AuthApiException catch (e) {
      throw AppAuthException(_mapAuthError(e.message));
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('invalid path specified')) {
        throw AppAuthException(_mapAuthError('Invalid path specified in request URL'));
      }
      throw AppAuthException('Şifre sıfırlama başarısız: $e');
    }
  }

  /// Web: mevcut uygulama adresi; Supabase Redirect URLs'e eklenmeli.
  static String get _passwordResetRedirectUrl {
    final uri = Uri.base;
    if (uri.hasScheme && uri.host.isNotEmpty) {
      return uri.replace(queryParameters: {}, fragment: '').toString();
    }
    return 'https://ruguikayrit.github.io/SantiJET/';
  }

  ActiveSession? getActiveSession() {
    final raw = _box.get(_activeSessionKey);
    if (raw is! Map) return null;
    return ActiveSession.fromJson(raw);
  }

  Future<bool> isSessionValid(ActiveSession session) async {
    final authSession = _client.auth.currentSession;
    if (authSession == null || authSession.user.id != session.userId) {
      return false;
    }

    final profile = await _client
        .from('profiles')
        .select('current_session_id')
        .eq('id', session.userId)
        .maybeSingle();

    if (profile == null) return false;
    return profile['current_session_id'] == session.sessionId;
  }

  Future<void> _updateSessionId(String userId, String sessionId) async {
    try {
      await _client
          .from('profiles')
          .update({'current_session_id': sessionId})
          .eq('id', userId);
    } on PostgrestException {
      // Oturum kaydı güncellenemese bile giriş tamamlansın.
    }
  }

  Future<void> _waitForProfile(String userId) async {
    for (var i = 0; i < 5; i++) {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (profile != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<void> _ensureProfile(User user) async {
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'email': user.email ?? '',
        'display_name': user.userMetadata?['display_name'] as String? ?? '',
      });
    } on PostgrestException {
      // Tetikleyici eşzamanlı oluşturmuş olabilir.
    }
  }

  String _newSessionId() {
    final value = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return 'sb$value';
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

  UserAccount _userFromSession(Session session) {
    return UserAccount(
      id: session.user.id,
      email: session.user.email ?? '',
      displayName: session.user.userMetadata?['display_name'] as String? ?? '',
      passwordHash: '',
      currentSessionId: '',
    );
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid path specified')) {
      return 'Supabase URL ayarı hatalı. GitHub Secrets\'taki SUPABASE_URL '
          'değeri https://PROJE_ID.supabase.co olmalı (/rest/v1 eklemeyin).';
    }
    if (lower.contains('invalid login credentials')) {
      return 'E-posta veya şifre hatalı';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('not confirmed')) {
      return 'E-posta adresinizi doğrulamanız gerekiyor';
    }
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'Bu e-posta zaten kayıtlı';
    }
    if (lower.contains('password')) {
      return 'Şifre en az 6 karakter olmalı';
    }
    return message;
  }
}
