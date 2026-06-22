abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Proje URL'si — yalnızca `https://PROJE_ID.supabase.co` olmalı.
  /// Dashboard'dan kopyalanan `/rest/v1` veya `/auth/v1` sonekleri otomatik temizlenir.
  static String get normalizedUrl => _normalizeProjectUrl(url);

  static String get normalizedAnonKey => anonKey.trim();

  static bool get isConfigured =>
      normalizedUrl.isNotEmpty && normalizedAnonKey.isNotEmpty;

  static String _normalizeProjectUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';

    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }

    // Yanlışlıkla REST/Auth endpoint URL'si yapıştırılmış olabilir.
    const suffixes = [
      '/rest/v1',
      '/auth/v1',
      '/storage/v1',
      '/functions/v1',
      '/realtime/v1',
    ];
    var changed = true;
    while (changed) {
      changed = false;
      for (final suffix in suffixes) {
        if (value.toLowerCase().endsWith(suffix)) {
          value = value.substring(0, value.length - suffix.length);
          while (value.endsWith('/')) {
            value = value.substring(0, value.length - 1);
          }
          changed = true;
        }
      }
    }

    return value;
  }
}
