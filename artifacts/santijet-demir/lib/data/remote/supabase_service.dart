import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:santijet_demir/core/config/supabase_config.dart';

abstract final class SupabaseService {
  static bool _initialized = false;
  static Future<bool>? _initFuture;
  static String? _initError;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isReady => _initialized && isConfigured;

  static String? get initError => _initError;

  static const invalidAnonKeyMessage =
      'Supabase API anahtarı geçersiz. GitHub Secrets\'taki SUPABASE_ANON_KEY '
      'değerini Dashboard → Project Settings → API bölümündeki '
      'anon public key ile güncelleyin, ardından deploy edin.';

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase is not initialized');
    }
    return Supabase.instance.client;
  }

  static Future<bool> initialize() async {
    if (!isConfigured || _initialized) return _initialized;
    final existing = _initFuture;
    if (existing != null) return existing;

    _initFuture = _initializeOnce();
    return _initFuture!;
  }

  static Future<bool> _initializeOnce() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.normalizedUrl,
        publishableKey: SupabaseConfig.normalizedAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(const Duration(seconds: 5));
      _initialized = true;
      _initError = null;
      return true;
    } catch (e, stack) {
      _initialized = false;
      _initError = e.toString();
      if (kDebugMode) {
        debugPrint('Supabase initialize failed: $e\n$stack');
      }
      return false;
    } finally {
      _initFuture = null;
    }
  }

  /// Web'de arka plan init bitene kadar giriş bekler.
  static Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!isConfigured) return false;
    if (_initialized) return true;

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_initialized) return true;
      await initialize();
      if (_initialized) return true;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return _initialized;
  }

  /// Auth/REST isteği öncesi bulut erişimini doğrular. Başarılıysa `null` döner.
  static Future<String?> verifyReachable({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!isConfigured) return null;

    final healthUrl = Uri.parse('${SupabaseConfig.normalizedUrl}/auth/v1/health');
    final headers = {
      'apikey': SupabaseConfig.normalizedAnonKey,
      'Authorization': 'Bearer ${SupabaseConfig.normalizedAnonKey}',
    };
    try {
      final response =
          await http.get(healthUrl, headers: headers).timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        return invalidAnonKeyMessage;
      }
      if (response.statusCode >= 500) {
        return 'Supabase geçici olarak yanıt vermiyor (HTTP ${response.statusCode}). '
            'Birkaç dakika sonra tekrar deneyin.';
      }
      return null;
    } on http.ClientException catch (e) {
      return _reachabilityErrorMessage(e);
    } catch (e) {
      return _reachabilityErrorMessage(e);
    }
  }

  static const reachabilityUserMessage =
      'Supabase sunucusuna ulaşılamıyor. GitHub Secrets\'taki SUPABASE_URL '
      'değerini Supabase Dashboard → Project Settings → API adresiyle '
      'karşılaştırın (https://PROJE_ID.supabase.co). '
      'Proje silinmiş, duraklatılmış veya URL yanlış olabilir.';

  static String _reachabilityErrorMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('failed host lookup') ||
        msg.contains('load failed') ||
        msg.contains('name not resolved') ||
        msg.contains('dns ad') ||
        msg.contains('socketexception')) {
      return reachabilityUserMessage;
    }
    if (msg.contains('timed out') || msg.contains('timeout')) {
      return 'Supabase yanıt vermiyor (zaman aşımı). İnternet bağlantınızı '
          'kontrol edin; proje duraklatılmış olabilir.';
    }
    return 'Bulut bağlantısı kurulamadı. Sayfayı yenileyip tekrar deneyin.';
  }
}
