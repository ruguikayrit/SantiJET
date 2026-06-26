import 'dart:convert';
import 'dart:math';

import 'package:santijet_demir/data/services/cad_text_entity.dart';

class DxfSegment {
  const DxfSegment({
    required this.layerName,
    required this.length,
  });

  final String layerName;
  final double length;
}

/// Lightweight ASCII DXF reader focused on LINE / LWPOLYLINE / POLYLINE.
class DxfAsciiParser {
  const DxfAsciiParser._();

  static const binaryDxfMessage =
      'Bu dosya Binary DXF formatında. AutoCAD\'de "ASCII DXF" olarak kaydedin.';

  static const invalidDxfMessage =
      'Geçerli bir ASCII DXF dosyası okunamadı. Dosyayı AutoCAD/BricsCAD '
      'üzerinden DXF (ASCII) olarak yeniden kaydedin.';

  static bool isBinaryDxf(List<int> bytes) {
    if (bytes.length < 22) return false;
    final header = latin1.decode(bytes.sublist(0, 22), allowInvalid: true);
    return header.startsWith('AutoCAD Binary DXF');
  }

  static String decodeContent(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      final codeUnits = <int>[];
      for (var i = 2; i + 1 < bytes.length; i += 2) {
        codeUnits.add(bytes[i] | (bytes[i + 1] << 8));
      }
      return String.fromCharCodes(codeUnits);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final codeUnits = <int>[];
      for (var i = 2; i + 1 < bytes.length; i += 2) {
        codeUnits.add((bytes[i] << 8) | bytes[i + 1]);
      }
      return String.fromCharCodes(codeUnits);
    }
    return latin1.decode(bytes, allowInvalid: true);
  }

  static List<DxfSegment> parseAllSegments(String content) {
    final pairs = readPairs(content);
    if (pairs.isEmpty) {
      throw FormatException(invalidDxfMessage);
    }

    final segments = <DxfSegment>[];
    var inEntities = false;
    var index = 0;

    String? polylineLayer;
    final polylineVertices = <(double, double)>[];

    void flushPolyline() {
      if (polylineLayer == null || polylineVertices.length < 2) {
        polylineVertices.clear();
        polylineLayer = null;
        return;
      }

      var total = 0.0;
      for (var i = 1; i < polylineVertices.length; i++) {
        total += distance(
          polylineVertices[i - 1].$1,
          polylineVertices[i - 1].$2,
          0,
          polylineVertices[i].$1,
          polylineVertices[i].$2,
          0,
        );
      }

      segments.add(DxfSegment(layerName: polylineLayer!, length: total));
      polylineVertices.clear();
      polylineLayer = null;
    }

    while (index < pairs.length) {
      final code = pairs[index].$1;
      final value = pairs[index].$2;

      if (code == 0 && value == 'SECTION') {
        if (index + 1 < pairs.length && pairs[index + 1].$1 == 2) {
          final sectionName = pairs[index + 1].$2.toUpperCase();
          inEntities = sectionName == 'ENTITIES';
        }
        index++;
        continue;
      }

      if (code == 0 && value == 'ENDSEC') {
        flushPolyline();
        inEntities = false;
        index++;
        continue;
      }

      if (!inEntities || code != 0) {
        index++;
        continue;
      }

      final entityType = value.toUpperCase();

      if (entityType == 'POLYLINE') {
        flushPolyline();
        polylineLayer = _layerFrom(pairs, index);
        index++;
        continue;
      }

      if (entityType == 'VERTEX' && polylineLayer != null) {
        polylineVertices.add((
          _doubleFrom(pairs, index, 10),
          _doubleFrom(pairs, index, 20),
        ));
        index++;
        continue;
      }

      if (entityType == 'SEQEND') {
        flushPolyline();
        index++;
        continue;
      }

      final entityStart = index;
      index++;

      while (index < pairs.length) {
        final nextCode = pairs[index].$1;
        if (nextCode == 0) break;
        index++;
      }

      final entityPairs = pairs.sublist(entityStart, index);
      segments.addAll(_segmentsFromEntity(entityType, entityPairs));
    }

    flushPolyline();
    return segments;
  }

  /// ENTITIES bölümündeki TEXT ve MTEXT içeriklerini döndürür.
  static List<String> parseAllTexts(String content) {
    return parseAllTextEntities(content).map((entity) => entity.text).toList();
  }

  /// ENTITIES bölümündeki TEXT ve MTEXT kayıtlarını tür bilgisiyle döndürür.
  static List<CadTextEntity> parseAllTextEntities(String content) {
    final pairs = readPairs(content);
    if (pairs.isEmpty) {
      throw FormatException(invalidDxfMessage);
    }

    final entities = <CadTextEntity>[];
    var inEntities = false;
    var index = 0;

    while (index < pairs.length) {
      final code = pairs[index].$1;
      final value = pairs[index].$2;

      if (code == 0 && value == 'SECTION') {
        if (index + 1 < pairs.length && pairs[index + 1].$1 == 2) {
          inEntities = pairs[index + 1].$2.toUpperCase() == 'ENTITIES';
        }
        index++;
        continue;
      }

      if (code == 0 && value == 'ENDSEC') {
        inEntities = false;
        index++;
        continue;
      }

      if (!inEntities || code != 0) {
        index++;
        continue;
      }

      final entityType = value.toUpperCase();
      if (entityType != 'TEXT' && entityType != 'MTEXT') {
        index++;
        continue;
      }

      final entityStart = index;
      index++;

      while (index < pairs.length) {
        if (pairs[index].$1 == 0) break;
        index++;
      }

      final text = _textFromEntity(pairs.sublist(entityStart, index));
      if (text != null && text.trim().isNotEmpty) {
        final trimmed = text.trim();
        entities.add(CadTextEntity(entityType: entityType, text: trimmed));
      }
    }

    return entities;
  }

  static String? _textFromEntity(List<(int, String)> pairs) {
    final parts = <String>[];
    for (final pair in pairs) {
      if (pair.$1 == 1 || pair.$1 == 3) {
        parts.add(pair.$2);
      }
    }
    if (parts.isEmpty) return null;
    return parts.join('');
  }

  static List<(int, String)> readPairs(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final pairs = <(int, String)>[];

    for (var i = 0; i + 1 < lines.length; i += 2) {
      final code = int.tryParse(lines[i].trim());
      if (code == null) continue;
      pairs.add((code, lines[i + 1].trim()));
    }

    return pairs;
  }

  static List<DxfSegment> _segmentsFromEntity(
    String entityType,
    List<(int, String)> pairs,
  ) {
    switch (entityType) {
      case 'LINE':
        return [_lineSegment(pairs)];
      case 'LWPOLYLINE':
        return _lwPolylineSegments(pairs);
      default:
        return const [];
    }
  }

  static DxfSegment _lineSegment(List<(int, String)> pairs) {
    final layer = stringValue(pairs, 8, fallback: '0');
    final x1 = doubleValue(pairs, 10);
    final y1 = doubleValue(pairs, 20);
    final z1 = doubleValue(pairs, 30);
    final x2 = doubleValue(pairs, 11);
    final y2 = doubleValue(pairs, 21);
    final z2 = doubleValue(pairs, 31);

    return DxfSegment(
      layerName: layer,
      length: distance(x1, y1, z1, x2, y2, z2),
    );
  }

  static List<DxfSegment> _lwPolylineSegments(List<(int, String)> pairs) {
    final layer = stringValue(pairs, 8, fallback: '0');
    final flags = intValue(pairs, 70);
    final closed = flags != null && (flags & 1) == 1;

    final xs = <double>[];
    final ys = <double>[];
    for (final pair in pairs) {
      if (pair.$1 == 10) {
        xs.add(double.tryParse(pair.$2) ?? 0);
      } else if (pair.$1 == 20 && xs.length > ys.length) {
        ys.add(double.tryParse(pair.$2) ?? 0);
      }
    }

    final pointCount = min(xs.length, ys.length);
    if (pointCount < 2) return const [];

    var total = 0.0;
    for (var i = 1; i < pointCount; i++) {
      total += distance(xs[i - 1], ys[i - 1], 0, xs[i], ys[i], 0);
    }

    if (closed && pointCount > 2) {
      total += distance(
        xs[pointCount - 1],
        ys[pointCount - 1],
        0,
        xs[0],
        ys[0],
        0,
      );
    }

    return [DxfSegment(layerName: layer, length: total)];
  }

  static String _layerFrom(List<(int, String)> pairs, int start) {
    for (var i = start + 1; i < pairs.length; i++) {
      if (pairs[i].$1 == 0) break;
      if (pairs[i].$1 == 8) return pairs[i].$2;
    }
    return '0';
  }

  static double _doubleFrom(List<(int, String)> pairs, int start, int code) {
    for (var i = start + 1; i < pairs.length; i++) {
      if (pairs[i].$1 == 0) break;
      if (pairs[i].$1 == code) {
        return double.tryParse(pairs[i].$2) ?? 0;
      }
    }
    return 0;
  }

  static String stringValue(
    List<(int, String)> pairs,
    int code, {
    required String fallback,
  }) {
    for (final pair in pairs) {
      if (pair.$1 == code) return pair.$2;
    }
    return fallback;
  }

  static double doubleValue(List<(int, String)> pairs, int code) {
    for (final pair in pairs) {
      if (pair.$1 == code) {
        return double.tryParse(pair.$2) ?? 0;
      }
    }
    return 0;
  }

  static int? intValue(List<(int, String)> pairs, int code) {
    for (final pair in pairs) {
      if (pair.$1 == code) {
        return int.tryParse(pair.$2);
      }
    }
    return null;
  }

  static double distance(
    double x1,
    double y1,
    double z1,
    double x2,
    double y2,
    double z2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = z2 - z1;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }
}
