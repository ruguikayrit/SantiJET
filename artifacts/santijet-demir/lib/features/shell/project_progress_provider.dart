import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class ProjectProgressRow {
  const ProjectProgressRow({
    required this.imalatId,
    required this.imalatName,
    required this.diameter,
    required this.plannedTonnage,
    required this.progressPercent,
  });

  final String imalatId;
  final String imalatName;
  final int? diameter;
  final double plannedTonnage;
  final double progressPercent;

  double get expectedTonnage => computeLinePlannedUsage(
        planned: plannedTonnage,
        progressPercent: progressPercent,
      );
}

/// Ana sayfa ilerleme satırlarından çap bazında planlanan kullanım toplamı.
/// Yeni sayım tablosundaki BEKLENEN sütunu bu değerden türetilir.
Map<int, double> aggregatePlannedUsageByDiameter(List<ProjectProgressRow> rows) {
  final totals = <int, double>{};

  for (final row in rows) {
    final diameter = row.diameter;
    if (diameter == null) continue;
    totals[diameter] = (totals[diameter] ?? 0) + row.expectedTonnage;
  }

  return totals;
}

class ProjectProgressSummary {
  const ProjectProgressSummary({
    required this.rows,
    required this.totalPlanned,
    required this.totalExpected,
  });

  final List<ProjectProgressRow> rows;
  final double totalPlanned;
  final double totalExpected;

  double get overallProgressPercent =>
      totalPlanned > 0 ? totalExpected / totalPlanned * 100 : 0;
}

List<ProjectProgressRow> buildProjectProgressRows(List<SurveyImalat> imalats) {
  final rows = <ProjectProgressRow>[];

  for (final imalat in imalats) {
    if (imalat.diameterLines.isEmpty) {
      if (imalat.planned <= 0) continue;
      rows.add(
        ProjectProgressRow(
          imalatId: imalat.id,
          imalatName: imalat.name,
          diameter: null,
          plannedTonnage: imalat.planned,
          progressPercent: imalat.progressPercent,
        ),
      );
      continue;
    }

    for (final line in imalat.diameterLines) {
      if (line.planned <= 0) continue;
      rows.add(
        ProjectProgressRow(
          imalatId: imalat.id,
          imalatName: imalat.name,
          diameter: line.diameter,
          plannedTonnage: line.planned,
          progressPercent: line.progressPercent,
        ),
      );
    }
  }

  return rows;
}

final projectProgressSummaryProvider = Provider<ProjectProgressSummary>((ref) {
  final project = ref.watch(surveyProjectProvider);
  final rows = buildProjectProgressRows(project.imalats);
  final totalExpected =
      rows.fold(0.0, (sum, row) => sum + row.expectedTonnage);

  return ProjectProgressSummary(
    rows: rows,
    totalPlanned: project.totalPlanned,
    totalExpected: totalExpected,
  );
});
