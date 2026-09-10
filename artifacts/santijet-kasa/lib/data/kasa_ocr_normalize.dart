import '../domain/kasa_lookups.dart';
import '../domain/money_format.dart';

/// OCR hücre metnini kasa alanlarına normalize eder.
abstract final class KasaOcrNormalize {
  static final moneyPattern = RegExp(
    r'₺?\s*(-?\d{1,3}(?:\.\d{3})*(?:,\d{2})?|-?\d+,\d{2})',
    caseSensitive: false,
  );

  static String fold(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static double? parseMoney(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return MoneyFormat.tryParse(raw);
  }

  /// Metindeki tüm tutarları bul (soldan sağa).
  static List<double> allAmounts(String raw) {
    final out = <double>[];
    for (final m in moneyPattern.allMatches(raw)) {
      final v = MoneyFormat.tryParse(m.group(0));
      if (v != null && v > 0) out.add(v);
    }
    return out;
  }

  static String matchOdeme(String raw) {
    final t = fold(raw);
    if (t.contains('havale')) return OdemeSekli.havale;
    if (t.contains('nakit')) return OdemeSekli.nakit;
    if (t.contains('sirket') && t.contains('kart')) {
      return OdemeSekli.sirketKart;
    }
    if (t.contains('sahsi') && t.contains('kart')) {
      return OdemeSekli.sahsiKart;
    }
    if (t.contains('kart')) return OdemeSekli.sahsiKart;
    if (t.contains('diger')) return OdemeSekli.diger;
    return raw.trim();
  }

  static String matchBelge(String raw) {
    final t = fold(raw);
    if (t.contains('fatura')) return BelgeTuru.fatura;
    if (t.contains('fis')) return BelgeTuru.fis;
    if (t.contains('yok')) return BelgeTuru.yok;
    return raw.trim();
  }

  static bool isIncomeHint(String text) {
    final t = fold(text);
    return t.contains('gonder') ||
        t.contains('avans') ||
        t.contains('hesabima') ||
        t.contains('hesabıma') ||
        t.contains('yatir') ||
        t.contains('yatır');
  }

  static bool isHeaderLine(String lower) {
    final hits = [
      'tarih',
      'tedarik',
      'aciklama',
      'açıklama',
      'gelir',
      'gider',
      'odeme',
      'ödeme',
      'belge',
      'santiye',
      'şantiye',
    ].where(lower.contains).length;
    return hits >= 4;
  }

  /// Gelir / gider — şablondaki tek tutar veya iki sütun.
  static ({double? gelir, double? gider}) splitAmounts({
    required List<double> amounts,
    required String context,
    required String odeme,
  }) {
    if (amounts.isEmpty) return (gelir: null, gider: null);
    final income = isIncomeHint(context) ||
        (odeme == OdemeSekli.havale && isIncomeHint(context));

    if (amounts.length >= 2) {
      double? gIn = amounts[amounts.length - 2];
      double? gOut = amounts.last;
      if ((gIn - gOut).abs() < 0.01) {
        gIn = null;
      } else if (!income) {
        gIn = null;
      } else if (gOut > gIn) {
        // OCR kayması: gelir sütunu boş, gider dolu
        gIn = gOut;
        gOut = null;
      }
      if (gIn != null && gOut != null) gOut = null;
      return (gelir: gIn, gider: gOut);
    }

    final only = amounts.first;
    if (income) return (gelir: only, gider: null);
    return (gelir: null, gider: only);
  }
}
