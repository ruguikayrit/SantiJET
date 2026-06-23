import '../../domain/entities/poz_analiz.dart';

/// Türkçe arama/normalizasyon — React Native `pozAnalizleri.ts` mantığının
/// birebir Dart portu (token + ölçü birimi + kelime sınırı eşleşmesi).
abstract final class TrSearch {
  static const _measureUnits = 'cm|mm|m²|m³|m2|m3|kg|ton|adet|lt|gr';
  static const _wordChar = 'a-z0-9ğüşıöç';

  /// TR küçük harfe çevirir ( İ/I dönüşümleri dahil) ve kırpılır.
  static String normalize(String text) {
    return text.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  }

  static String _escape(String text) {
    return text.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (m) => '\\${m[0]}',
    );
  }

  /// "19cm" → "19 cm" gibi bitişik ölçü yazımlarını ayırır.
  static String _expand(String query) {
    return normalize(query).replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(' + _measureUnits + r')\b',
          caseSensitive: false),
      (m) => '${m[1]} ${m[2]}',
    );
  }

  /// Sorguyu kelime token'larına ayırır; sayı+birim çiftlerini birleştirir.
  static List<String> tokenize(String query) {
    final parts = _expand(query)
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final unitRe = RegExp('^($_measureUnits)\$', caseSensitive: false);
    final tokens = <String>[];

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final next = i + 1 < parts.length ? parts[i + 1] : null;
      if (RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(part) &&
          next != null &&
          unitRe.hasMatch(next)) {
        tokens.add('$part $next');
        i++;
      } else {
        tokens.add(part);
      }
    }
    return tokens;
  }

  static bool _tokenMatches(String token, String haystack) {
    final measureMatch = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s+(' + _measureUnits + r')$',
      caseSensitive: false,
    ).firstMatch(token);

    if (measureMatch != null) {
      final num = _escape(measureMatch.group(1)!);
      final unit = _escape(measureMatch.group(2)!);
      final re = RegExp(
        '(^|[^$_wordChar])$num\\s*$unit(\$|[^$_wordChar])',
        caseSensitive: false,
      );
      return re.hasMatch(haystack);
    }

    final re = RegExp(
      '(^|[^$_wordChar])${_escape(token)}(\$|[^$_wordChar])',
      caseSensitive: false,
    );
    return re.hasMatch(haystack);
  }

  /// Analizin aranabilir metnini birleştirir (poz + ad + tarif + kategori + kalemler).
  static String buildHaystack(PozAnaliz a) {
    final kalemMetni = a.kalemler.map((k) => '${k.pozNo} ${k.tanim}').join(' ');
    return normalize(
      [a.pozNo, a.analizAdi, a.pozTarifi, a.kategori, kalemMetni]
          .where((s) => s.isNotEmpty)
          .join(' '),
    );
  }

  /// Tüm token'lar eşleşmeli (AND arama).
  static bool matches(PozAnaliz a, String query) {
    final tokens = tokenize(query);
    if (tokens.isEmpty) return true;
    final haystack = buildHaystack(a);
    return tokens.every((t) => _tokenMatches(t, haystack));
  }
}
