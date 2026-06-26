import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';

/// Metraj satırlarını keşif imalatına dönüştürür.
class RebarSurveyMapper {
  const RebarSurveyMapper._();

  static SurveyImalat createImalatFromMetraj({
    required String id,
    required String name,
    required List<RebarMetrajLine> lines,
  }) {
    final diameterLines = _linesToDiameterLines(lines, replace: true);
    return _buildImalat(id: id, name: name, diameterLines: diameterLines);
  }

  static SurveyImalat applyMetrajToImalat({
    required SurveyImalat imalat,
    required List<RebarMetrajLine> lines,
    required bool replaceExisting,
  }) {
    final diameterLines = _mergeDiameterLines(
      existing: imalat.diameterLines,
      metrajLines: lines,
      replaceExisting: replaceExisting,
    );
    return _buildImalat(
      id: imalat.id,
      name: imalat.name,
      diameterLines: diameterLines,
      ordered: imalat.ordered,
      delivered: imalat.delivered,
      progressPercent: imalat.progressPercent,
    );
  }

  static List<DiameterLine> _linesToDiameterLines(
    List<RebarMetrajLine> lines, {
    required bool replace,
  }) {
    return _mergeDiameterLines(
      existing: const [],
      metrajLines: lines,
      replaceExisting: replace,
    );
  }

  static List<DiameterLine> _mergeDiameterLines({
    required List<DiameterLine> existing,
    required List<RebarMetrajLine> metrajLines,
    required bool replaceExisting,
  }) {
    final merged = <int, DiameterLine>{
      for (final line in existing) line.diameter: line,
    };

    for (final metrajLine in metrajLines) {
      final current = merged[metrajLine.diameter];
      final planned = replaceExisting
          ? metrajLine.tonnage
          : (current?.planned ?? 0) + metrajLine.tonnage;
      merged[metrajLine.diameter] = DiameterLine(
        diameter: metrajLine.diameter,
        planned: planned,
        ordered: current?.ordered ?? 0,
        delivered: current?.delivered ?? 0,
      );
    }

    return merged.values.toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));
  }

  static SurveyImalat _buildImalat({
    required String id,
    required String name,
    required List<DiameterLine> diameterLines,
    double ordered = 0,
    double delivered = 0,
    double? progressPercent,
  }) {
    final planned = diameterLines.fold(0.0, (sum, line) => sum + line.planned);
    final pending = (ordered - delivered).clamp(0, double.infinity);
    final progress = progressPercent ??
        (planned > 0 ? (delivered / planned * 100).clamp(0, 100) : 0);

    return SurveyImalat(
      id: id,
      name: name,
      totalTonnage: planned,
      progressPercent: progress,
      diameters: diameterLines.map((line) => line.diameter).toList(),
      diameterLines: diameterLines,
      planned: planned,
      ordered: ordered,
      delivered: delivered,
      pending: pending,
    );
  }

  static String slugifyImalatId(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[çÇ]'), 'c')
        .replaceAll(RegExp(r'[ğĞ]'), 'g')
        .replaceAll(RegExp(r'[ıİ]'), 'i')
        .replaceAll(RegExp(r'[öÖ]'), 'o')
        .replaceAll(RegExp(r'[şŞ]'), 's')
        .replaceAll(RegExp(r'[üÜ]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (normalized.isEmpty) {
      return 'imalat-${DateTime.now().millisecondsSinceEpoch}';
    }
    return normalized;
  }
}
