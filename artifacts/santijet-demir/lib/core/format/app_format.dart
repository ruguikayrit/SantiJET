import 'package:intl/intl.dart';

/// Türkçe sayı/para formatı — binlik ayırıcı: nokta (19.289.900).
abstract final class AppFormat {
  static final _integerTr = NumberFormat('#,##0', 'tr_TR');

  static String integer(num value) => _integerTr.format(value.round());

  static String currency(num value, {String symbol = '₺'}) {
    return '$symbol${integer(value)}';
  }
}
