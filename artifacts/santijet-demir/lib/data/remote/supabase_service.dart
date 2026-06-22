import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:santijet_demir/core/config/supabase_config.dart';

abstract final class SupabaseService {
  static bool _initialized = false;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isReady => _initialized && isConfigured;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!isConfigured || _initialized) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }
}
