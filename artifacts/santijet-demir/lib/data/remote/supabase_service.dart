import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:santijet_demir/core/config/supabase_config.dart';

abstract final class SupabaseService {
  static bool _initialized = false;
  static String? _initError;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isReady => _initialized && isConfigured;

  static String? get initError => _initError;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase is not initialized');
    }
    return Supabase.instance.client;
  }

  static Future<bool> initialize() async {
    if (!isConfigured || _initialized) return _initialized;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url.trim(),
        publishableKey: SupabaseConfig.anonKey.trim(),
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
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
    }
  }
}
