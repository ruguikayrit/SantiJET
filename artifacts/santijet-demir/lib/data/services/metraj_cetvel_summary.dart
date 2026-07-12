import 'package:santijet_demir/data/services/element_header_parser.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

/// Çap bazlı metraj icmali (tüm okunan etiketler).
class MetrajIcmaliSummary {
  const MetrajIcmaliSummary({
    required this.totalTonnage,
    required this.thinTonnage,
    required this.thickTonnage,
    required this.totalLengthM,
    required this.totalBarCount,
    required this.lines,
  });

  final double totalTonnage;
  final double thinTonnage;
  final double thickTonnage;
  final double totalLengthM;
  final int totalBarCount;
  final List<RebarMetrajLine> lines;
}

/// Eleman tipi bazlı icmal satırı (cetvelden).
class MetrajIcmaliTypeRow {
  const MetrajIcmaliTypeRow({
    required this.typeLabel,
    required this.elementCount,
    required this.tonnage,
    required this.barCount,
  });

  final String typeLabel;
  final int elementCount;
  final double tonnage;
  final int barCount;
}

MetrajIcmaliSummary summarizeLines(List<RebarMetrajLine> lines) {
  final sorted = List<RebarMetrajLine>.from(lines)
    ..sort((a, b) => a.diameter.compareTo(b.diameter));

  var thinTonnage = 0.0;
  var thickTonnage = 0.0;
  var totalLengthM = 0.0;
  var totalBarCount = 0;
  var totalWeightKg = 0.0;

  for (final line in sorted) {
    totalLengthM += line.totalLengthM;
    totalBarCount += line.barCount;
    totalWeightKg += line.weightKg;
    if (line.diameter <= 12) {
      thinTonnage += line.tonnage;
    } else {
      thickTonnage += line.tonnage;
    }
  }

  return MetrajIcmaliSummary(
    totalTonnage: totalWeightKg / 1000,
    thinTonnage: thinTonnage,
    thickTonnage: thickTonnage,
    totalLengthM: totalLengthM,
    totalBarCount: totalBarCount,
    lines: sorted,
  );
}

List<MetrajIcmaliTypeRow> summarizeCetvelByType(List<MetrajCetvelEntry> entries) {
  final grouped = <StructuralElementType, List<MetrajCetvelEntry>>{};
  for (final entry in entries) {
    final type = StructuralElementType.fromLetter(entry.elementTypeCode);
    grouped.putIfAbsent(type, () => []).add(entry);
  }

  return grouped.entries
      .map(
        (entry) => MetrajIcmaliTypeRow(
          typeLabel: entry.key.label,
          elementCount: entry.value.length,
          tonnage: entry.value.fold(0.0, (sum, item) => sum + item.totalTonnage),
          barCount: entry.value.fold(0, (sum, item) => sum + item.totalBarCount),
        ),
      )
      .toList()
    ..sort((a, b) => a.typeLabel.compareTo(b.typeLabel));
}

/// Metraj cetveli özet satırları (Excel cetveli alt toplamları).
class MetrajCetvelSummary {
  const MetrajCetvelSummary({
    required this.totalTonnage,
    required this.thinTonnage,
    required this.thickTonnage,
    required this.totalLengthM,
    required this.elementCount,
    required this.rowCount,
    required this.tonnageByDiameter,
  });

  final double totalTonnage;
  final double thinTonnage;
  final double thickTonnage;
  final double totalLengthM;
  final int elementCount;
  final int rowCount;
  final Map<int, double> tonnageByDiameter;

  factory MetrajCetvelSummary.fromEntries(List<MetrajCetvelEntry> entries) {
    final tonnageByDiameter = <int, double>{};
    var totalTonnage = 0.0;
    var thinTonnage = 0.0;
    var thickTonnage = 0.0;
    var totalLengthM = 0.0;
    var rowCount = 0;

    for (final entry in entries) {
      totalTonnage += entry.totalTonnage;
      totalLengthM += entry.totalLengthM;
      rowCount += entry.rows.length;

      for (final row in entry.rows) {
        tonnageByDiameter[row.diameter] =
            (tonnageByDiameter[row.diameter] ?? 0) + row.totalTonnage;
        if (row.diameter <= 12) {
          thinTonnage += row.totalTonnage;
        } else {
          thickTonnage += row.totalTonnage;
        }
      }
    }

    return MetrajCetvelSummary(
      totalTonnage: totalTonnage,
      thinTonnage: thinTonnage,
      thickTonnage: thickTonnage,
      totalLengthM: totalLengthM,
      elementCount: entries.length,
      rowCount: rowCount,
      tonnageByDiameter: tonnageByDiameter,
    );
  }
}

MetrajCetvelSummary summarizeCetvel(List<MetrajCetvelEntry> entries) {
  return MetrajCetvelSummary.fromEntries(entries);
}
