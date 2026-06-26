import 'package:santijet_demir/data/services/dwg_text_extractor.dart';
import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

class DxfRebarParser {
  const DxfRebarParser({
    this.settings = const RebarMetrajSettings(),
    this.textParser = const RebarTextParser(),
  });

  final RebarMetrajSettings settings;
  final RebarTextParser textParser;

  static bool isDwgBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    final header = String.fromCharCodes(bytes.take(4));
    return header == 'AC10' || header.startsWith('AC1');
  }

  Future<RebarMetrajResult> parseDwgBytes({
    required String fileName,
    required List<int> bytes,
  }) async {
    final texts = await DwgTextExtractor.extract(bytes);
    return _buildResultFromTexts(
      fileName: fileName,
      sourceFormat: 'DWG',
      texts: texts,
    );
  }

  RebarMetrajResult parseBytes({
    required String fileName,
    required List<int> bytes,
    String sourceFormat = 'DXF',
  }) {
    if (isDwgBytes(bytes)) {
      throw FormatException(
        'DWG algılandı. Lütfen dosyayı .dwg uzantısıyla yükleyin.',
      );
    }

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
    final texts = DxfAsciiParser.parseAllTexts(content);
    return _buildResultFromTexts(
      fileName: fileName,
      sourceFormat: sourceFormat,
      texts: texts,
    );
  }

  RebarMetrajResult _buildResultFromTexts({
    required String fileName,
    required String sourceFormat,
    required List<String> texts,
  }) {
    final warnings = <String>[];
    final grouped = <int, _DiameterAccumulator>{};
    var skipped = 0;

    if (texts.isEmpty) {
      warnings.add(
        'CAD dosyasında TEXT/MTEXT bulunamadı. Demir etiketlerinin '
        'metin olarak çizimde yer aldığından emin olun.',
      );
    }

    final entries = textParser.parseAll(texts);
    skipped = texts.length - entries.length;

    if (texts.isNotEmpty && entries.isEmpty) {
      warnings.add(
        'Metin bulundu ancak çap ve boy birlikte okunamadı. '
        'Örnek format: Ø12/350, 12Ø350, 5xØ16/450',
      );
    }

    for (final entry in entries) {
      final scaledLength = entry.lengthM * settings.unitScale;
      grouped.putIfAbsent(entry.diameter, () => _DiameterAccumulator());
      grouped[entry.diameter]!.addBars(
        lengthM: scaledLength,
        count: entry.quantity,
        label: entry.sourceText,
      );
    }

    final lines = grouped.entries
        .map(
          (entry) => RebarMetrajLine(
            diameter: entry.key,
            totalLengthM: entry.value.totalLengthM,
            weightKg: RebarWeightCalculator.weightKg(
              diameterMm: entry.key,
              lengthM: entry.value.totalLengthM,
            ),
            barCount: entry.value.barCount,
            layerName: entry.value.sampleLabel,
          ),
        )
        .toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));

    return RebarMetrajResult(
      fileName: fileName,
      sourceFormat: sourceFormat,
      parsedAt: DateTime.now(),
      lines: lines,
      skippedEntityCount: skipped,
      warnings: warnings,
    );
  }
}

class _DiameterAccumulator {
  double totalLengthM = 0;
  int barCount = 0;
  String sampleLabel = '';

  void addBars({
    required double lengthM,
    required int count,
    required String label,
  }) {
    totalLengthM += lengthM * count;
    barCount += count;
    if (sampleLabel.isEmpty) {
      sampleLabel = label.length > 48 ? '${label.substring(0, 48)}…' : label;
    }
  }
}
