import 'dart:math' as math;

import '../regulation/regulation_catalog.dart';

/// Fiziksel yerleşim — eleman hesaplarından bağımsız ortak geometri.
abstract final class PlacementCalculator {
  static double availableInnerMm({
    required double sectionMm,
    required double coverMm,
    required double stirrupDiameterMm,
  }) {
    return sectionMm - 2 * coverMm - 2 * stirrupDiameterMm;
  }

  static int maxBarsInLayer({
    required double availableMm,
    required double barDiameterMm,
    required double clearSpacingMm,
  }) {
    if (availableMm + 1e-9 < barDiameterMm) return 0;
    return ((availableMm + clearSpacingMm) / (barDiameterMm + clearSpacingMm))
        .floor();
  }

  static int layersNeeded(int bars, int maxPerLayer) {
    if (bars <= 0) return 0;
    if (maxPerLayer <= 0) return 999;
    return (bars / maxPerLayer).ceil();
  }

  static int columnPerimeterCapacity({
    required double widthMm,
    required double heightMm,
    required double coverMm,
    required double stirrupDiameterMm,
    required double barDiameterMm,
    required RegulationCatalog catalog,
  }) {
    final clear = catalog.minClearForBar(barDiameterMm);
    final availB = availableInnerMm(
      sectionMm: widthMm,
      coverMm: coverMm,
      stirrupDiameterMm: stirrupDiameterMm,
    );
    final availH = availableInnerMm(
      sectionMm: heightMm,
      coverMm: coverMm,
      stirrupDiameterMm: stirrupDiameterMm,
    );
    final onB = maxBarsInLayer(
      availableMm: availB,
      barDiameterMm: barDiameterMm,
      clearSpacingMm: clear,
    );
    final onH = maxBarsInLayer(
      availableMm: availH,
      barDiameterMm: barDiameterMm,
      clearSpacingMm: clear,
    );
    if (onB < 2 || onH < 2) return 0;
    return 2 * (onB + onH) - 4;
  }

  static bool columnFits({
    required double widthMm,
    required double heightMm,
    required double coverMm,
    required double stirrupDiameterMm,
    required double barDiameterMm,
    required int count,
    required RegulationCatalog catalog,
  }) {
    final capacity = columnPerimeterCapacity(
      widthMm: widthMm,
      heightMm: heightMm,
      coverMm: coverMm,
      stirrupDiameterMm: stirrupDiameterMm,
      barDiameterMm: barDiameterMm,
      catalog: catalog,
    );
    return count <= capacity;
  }

  static ({int maxPerLayer, int layers, bool fits}) beamFit({
    required double widthMm,
    required double heightMm,
    required double coverMm,
    required double stirrupDiameterMm,
    required double barDiameterMm,
    required int count,
    required RegulationCatalog catalog,
  }) {
    final clear = catalog.minClearForBar(barDiameterMm);
    final avail = availableInnerMm(
      sectionMm: widthMm,
      coverMm: coverMm,
      stirrupDiameterMm: stirrupDiameterMm,
    );
    final maxPerLayer = maxBarsInLayer(
      availableMm: avail,
      barDiameterMm: barDiameterMm,
      clearSpacingMm: clear,
    );
    final layers = layersNeeded(count, maxPerLayer);
    final stackHeight =
        coverMm + stirrupDiameterMm + layers * barDiameterMm + (layers - 1) * clear;
    final heightOk = stackHeight <= heightMm * 0.45 + 1e-9;
    return (
      maxPerLayer: maxPerLayer,
      layers: layers,
      fits: maxPerLayer > 0 && layers <= catalog.maxBeamLayers && heightOk,
    );
  }

  static bool spacingPhysicallyPossible({
    required double spacingMm,
    required double barDiameterMm,
    required RegulationCatalog catalog,
  }) {
    return spacingMm + 1e-9 >= barDiameterMm + catalog.minClearForBar(barDiameterMm);
  }

  static bool thicknessFitsLayers({
    required double thicknessMm,
    required double coverMm,
    required double barDiameterMm,
    required bool bothLayers,
  }) {
    final needed = bothLayers
        ? 2 * coverMm + 2 * barDiameterMm + 20
        : coverMm + barDiameterMm + coverMm;
    return needed <= thicknessMm + 1e-9;
  }

  static double faceClearSpacingMm({
    required double availableMm,
    required int barsOnFace,
    required double barDiameterMm,
  }) {
    if (barsOnFace <= 1) return availableMm;
    return (availableMm - barsOnFace * barDiameterMm) /
        math.max(1, barsOnFace - 1);
  }
}
