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

  /// Tonaj — her zaman virgülden sonra 2 hane (1.234,50).
  static String tonnage(num value) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final fraction = parts.length > 1 ? parts[1] : '00';
    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write('.');
      buffer.write(whole[i]);
    }
    buffer
      ..write(',')
      ..write(fraction);
    return buffer.toString();
  }
}
