import 'package:equatable/equatable.dart';

class RebarMetrajLine extends Equatable {
  const RebarMetrajLine({
    required this.diameter,
    required this.totalLengthM,
    required this.weightKg,
    required this.barCount,
    required this.layerName,
  });

  final int diameter;
  final double totalLengthM;
  final double weightKg;
  final int barCount;
  final String layerName;

  double get tonnage => weightKg / 1000;

  @override
  List<Object?> get props =>
      [diameter, totalLengthM, weightKg, barCount, layerName];
}

class RebarMetrajResult extends Equatable {
  const RebarMetrajResult({
    required this.fileName,
    required this.sourceFormat,
    required this.parsedAt,
    required this.lines,
    required this.skippedEntityCount,
    required this.warnings,
  });

  final String fileName;
  final String sourceFormat;
  final DateTime parsedAt;
  final List<RebarMetrajLine> lines;
  final int skippedEntityCount;
  final List<String> warnings;

  double get totalLengthM =>
      lines.fold(0, (sum, line) => sum + line.totalLengthM);

  double get totalWeightKg =>
      lines.fold(0, (sum, line) => sum + line.weightKg);

  double get totalTonnage => totalWeightKg / 1000;

  int get totalBarCount => lines.fold(0, (sum, line) => sum + line.barCount);

  @override
  List<Object?> get props => [
        fileName,
        sourceFormat,
        parsedAt,
        lines,
        skippedEntityCount,
        warnings,
      ];
}

class RebarLayerRule extends Equatable {
  const RebarLayerRule({
    required this.layerPattern,
    this.defaultDiameter,
  });

  final String layerPattern;
  final int? defaultDiameter;

  @override
  List<Object?> get props => [layerPattern, defaultDiameter];
}

class RebarMetrajSettings extends Equatable {
  const RebarMetrajSettings({
    this.layerKeywords = const [
      'DONAT',
      'DONATI',
      'ARMAT',
      'ARMATUR',
      'DEMIR',
      'DEMİR',
      'REBAR',
      'CELİK',
      'CELIK',
      'STEEL',
    ],
    this.defaultDiameter = 12,
    this.unitScale = 1.0,
  });

  final List<String> layerKeywords;
  final int defaultDiameter;
  final double unitScale;

  @override
  List<Object?> get props => [layerKeywords, defaultDiameter, unitScale];
}
