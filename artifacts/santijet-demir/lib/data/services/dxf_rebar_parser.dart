import 'package:santijet_demir/data/services/cad_text_entity.dart';
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
    final entities = await DwgTextExtractor.extract(bytes);
    return _buildResultFromEntities(
      fileName: fileName,
      sourceFormat: 'DWG',
      entities: entities,
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
    final entities = DxfAsciiParser.parseAllTextEntities(content);
    return _buildResultFromEntities(
      fileName: fileName,
      sourceFormat: sourceFormat,
      entities: entities,
    );
  }

  RebarMetrajResult _buildResultFromEntities({
    required String fileName,
    required String sourceFormat,
    required List<CadTextEntity> entities,
  }) {
    final warnings = <String>[];
    final grouped = <int, _DiameterAccumulator>{};
    final textDetails = <RebarMetrajTextDetail>[];

    if (entities.isEmpty) {
      warnings.add(
        'CAD dosyasında TEXT/MTEXT bulunamadı. Demir etiketlerinin '
        'metin olarak çizimde yer aldığından emin olun.',
      );
    }

    for (final entity in entities) {
      final parsed = textParser.parseOne(entity.text);
      if (parsed == null) continue;

      final scaledLength = parsed.lengthM * settings.unitScale;
      final weightKg = RebarWeightCalculator.weightKg(
        diameterMm: parsed.diameter,
        lengthM: scaledLength,
      );

      textDetails.add(
        RebarMetrajTextDetail(
          entityType: entity.entityType,
          sourceText: entity.text,
          included: true,
          diameter: parsed.diameter,
          lengthM: scaledLength,
          quantity: parsed.quantity,
          weightKg: weightKg * parsed.quantity,
        ),
      );

      grouped.putIfAbsent(parsed.diameter, () => _DiameterAccumulator());
      grouped[parsed.diameter]!.addBars(
        lengthM: scaledLength,
        count: parsed.quantity,
        label: parsed.sourceText,
      );
    }

    if (entities.isNotEmpty && grouped.isEmpty) {
      final samples = entities
          .take(5)
          .map((entity) {
            final text = entity.text.trim();
            if (text.length <= 64) return text;
            return '${text.substring(0, 64)}…';
          })
          .join('\n• ');

      warnings.add(
        'Demir etiketi bulunamadı. Örnek formatlar:\n'
        'üst.334Ø22/15 l=120 (334 ad × 12 m)\n'
        '15000Ø16 l=200 (15000 ad × 2 m)',
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
      textDetails: textDetails,
      skippedEntityCount: entities.length - textDetails.length,
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
