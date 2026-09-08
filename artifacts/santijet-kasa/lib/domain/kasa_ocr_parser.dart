import 'package:uuid/uuid.dart';

import 'kasa_hareket.dart';
import 'kasa_lookups.dart';
import 'kasa_rules.dart';
import 'money_format.dart';

/// OCR / serbest metinden kasa satırları.
abstract final class KasaOcrParser {
  static final _dateRe = RegExp(
    r'(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})',
  );
  static final _moneyRe = RegExp(
    r'(?:₺|TL)?\s*(-?\d{1,3}(?:[.\s]\d{3})*(?:[,.]\d{1,2})?|-?\d+[,.]\d{2})\s*(?:₺|TL)?',
    caseSensitive: false,
  );

  /// Ham OCR metnini hareket listesine çevirir.
  static ({List<KasaHareket> hareketler, int skipped}) parseText(
    String raw, {
    DateTime? now,
    String defaultSantiye = 'İZMİT/EFSANE',
    String sourceLabel = 'OCR',
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
      final lower = line.toLowerCase();
      if (_isHeaderOrNoise(lower)) {
        skipped++;
        continue;
      }

      final parsed = _parseLine(line);
      if (parsed == null) {
        skipped++;
        continue;
      }

      final err = validateHareket(
        aciklama: parsed.aciklama,
        gelir: parsed.gelir,
        gider: parsed.gider,
      );
      if (err != null) {
        skipped++;
        continue;
      }

      out.add(
        KasaHareket(
          id: uuid.v4(),
          tarih: parsed.tarih ?? stamp,
          tedarikci: parsed.tedarikci,
          aciklama: parsed.aciklama,
          gelir: parsed.gelir,
          gider: parsed.gider,
          odemeSekli: parsed.odemeSekli.isEmpty
              ? OdemeSekli.nakit
              : parsed.odemeSekli,
          belgeTuru:
              parsed.belgeTuru.isEmpty ? BelgeTuru.fis : parsed.belgeTuru,
          santiye: parsed.santiye.isEmpty ? defaultSantiye : parsed.santiye,
          ekAciklama: parsed.ek.isEmpty
              ? 'Kaynak: $sourceLabel'
              : '${parsed.ek} · $sourceLabel',
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );
    }

    if (out.isEmpty) {
      final fallback = _parseReceiptBlock(
        raw,
        stamp: stamp,
        santiye: defaultSantiye,
        sourceLabel: sourceLabel,
      );
      if (fallback != null) out.add(fallback);
    }

    return (hareketler: out, skipped: skipped);
  }

  static bool _isHeaderOrNoise(String lower) {
    if (lower.contains('iş avansı') || lower.contains('harcama tablosu')) {
      return true;
    }
    if (lower.contains('toplam gelir') ||
        lower.contains('toplam gider') ||
        lower.contains('güncel kasa')) {
      return true;
    }
    final headerHits = [
      'tarih',
      'tedarik',
      'açıklama',
      'aciklama',
      'gelir',
      'gider',
      'ödeme',
      'odeme',
      'belge',
      'şantiye',
      'santiye',
    ].where(lower.contains).length;
    return headerHits >= 3;
  }

  static _ParsedLine? _parseLine(String line) {
    final dateMatch = _dateRe.firstMatch(line);
    final moneyMatches = _moneyRe.allMatches(line).toList();
    if (moneyMatches.isEmpty) return null;

    final amounts = <double>[];
    for (final m in moneyMatches) {
      final v = MoneyFormat.tryParse(m.group(1) ?? m.group(0));
      if (v != null && v > 0) amounts.add(v);
    }
    if (amounts.isEmpty) return null;

    final lower = line.toLowerCase();
    final looksGelir = lower.contains('gelir') ||
        lower.contains('avans') ||
        (lower.contains('havale') &&
            !lower.contains('gider') &&
            !lower.contains('fiş') &&
            !lower.contains('fatura') &&
            (lower.contains('gönder') || lower.contains('hesap')));

    double? gelir;
    double? gider;

    if (amounts.length >= 2 && lower.contains('gelir')) {
      gelir = amounts.first;
      gider = amounts.last;
      if (gelir > 0 && gider > 0) {
        if (gelir >= gider) {
          gider = null;
        } else {
          gelir = null;
        }
      }
    } else if (looksGelir) {
      gelir = amounts.last;
    } else {
      gider = amounts.last;
    }

    if ((gelir == null || gelir <= 0) && (gider == null || gider <= 0)) {
      return null;
    }
    if (gelir != null && gelir > 0 && gider != null && gider > 0) {
      gider = null;
    }

    var rest = line;
    if (dateMatch != null) {
      rest = rest.replaceFirst(dateMatch.group(0)!, ' ').trim();
    }
    for (final m in moneyMatches.reversed) {
      rest = rest.replaceFirst(m.group(0)!, ' ');
    }
    rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();

    var odeme = '';
    for (final o in OdemeSekli.all) {
      if (RegExp(RegExp.escape(o), caseSensitive: false).hasMatch(rest)) {
        odeme = o;
        rest = rest.replaceAll(RegExp(RegExp.escape(o), caseSensitive: false), ' ');
        break;
      }
    }
    if (odeme.isEmpty) {
      if (RegExp(r'\bhavale\b', caseSensitive: false).hasMatch(line)) {
        odeme = OdemeSekli.havale;
      } else if (RegExp(r'\bnakit\b', caseSensitive: false).hasMatch(line)) {
        odeme = OdemeSekli.nakit;
      } else if (RegExp(r'k\.?\s*kart', caseSensitive: false).hasMatch(line)) {
        odeme = OdemeSekli.sahsiKart;
      }
    }

    var belge = '';
    for (final b in BelgeTuru.all) {
      if (line.toLowerCase().contains(b.toLowerCase())) {
        belge = b;
        rest = rest.replaceAll(RegExp(RegExp.escape(b), caseSensitive: false), ' ');
        break;
      }
    }

    var santiye = '';
    final santiyeMatch = RegExp(
      r'([A-ZÇĞİÖŞÜa-zçğıöşü]+\/[A-ZÇĞİÖŞÜa-zçğıöşü0-9]+)',
    ).firstMatch(rest);
    if (santiyeMatch != null) {
      santiye = santiyeMatch.group(1)!;
      rest = rest.replaceFirst(santiye, ' ').trim();
    }

    rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (rest.isEmpty) rest = 'OCR satırı';

    var tedarikci = '';
    var aciklama = rest;
    final parts = rest.split(' ');
    if (parts.length >= 2) {
      final first = parts.first;
      if (first.length >= 3 && first == first.toUpperCase()) {
        var n = 1;
        while (n < parts.length &&
            n < 3 &&
            parts[n] == parts[n].toUpperCase() &&
            !parts[n].contains(',')) {
          n++;
        }
        tedarikci = parts.take(n).join(' ');
        aciklama = parts.skip(n).join(' ').trim();
        if (aciklama.isEmpty) aciklama = tedarikci;
      }
    }

    DateTime? tarih;
    if (dateMatch != null) {
      final d = int.parse(dateMatch.group(1)!);
      final m = int.parse(dateMatch.group(2)!);
      var y = int.parse(dateMatch.group(3)!);
      if (y < 100) y += 2000;
      tarih = DateTime(y, m, d);
    }

    return _ParsedLine(
      tarih: tarih,
      tedarikci: tedarikci,
      aciklama: aciklama,
      gelir: gelir != null && gelir > 0 ? gelir : null,
      gider: gider != null && gider > 0 ? gider : null,
      odemeSekli: odeme,
      belgeTuru: belge,
      santiye: santiye,
      ek: '',
    );
  }

  static KasaHareket? _parseReceiptBlock(
    String raw, {
    required DateTime stamp,
    required String santiye,
    required String sourceLabel,
  }) {
    final dateMatch = _dateRe.firstMatch(raw);
    final moneyMatches = _moneyRe.allMatches(raw).toList();
    if (moneyMatches.isEmpty) return null;
    double? maxAmount;
    for (final m in moneyMatches) {
      final v = MoneyFormat.tryParse(m.group(1) ?? m.group(0));
      if (v != null && (maxAmount == null || v > maxAmount)) maxAmount = v;
    }
    if (maxAmount == null || maxAmount <= 0) return null;

    DateTime? tarih;
    if (dateMatch != null) {
      final d = int.parse(dateMatch.group(1)!);
      final m = int.parse(dateMatch.group(2)!);
      var y = int.parse(dateMatch.group(3)!);
      if (y < 100) y += 2000;
      tarih = DateTime(y, m, d);
    }

    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !_isHeaderOrNoise(e.toLowerCase()))
        .toList();
    var aciklama = lines.isNotEmpty
        ? (lines.length > 1 ? lines.take(2).join(' · ') : lines.first)
        : 'OCR fiş';
    if (aciklama.length > 120) {
      aciklama = '${aciklama.substring(0, 120)}…';
    }

    return KasaHareket(
      id: const Uuid().v4(),
      tarih: tarih ?? stamp,
      aciklama: aciklama,
      gider: maxAmount,
      odemeSekli: OdemeSekli.nakit,
      belgeTuru: BelgeTuru.fis,
      santiye: santiye,
      ekAciklama: 'Kaynak: $sourceLabel (fiş)',
      createdAt: stamp,
      updatedAt: stamp,
    );
  }
}

class _ParsedLine {
  const _ParsedLine({
    required this.tarih,
    required this.tedarikci,
    required this.aciklama,
    required this.gelir,
    required this.gider,
    required this.odemeSekli,
    required this.belgeTuru,
    required this.santiye,
    required this.ek,
  });

  final DateTime? tarih;
  final String tedarikci;
  final String aciklama;
  final double? gelir;
  final double? gider;
  final String odemeSekli;
  final String belgeTuru;
  final String santiye;
  final String ek;
}
