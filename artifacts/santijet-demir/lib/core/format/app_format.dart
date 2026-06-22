/// Türkçe sayı/para formatı — binlik ayırıcı: nokta (19.857.250).
abstract final class AppFormat {
  static String integer(num value) {
    final n = value.round();
    final sign = n < 0 ? '-' : '';
    final digits = n.abs().toString();

    final buffer = StringBuffer(sign);
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String currency(num value, {String symbol = '₺'}) {
    return '$symbol${integer(value)}';
  }
}
