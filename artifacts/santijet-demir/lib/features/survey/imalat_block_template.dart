import 'package:santijet_demir/domain/entities/survey.dart';

/// İmalat türüne göre blok ve alt imalat başlangıcı.
/// Miktarlar mevcut planlanan toplama oranlanır.
abstract final class ImalatBlockTemplate {
  static List<ImalatBlock> build(SurveyImalat imalat) {
    final rows = _rowsFor(imalat.name);
    final weight = rows.fold<double>(0, (sum, row) => sum + row.subWeight);
    final scale = imalat.planned > 0 && weight > 0 ? imalat.planned / weight : 1.0;
    final grouped = <String, List<_TemplateRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.code, () => []).add(row);
    }
    return [
      for (final code in grouped.keys)
        ImalatBlock(
          id: 'block-$code',
          code: code,
          name: '$code Blok',
          items: [
            for (var i = 0; i < grouped[code]!.length; i++)
              _item(grouped[code]![i], i, scale, note: code == 'A' && i == 0),
          ],
        ),
    ];
  }

  static ImalatSubWork _item(_TemplateRow row, int index, double scale, {required bool note}) {
    final amount = row.subWeight * scale;
    final mixWeight = row.mix.fold<double>(0, (sum, part) => sum + part.$2);
    return ImalatSubWork(
      id: 'sub-${row.code}-$index',
      name: row.subName,
      note: note ? '${row.code} Blok ${row.subName.toLowerCase()} demir keşfi.' : '',
      lines: [
        for (final part in row.mix)
          if (mixWeight > 0)
            DiameterLine(
              diameter: part.$1,
              planned: amount * part.$2 / mixWeight,
              ordered: 0,
              delivered: 0,
            ),
      ],
    );
  }

  static List<_TemplateRow> _rowsFor(String name) {
    final key = _fold(name);
    final titles = _titlesFor(key);
    return [
      _TemplateRow('A', titles.$1, 80, const [(8, 6), (10, 18), (12, 32), (14, 18), (16, 6)]),
      _TemplateRow('A', titles.$2, 25, const [(8, 8), (10, 9), (12, 8)]),
      _TemplateRow('A', titles.$3, 15, const [(8, 4), (10, 6), (12, 5)]),
      _TemplateRow('B', titles.$1, 55, const [(10, 20), (12, 22), (14, 13)]),
      _TemplateRow('B', titles.$2, 40, const [(8, 12), (10, 16), (12, 12)]),
      _TemplateRow('C', titles.$1, 25, const [(10, 8), (12, 10), (14, 7)]),
      _TemplateRow('C', titles.$2, 20, const [(8, 6), (10, 8), (12, 6)]),
      _TemplateRow('C', titles.$3, 15, const [(8, 4), (10, 6), (12, 5)]),
      _TemplateRow('D', titles.$1, 18, const [(10, 7), (12, 7), (14, 4)]),
      _TemplateRow('D', titles.$3, 12, const [(8, 4), (10, 4), (12, 4)]),
    ];
  }

  static (String, String, String) _titlesFor(String key) {
    if (key.contains('temel')) return ('Radye Temel', 'Bağ Kirişi', 'Tekil Temel');
    if (key.contains('kolon')) return ('Kolon', 'Kısa Kolon', 'Perde Kolon');
    if (key.contains('perde')) return ('Perde', 'Perde Başı', 'Perde Ucu');
    if (key.contains('kiris')) return ('Kiriş', 'Hatıl', 'Lento');
    if (key.contains('doseme')) return ('Döşeme', 'Kirişli Döşeme', 'Plak');
    if (key.contains('merdiven')) return ('Merdiven', 'Sahanlık', 'Basamak');
    return ('Ana İmalat', 'Yan İmalat', 'Detay İmalat');
  }

  static String _fold(String name) {
    const map = {
      'ş': 's',
      'Ş': 's',
      'ı': 'i',
      'I': 'i',
      'İ': 'i',
      'ö': 'o',
      'Ö': 'o',
      'ü': 'u',
      'Ü': 'u',
      'ğ': 'g',
      'Ğ': 'g',
      'ç': 'c',
      'Ç': 'c',
    };
    final buffer = StringBuffer();
    for (final rune in name.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(map[char] ?? char.toLowerCase());
    }
    return buffer.toString();
  }
}

class _TemplateRow {
  const _TemplateRow(this.code, this.subName, this.subWeight, this.mix);

  final String code;
  final String subName;
  final double subWeight;
  final List<(int, double)> mix;
}
