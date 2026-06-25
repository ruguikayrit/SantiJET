import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

class DxfRebarParser {
  const DxfRebarParser({this.settings = const RebarMetrajSettings()});

  final RebarMetrajSettings settings;

  static const dwgUnsupportedMessage =
      'DWG dosyaları doğrudan okunamaz. AutoCAD/BricsCAD ile DXF olarak '
      'kaydedin veya yakında eklenecek sunucu dönüşümünü kullanın.';

  RebarMetrajResult parseBytes({
    required String fileName,
    required List<int> bytes,
    String sourceFormat = 'DXF',
  }) {
    if (DxfAsciiParser.isBinaryDxf(bytes)) {
      throw FormatException(DxfAsciiParser.binaryDxfMessage);
    }

    final content = DxfAsciiParser.decodeContent(bytes);
    return parse(
      fileName: fileName,
      content: content,
      sourceFormat: sourceFormat,
    );
  }

  RebarMetrajResult parse({
    required String fileName,
    required String content,
    String sourceFormat = 'DXF',
  }) {
    final warnings = <String>[];
    final grouped = <String, _LayerAccumulator>{};
    var skipped = 0;

    final segments = DxfAsciiParser.parseAllSegments(content);
    if (segments.isEmpty) {
      warnings.add(
        'DXF dosyasında LINE veya POLYLINE bulunamadı. Çizimde demir '
        'elemanlarının çizgi/polyline olarak yer aldığından emin olun.',
      );
    }

    for (final segment in segments) {
      if (!_isRebarLayer(segment.layerName)) {
        skipped++;
        continue;
      }

      if (segment.length <= 0) {
        skipped++;
        continue;
      }

      final scaledLength = segment.length * settings.unitScale;
      final diameter =
          _resolveDiameter(segment.layerName) ?? settings.defaultDiameter;
      final key = '${segment.layerName.toUpperCase()}|$diameter';
      grouped.putIfAbsent(
        key,
        () => _LayerAccumulator(
          layerName: segment.layerName,
          diameter: diameter,
        ),
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
      if (value != null &&
          RebarWeightCalculator.standardDiameters.contains(value)) {
        return value;
      }
    }

    final embedded = RegExp(r'(\d{2})').allMatches(normalized);
    for (final match in embedded) {
      final value = int.tryParse(match.group(1)!);
      if (value != null &&
          RebarWeightCalculator.standardDiameters.contains(value)) {
        return value;
      }
    }

    return null;
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
