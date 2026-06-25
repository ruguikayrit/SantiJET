abstract final class DwgConverterConfig {
  static const url = String.fromEnvironment('DWG_CONVERTER_URL');

  static bool get isConfigured => url.trim().isNotEmpty;
}
