/// Türkçe sayı/para biçimi.
///
/// Binlik ayırıcı: nokta, ondalık ayırıcı: virgül (ör. 1.061,58 ₺).
/// ŞantiJET Demir `AppFormat` ile uyumlu; BFA maliyet alanları için ondalık
/// (kuruş) desteği eklenmiştir.
abstract final class AppFormat {
  static String integer(num value) {
    final n = value.round();
    final sign = n < 0 ? '-' : '';
    final digits = n.abs().toString();
    return '$sign${_groupThousands(digits)}';
  }

  /// TR ondalık biçim: 1.061,58
  static String decimal(num value, {int fractionDigits = 2}) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(fractionDigits);
    final parts = fixed.split('.');
    final intPart = _groupThousands(parts[0]);
    final sign = negative ? '-' : '';
    if (parts.length < 2) return '$sign$intPart';
    return '$sign$intPart,${parts[1]}';
  }

  /// Para birimi: 1.061,58 ₺
  static String currency(num value,
      {String symbol = '₺', int fractionDigits = 2}) {
    return '${decimal(value, fractionDigits: fractionDigits)} $symbol';
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
