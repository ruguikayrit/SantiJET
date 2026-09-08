import 'package:intl/intl.dart';

/// TR para formatı: ₺1.234,56
abstract final class MoneyFormat {
  static final NumberFormat _tr = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static String format(num value) => _tr.format(value);

  /// Negatif bakiyede kırmızı vurgu için işaretli metin.
  static String formatSigned(num value) {
    if (value < 0) return '-${format(value.abs())}';
    return format(value);
  }

  /// Kullanıcı girdisinden double (virgül veya nokta).
  static double? tryParse(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .trim()
        .replaceAll('₺', '')
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
