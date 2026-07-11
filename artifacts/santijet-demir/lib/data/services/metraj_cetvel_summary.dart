import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

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
