import 'dart:math' as math;

import 'package:santijet_demir/data/services/cad_text_entity.dart';

/// DWG metinlerini çizim okuma sırasına göre sıralar.
List<CadTextEntity> sortCadTextEntitiesForMetraj(List<CadTextEntity> entities) {
  if (entities.length <= 1) return entities;

  final positioned = entities.where((entity) => entity.hasPosition).toList();
  if (positioned.length < 2) return entities;

  final xs = positioned.map((entity) => entity.x!).toList()..sort();
  final ys = positioned.map((entity) => entity.y!).toList()..sort();
  final spanX = xs.last - xs.first;
  final spanY = ys.last - ys.first;

  // Tüm koordinatlar aynıysa sıralama anlamsız.
  if (spanX.abs() < 1 && spanY.abs() < 1) return entities;

  final sorted = List<CadTextEntity>.from(entities)
    ..sort((a, b) => a.compareDrawingOrder(b));

  return sorted;
}

/// İki metin arasındaki çizim mesafesi (CAD birimi).
double cadTextDistance(CadTextEntity a, CadTextEntity b) {
  if (!a.hasPosition || !b.hasPosition) return double.infinity;
  final dx = a.x! - b.x!;
  final dy = a.y! - b.y!;
  return math.sqrt(dx * dx + dy * dy);
}

/// Metin listesindeki konumlu elemanlar için tipik atama yarıçapı.
double estimateMetrajAssignRadius(List<CadTextEntity> entities) {
  final positioned = entities.where((entity) => entity.hasPosition).toList();
  if (positioned.length < 2) return 15000;

  final xs = positioned.map((entity) => entity.x!).toList()..sort();
  final ys = positioned.map((entity) => entity.y!).toList()..sort();
  final span = math.max(xs.last - xs.first, ys.last - ys.first);
  if (span <= 0) return 15000;

  return (span * 0.35).clamp(800, 25000);
}
