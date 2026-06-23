import 'dart:convert';

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

  Future<List<PozAnaliz>> loadDiscipline(AnalizDiscipline discipline) async {
    final path = _assetByDiscipline[discipline]!;
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((m) {
          final analiz = PozAnaliz.fromJson(m);
          // Resmi kayıtlar dosya kaynağına göre disiplinle etiketlenir.
          return analiz.discipline == null
              ? analiz.copyWith(discipline: discipline)
              : analiz;
        })
        .where((a) => a.id.isNotEmpty)
        .toList();
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
