import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Resmi katalog JSON dosyalarını assets'ten yükler ve `PozAnaliz` listesine
/// dönüştürür. Disiplin bilgisi dosya kaynağına göre etiketlenir.
class CatalogLocalDataSource {
  const CatalogLocalDataSource();

  static const _assetByDiscipline = {
    AnalizDiscipline.insaat: 'assets/data/resmi-poz-analizleri.json',
    AnalizDiscipline.mekanik: 'assets/data/resmi-mekanik-analizleri.json',
    AnalizDiscipline.elektrik: 'assets/data/resmi-elektrik-analizleri.json',
  };

  /// Web'de UI'yi kilitlememek için her N kayıtta event loop'a bırakılır.
  static const _webYieldEvery = 400;

  Future<List<PozAnaliz>> loadDiscipline(AnalizDiscipline discipline) async {
    final path = _assetByDiscipline[discipline]!;
    final raw = await rootBundle.loadString(path);
    final args = _CatalogParseArgs(raw, discipline.jsonValue);

    if (kIsWeb) {
      return _parseDisciplineJsonChunked(args);
    }
    // Mobil/desktop: JSON parse arka plan izolatında.
    return compute(_parseDisciplineJsonSync, args);
  }

  Future<Map<AnalizDiscipline, List<PozAnaliz>>> loadAll() async {
    final entries = await Future.wait(
      AnalizDiscipline.values.map(
        (d) async => MapEntry(d, await loadDiscipline(d)),
      ),
    );
    return Map.fromEntries(entries);
  }
}

class _CatalogParseArgs {
  const _CatalogParseArgs(this.raw, this.disciplineKey);

  final String raw;
  final String disciplineKey;
}

List<PozAnaliz> _parseDisciplineJsonSync(_CatalogParseArgs args) {
  final decoded = json.decode(args.raw);
  if (decoded is! List) return const [];
  final discipline = AnalizDiscipline.fromJson(args.disciplineKey);
  final out = <PozAnaliz>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final analiz = PozAnaliz.fromJson(Map<dynamic, dynamic>.from(item));
    if (analiz.id.isEmpty) continue;
    out.add(
      analiz.discipline == null
          ? analiz.copyWith(discipline: discipline)
          : analiz,
    );
  }
  return out;
}

Future<List<PozAnaliz>> _parseDisciplineJsonChunked(
  _CatalogParseArgs args,
) async {
  final decoded = json.decode(args.raw);
  if (decoded is! List) return const [];
  final discipline = AnalizDiscipline.fromJson(args.disciplineKey);
  final out = <PozAnaliz>[];
  for (var i = 0; i < decoded.length; i++) {
    final item = decoded[i];
    if (item is Map) {
      final analiz = PozAnaliz.fromJson(Map<dynamic, dynamic>.from(item));
      if (analiz.id.isNotEmpty) {
        out.add(
          analiz.discipline == null
              ? analiz.copyWith(discipline: discipline)
              : analiz,
        );
      }
    }
    if (i > 0 && i % CatalogLocalDataSource._webYieldEvery == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  return out;
}
