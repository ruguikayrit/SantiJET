import '../domain/kasa_lookups.dart';
import '../domain/money_format.dart';

/// OCR hücre metnini kasa alanlarına normalize eder.
abstract final class KasaOcrNormalize {
  /// Yalnız gerçek tutarlar: ₺… veya `1.234,56` / `350,00`.
  /// Çıplak `1`, `10`, `48` (adet/kg) para değildir.
  static final moneyPattern = RegExp(
    r'₺\s*(-?\d{1,3}(?:\.\d{3})*(?:,\d{2})?|-?\d+,\d{2})|'
    r'(-?\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:₺|TL)?',
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
    final extracted = allAmounts(raw);
    if (extracted.isNotEmpty) {
      return extracted.reduce((a, b) => a > b ? a : b);
    }
    final t = raw.trim();
    if (!RegExp(r'^-?[\d.,\s₺TL]+$', caseSensitive: false).hasMatch(t)) {
      return null;
    }
    final v = MoneyFormat.tryParse(t);
    if (v != null && v > 0) return v;
    return null;
  }

  /// Metindeki tüm tutarları bul (soldan sağa) — adet/tarih sayıları yok.
  static List<double> allAmounts(String raw) {
    final out = <double>[];
    for (final m in moneyPattern.allMatches(raw)) {
      final rawAmt = m.group(1) ?? m.group(2) ?? m.group(0);
      final v = MoneyFormat.tryParse(rawAmt);
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
    return hits >= 3 ||
        lower.contains('iş avansı') ||
        lower.contains('harcama tablosu');
  }

  /// Satır soyma: tek tutar giderdir; gelir yalnız havale + gelir ipucu.
  static ({double? gelir, double? gider}) splitAmounts({
    required List<double> amounts,
    required String context,
    required String odeme,
  }) {
    if (amounts.isEmpty) return (gelir: null, gider: null);
    final income = isIncomeHint(context) && odeme == OdemeSekli.havale;

    if (amounts.length >= 2) {
      var gIn = amounts[amounts.length - 2];
      var gOut = amounts.last;
      if ((gIn - gOut).abs() < 0.01) {
        return (gelir: null, gider: gOut);
      }
      if (!income) return (gelir: null, gider: gOut);
      return (gelir: gIn, gider: null);
    }

    final only = amounts.first;
    if (income) return (gelir: only, gider: null);
    return (gelir: null, gider: only);
  }
}
