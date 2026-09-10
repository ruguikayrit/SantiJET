import 'package:uuid/uuid.dart';

import '../domain/kasa_hareket.dart';
import '../domain/kasa_lookups.dart';
import '../domain/kasa_ocr_parser.dart';
import '../domain/kasa_rules.dart';
import 'kasa_ocr_normalize.dart';

/// OCR kelimesi — konum ile.
class OcrWord {
  const OcrWord({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String text;
  final int left;
  final int top;
  final int width;
  final int height;

  int get right => left + width;
  int get centerX => left + (width ~/ 2);
  int get centerY => top + (height ~/ 2);
}

/// Overlay kelimelerinden Excel tablosu sütun hizalaması.
abstract final class KasaTableOcr {
  static const _colKeys = <String>[
    'tarih',
    'tedarikci',
    'aciklama',
    'gelir',
    'gider',
    'odeme',
    'belge',
    'santiye',
    'ek',
  ];

  static final _dateRe = RegExp(
    r'^(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})$',
  );

  /// Overlay varsa tablo hizala; yoksa satır parser’a düş.
  static ({List<KasaHareket> hareketler, int skipped}) parse({
    required String rawText,
    List<OcrWord> words = const [],
    DateTime? now,
    String defaultSantiye = 'İZMİT/EFSANE',
    String sourceLabel = 'OCR tablo',
  }) {
    if (words.length >= 12) {
      final fromOverlay = _fromOverlay(
        words,
        now: now,
        defaultSantiye: defaultSantiye,
        sourceLabel: sourceLabel,
      );
      if (fromOverlay.hareketler.isNotEmpty) return fromOverlay;
    }

    // Metin: sağdan sütun soyma (Excel defteri)
    final peeled = _fromPeeledLines(
      rawText,
      now: now,
      defaultSantiye: defaultSantiye,
      sourceLabel: sourceLabel,
    );
    if (peeled.hareketler.isNotEmpty) return peeled;

    return KasaOcrParser.parseText(
      rawText,
      now: now,
      defaultSantiye: defaultSantiye,
      sourceLabel: sourceLabel,
    );
  }

  static ({List<KasaHareket> hareketler, int skipped}) _fromOverlay(
    List<OcrWord> words, {
    DateTime? now,
    required String defaultSantiye,
    required String sourceLabel,
  }) {
    final stamp = now ?? DateTime.now();
    const uuid = Uuid();
    final rows = _clusterRows(words);
    if (rows.length < 2) {
      return (hareketler: <KasaHareket>[], skipped: 0);
    }

    final headerIdx = _findHeaderRow(rows);
    if (headerIdx < 0) {
      return (hareketler: <KasaHareket>[], skipped: 0);
    }

    final colCenters = _headerColumnCenters(rows[headerIdx]);
    if (colCenters.length < 4) {
      return (hareketler: <KasaHareket>[], skipped: 0);
    }

    final out = <KasaHareket>[];
    var skipped = 0;

    for (var i = headerIdx + 1; i < rows.length; i++) {
      final cells = _assignColumns(rows[i], colCenters);
      final h = _hareketFromCells(
        cells,
        stamp: stamp,
        id: uuid.v4(),
        defaultSantiye: defaultSantiye,
        sourceLabel: sourceLabel,
      );
      if (h == null) {
        skipped++;
      } else {
        out.add(h);
      }
    }

    return (hareketler: out, skipped: skipped);
  }

  static List<List<OcrWord>> _clusterRows(List<OcrWord> words) {
    final sorted = [...words]..sort((a, b) {
        final dy = a.centerY.compareTo(b.centerY);
        if (dy != 0) return dy;
        return a.left.compareTo(b.left);
      });
    if (sorted.isEmpty) return const [];

    final heights = sorted.map((w) => w.height).toList()..sort();
    final medianH = heights[heights.length ~/ 2].clamp(10, 40);
    final tol = (medianH * 0.55).round().clamp(6, 22);

    final rows = <List<OcrWord>>[];
    var current = <OcrWord>[sorted.first];
    var rowY = sorted.first.centerY;

    for (var i = 1; i < sorted.length; i++) {
      final w = sorted[i];
      if ((w.centerY - rowY).abs() <= tol) {
        current.add(w);
        rowY = ((rowY * (current.length - 1)) + w.centerY) ~/ current.length;
      } else {
        current.sort((a, b) => a.left.compareTo(b.left));
        rows.add(current);
        current = [w];
        rowY = w.centerY;
      }
    }
    current.sort((a, b) => a.left.compareTo(b.left));
    rows.add(current);
    return rows;
  }

  static int _findHeaderRow(List<List<OcrWord>> rows) {
    for (var i = 0; i < rows.length && i < 8; i++) {
      final joined = rows[i].map((w) => KasaOcrNormalize.fold(w.text)).join(' ');
      if (KasaOcrNormalize.isHeaderLine(joined)) return i;
    }
    return -1;
  }

  static Map<String, int> _headerColumnCenters(List<OcrWord> header) {
    final map = <String, int>{};
    for (final w in header) {
      final t = _fold(w.text);
      final key = _headerKey(t);
      // İlk eşleşme sütun merkezidir; ikinci "AÇIKLAMA" (Ek Açıklama)
      // asıl açıklama sütununu kaydırmasın.
      if (key != null && !map.containsKey(key)) {
        map[key] = w.centerX;
      }
    }
    // Eksik sütunları komşulardan tahmin et
    _fillMissingCenters(map);
    return map;
  }

  static String? _headerKey(String t) {
    if (t.contains('tarih')) return 'tarih';
    if (t.contains('tedarik')) return 'tedarikci';
    if (t.contains('aciklama') || t.contains('açıklama')) {
      if (t.contains('ek')) return 'ek';
      return 'aciklama';
    }
    if (t == 'gelir' || t.startsWith('gelir')) return 'gelir';
    if (t == 'gider' || t.startsWith('gider')) return 'gider';
    if (t.contains('odeme') || t.contains('ödeme')) return 'odeme';
    if (t.contains('belge')) return 'belge';
    if (t.contains('santiye') || t.contains('şantiye')) return 'santiye';
    if (t.contains('ek')) return 'ek';
    return null;
  }

  static void _fillMissingCenters(Map<String, int> map) {
    // Bilinen sıralı varsayılan oranlar (0–1000)
    const defaults = {
      'tarih': 40,
      'tedarikci': 140,
      'aciklama': 320,
      'gelir': 480,
      'gider': 560,
      'odeme': 680,
      'belge': 780,
      'santiye': 880,
      'ek': 980,
    };
    if (map.isEmpty) {
      map.addAll(defaults);
      return;
    }
    final known = map.values.toList()..sort();
    final span = (known.last - known.first).clamp(200, 5000);
    final origin = known.first;
    for (final key in _colKeys) {
      if (map.containsKey(key)) continue;
      final ratio = defaults[key]! / 1000.0;
      map[key] = origin + (span * ratio).round();
    }
  }

  static Map<String, String> _assignColumns(
    List<OcrWord> row,
    Map<String, int> centers,
  ) {
    final cells = {for (final k in _colKeys) k: <String>[]};
    final keys = _colKeys.where(centers.containsKey).toList()
      ..sort((a, b) => centers[a]!.compareTo(centers[b]!));

    for (final w in row) {
      var best = keys.first;
      var bestDist = (w.centerX - centers[best]!).abs();
      for (final k in keys.skip(1)) {
        final d = (w.centerX - centers[k]!).abs();
        if (d < bestDist) {
          bestDist = d;
          best = k;
        }
      }
      cells[best]!.add(w.text);
    }

    return {
      for (final e in cells.entries) e.key: e.value.join(' ').trim(),
    };
  }

  static KasaHareket? _hareketFromCells(
    Map<String, String> cells, {
    required DateTime stamp,
    required String id,
    required String defaultSantiye,
    required String sourceLabel,
  }) {
    final tarih = _parseDate(cells['tarih'] ?? '') ??
        _parseDate(_dateRe.firstMatch(cells.values.join(' '))?.group(0) ?? '');
    var aciklama = (cells['aciklama'] ?? '').trim();
    final tedarikci = (cells['tedarikci'] ?? '').trim();
    if (aciklama.isEmpty) aciklama = tedarikci;
    if (aciklama.isEmpty) return null;

    // Sütun tutarları kaynak kabul edilir; satırdaki adet/kg sayıları
    // (1 PAKET, 10 ADET) tutarı ezmesin.
    double? gIn = KasaOcrNormalize.parseMoney(cells['gelir']);
    double? gOut = KasaOcrNormalize.parseMoney(cells['gider']);
    if (gIn != null && gIn <= 0) gIn = null;
    if (gOut != null && gOut <= 0) gOut = null;
    if (gIn != null && gOut != null) {
      if (gIn >= gOut) {
        gOut = null;
      } else {
        gIn = null;
      }
    }
    if (gIn == null && gOut == null) {
      for (final key in ['aciklama', 'odeme', 'ek', 'tedarikci']) {
        final v = KasaOcrNormalize.parseMoney(cells[key]);
        if (v != null && v > 0) {
          gOut = v;
          break;
        }
      }
    }

    final odeme = KasaOcrNormalize.matchOdeme((cells['odeme'] ?? '').trim());

    final err = validateHareket(aciklama: aciklama, gelir: gIn, gider: gOut);
    if (err != null) return null;

    var belge = KasaOcrNormalize.matchBelge((cells['belge'] ?? '').trim());
    var santiye = (cells['santiye'] ?? '').trim();
    if (santiye.isEmpty) santiye = defaultSantiye;

    return KasaHareket(
      id: id,
      tarih: tarih ?? stamp,
      tedarikci: tedarikci,
      aciklama: aciklama,
      gelir: gIn,
      gider: gOut,
      odemeSekli: odeme.isEmpty ? OdemeSekli.nakit : odeme,
      belgeTuru: belge.isEmpty ? BelgeTuru.yok : belge,
      santiye: santiye,
      ekAciklama: (cells['ek'] ?? '').trim(),
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  /// Satır metninden sağdan sütun soyma — Excel defteri JPG için.
  static ({List<KasaHareket> hareketler, int skipped}) _fromPeeledLines(
    String raw, {
    DateTime? now,
    required String defaultSantiye,
    required String sourceLabel,
  }) {
    final stamp = now ?? DateTime.now();
    const uuid = Uuid();
    final lines = raw
        .replaceAll('\r', '\n')
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final out = <KasaHareket>[];
    var skipped = 0;

    for (final line in lines) {
      final lower = KasaOcrNormalize.fold(line);
      if (KasaOcrNormalize.isHeaderLine(lower)) {
        skipped++;
        continue;
      }
      final peeled = _peelLine(line, defaultSantiye: defaultSantiye);
      if (peeled == null) {
        skipped++;
        continue;
      }
      final err = validateHareket(
        aciklama: peeled.aciklama,
        gelir: peeled.gelir,
        gider: peeled.gider,
      );
      if (err != null) {
        skipped++;
        continue;
      }
      out.add(
        KasaHareket(
          id: uuid.v4(),
          tarih: peeled.tarih ?? stamp,
          tedarikci: peeled.tedarikci,
          aciklama: peeled.aciklama,
          gelir: peeled.gelir,
          gider: peeled.gider,
          odemeSekli:
              peeled.odeme.isEmpty ? OdemeSekli.nakit : peeled.odeme,
          belgeTuru: peeled.belge.isEmpty ? BelgeTuru.yok : peeled.belge,
          santiye: peeled.santiye.isEmpty ? defaultSantiye : peeled.santiye,
          ekAciklama: peeled.ek,
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );
    }

    return (hareketler: out, skipped: skipped);
  }

  static _Peeled? _peelLine(String line, {required String defaultSantiye}) {
    var rest = line.trim();
    final dateMatch = RegExp(
      r'^(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})\b',
    ).firstMatch(rest);
    if (dateMatch == null) return null;

    final d = int.parse(dateMatch.group(1)!);
    final m = int.parse(dateMatch.group(2)!);
    var y = int.parse(dateMatch.group(3)!);
    if (y < 100) y += 2000;
    final tarih = DateTime(y, m, d);
    rest = rest.substring(dateMatch.end).trim();

    // Sağdan şantiye
    var santiye = '';
    final santiyeRe = RegExp(
      r'([A-ZÇĞİÖŞÜa-zçğıöşüİı]+\/[A-ZÇĞİÖŞÜa-zçğıöşüİı0-9]+)',
    );
    final sm = santiyeRe.allMatches(rest).toList();
    if (sm.isNotEmpty) {
      santiye = sm.last.group(1)!;
      rest = rest.replaceFirst(santiye, ' ').trim();
    }

    var belge = '';
    for (final b in ['FATURA', 'FİŞ', 'FIS', 'YOK']) {
      final re = RegExp('\\b${RegExp.escape(b)}\\b', caseSensitive: false);
      if (re.hasMatch(rest)) {
        belge = KasaOcrNormalize.matchBelge(b);
        rest = rest.replaceFirst(re, ' ').trim();
        break;
      }
    }

    var odeme = '';
    final odemePatterns = <RegExp>[
      RegExp(r'ŞAHS[Iİ]\s*K\.?\s*KART[Iİ]', caseSensitive: false),
      RegExp(r'ŞİRKET\s*K\.?\s*KART', caseSensitive: false),
      RegExp(r'\bHAVALE\b', caseSensitive: false),
      RegExp(r'\bNAK[Iİ]T\b', caseSensitive: false),
      RegExp(r'\bD[Iİ]ĞER\b|\bDIGER\b', caseSensitive: false),
    ];
    for (final re in odemePatterns) {
      final m = re.firstMatch(rest);
      if (m != null) {
        odeme = KasaOcrNormalize.matchOdeme(m.group(0)!);
        rest = rest.replaceFirst(re, ' ').trim();
        break;
      }
    }

    final amounts = <double>[];
    for (final m in KasaOcrNormalize.moneyPattern.allMatches(rest).toList()) {
      final rawAmt = m.group(1) ?? m.group(2) ?? m.group(0);
      final v = KasaOcrNormalize.parseMoney(rawAmt);
      if (v != null && v > 0) amounts.add(v);
      rest = rest.replaceFirst(m.group(0)!, ' ');
    }
    rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();

    final split = KasaOcrNormalize.splitAmounts(
      amounts: amounts,
      context: line,
      odeme: odeme,
    );
    final gelir = split.gelir;
    final gider = split.gider;
    if (gelir == null && gider == null) return null;

    // Kalan: tedarikçi + açıklama + ek
    var tedarikci = '';
    var aciklama = rest;
    var ek = '';
    final parts = rest.split(RegExp(r'\s{2,}|\s·\s|\s\|\s'));
    if (parts.length >= 2) {
      tedarikci = parts.first.trim();
      aciklama = parts[1].trim();
      if (parts.length >= 3) ek = parts.sublist(2).join(' ').trim();
    } else {
      final tokens = rest.split(' ');
      if (tokens.length >= 2 &&
          tokens.first == tokens.first.toUpperCase() &&
          tokens.first.length >= 3) {
        var n = 1;
        while (n < tokens.length &&
            n < 3 &&
            tokens[n] == tokens[n].toUpperCase()) {
          n++;
        }
        tedarikci = tokens.take(n).join(' ');
        aciklama = tokens.skip(n).join(' ').trim();
      }
    }
    if (aciklama.isEmpty) aciklama = tedarikci.isEmpty ? 'OCR satırı' : tedarikci;

    return _Peeled(
      tarih: tarih,
      tedarikci: tedarikci,
      aciklama: aciklama,
      gelir: gelir,
      gider: gider,
      odeme: odeme,
      belge: belge,
      santiye: santiye.isEmpty ? defaultSantiye : santiye,
      ek: ek,
    );
  }

  static DateTime? _parseDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final m = RegExp(
      r'(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})',
    ).firstMatch(t);
    if (m == null) return null;
    final d = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    var y = int.parse(m.group(3)!);
    if (y < 100) y += 2000;
    return DateTime(y, mo, d);
  }

  static String _fold(String s) {
    return s
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }
}

class _Peeled {
  const _Peeled({
    required this.tarih,
    required this.tedarikci,
    required this.aciklama,
    required this.gelir,
    required this.gider,
    required this.odeme,
    required this.belge,
    required this.santiye,
    required this.ek,
  });

  final DateTime? tarih;
  final String tedarikci;
  final String aciklama;
  final double? gelir;
  final double? gider;
  final String odeme;
  final String belge;
  final String santiye;
  final String ek;
}
