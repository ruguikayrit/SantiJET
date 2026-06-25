import 'dart:math';

import 'package:dxf/dxf.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

class DxfRebarParser {
  const DxfRebarParser({this.settings = const RebarMetrajSettings()});

  final RebarMetrajSettings settings;

  static const dwgUnsupportedMessage =
      'DWG dosyaları doğrudan okunamaz. AutoCAD/BricsCAD ile DXF olarak '
      'kaydedin veya yakında eklenecek sunucu dönüşümünü kullanın.';

  RebarMetrajResult parse({
    required String fileName,
    required String content,
    String sourceFormat = 'DXF',
  }) {
    final warnings = <String>[];
    final grouped = <String, _LayerAccumulator>{};
    var skipped = 0;

    final dxf = DXF.fromString(content);
    for (final entity in dxf.entities) {
      final layerName = entity.layerName;
      if (!_isRebarLayer(layerName)) {
        skipped++;
        continue;
      }

      final length = _entityLength(entity);
      if (length <= 0) {
        skipped++;
        continue;
      }

      final scaledLength = length * settings.unitScale;
      final diameter = _resolveDiameter(layerName) ?? settings.defaultDiameter;
      final key = '${layerName.toUpperCase()}|$diameter';
      grouped.putIfAbsent(
        key,
        () => _LayerAccumulator(layerName: layerName, diameter: diameter),
      );
      grouped[key]!.addBar(scaledLength);
    }

    if (grouped.isEmpty) {
      warnings.add(
        'Demir katmanında çizgi/polyline bulunamadı. Katman adları '
        'DONAT, ARMATUR, DEMIR gibi anahtar kelimeler içermeli.',
      );
    }

    final lines = grouped.values
        .map(
          (entry) => RebarMetrajLine(
            diameter: entry.diameter,
            totalLengthM: entry.totalLengthM,
            weightKg: RebarWeightCalculator.weightKg(
              diameterMm: entry.diameter,
              lengthM: entry.totalLengthM,
            ),
            barCount: entry.barCount,
            layerName: entry.layerName,
          ),
        )
        .toList()
      ..sort((a, b) {
        final byDiameter = a.diameter.compareTo(b.diameter);
        if (byDiameter != 0) return byDiameter;
        return a.layerName.compareTo(b.layerName);
      });

    return RebarMetrajResult(
      fileName: fileName,
      sourceFormat: sourceFormat,
      parsedAt: DateTime.now(),
      lines: lines,
      skippedEntityCount: skipped,
      warnings: warnings,
    );
  }

  bool _isRebarLayer(String layerName) {
    final normalized = _normalize(layerName);
    return settings.layerKeywords.any(normalized.contains);
  }

  int? _resolveDiameter(String layerName) {
    final normalized = _normalize(layerName);

    final fiMatch = RegExp(r'(?:FI|F[Iİ]|Ø|O|D)[\s_-]*(\d{2})').firstMatch(
      normalized,
    );
    if (fiMatch != null) {
      return int.tryParse(fiMatch.group(1)!);
    }

    final suffixMatch = RegExp(r'(?:^|[_\-\s])(\d{2})(?:MM|MM\.|$)').firstMatch(
      normalized,
    );
    if (suffixMatch != null) {
      final value = int.tryParse(suffixMatch.group(1)!);
      if (value != null && RebarWeightCalculator.standardDiameters.contains(value)) {
        return value;
      }
    }

    final embedded = RegExp(r'(\d{2})').allMatches(normalized);
    for (final match in embedded) {
      final value = int.tryParse(match.group(1)!);
      if (value != null && RebarWeightCalculator.standardDiameters.contains(value)) {
        return value;
      }
    }

    return null;
  }

  double _entityLength(AcDbEntity entity) {
    if (entity is AcDbLine) {
      return _distance(entity.x, entity.y, entity.z, entity.x1, entity.y1, entity.z1);
    }

    if (entity is AcDbPolyline) {
      final vertices = entity.vertices;
      if (vertices.length < 2) return 0;

      var total = 0.0;
      for (var i = 1; i < vertices.length; i++) {
        total += _distance(
          vertices[i - 1][0],
          vertices[i - 1][1],
          vertices[i - 1].length > 2 ? vertices[i - 1][2] : 0,
          vertices[i][0],
          vertices[i][1],
          vertices[i].length > 2 ? vertices[i][2] : 0,
        );
      }

      if (entity.isClosed && vertices.length > 2) {
        final first = vertices.first;
        final last = vertices.last;
        total += _distance(
          last[0],
          last[1],
          last.length > 2 ? last[2] : 0,
          first[0],
          first[1],
          first.length > 2 ? first[2] : 0,
        );
      }
      return total;
    }

    return 0;
  }

  double _distance(double x1, double y1, double z1, double x2, double y2, double z2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = z2 - z1;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  String _normalize(String value) {
    return value
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }
}

class _LayerAccumulator {
  _LayerAccumulator({
    required this.layerName,
    required this.diameter,
  });

  final String layerName;
  final int diameter;
  double totalLengthM = 0;
  int barCount = 0;

  void addBar(double lengthM) {
    totalLengthM += lengthM;
    barCount++;
  }
}
