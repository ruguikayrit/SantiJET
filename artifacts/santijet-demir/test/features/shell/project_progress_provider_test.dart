import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/shell/project_progress_provider.dart';

void main() {
  group('buildProjectProgressRows', () {
    test('lists one row per imalat and diameter with progress-based expected', () {
      const imalats = [
        SurveyImalat(
          id: 'temel',
          name: 'Temel',
          totalTonnage: 100,
          progressPercent: 40,
          diameters: [16, 20],
          diameterLines: [
            DiameterLine(
              diameter: 16,
              planned: 60,
              ordered: 0,
              delivered: 0,
              progressPercent: 40,
            ),
            DiameterLine(
              diameter: 20,
              planned: 40,
              ordered: 0,
              delivered: 0,
              progressPercent: 50,
            ),
          ],
          planned: 100,
          ordered: 0,
          delivered: 0,
          pending: 0,
        ),
        SurveyImalat(
          id: 'perde',
          name: 'Perde',
          totalTonnage: 200,
          progressPercent: 25,
          diameters: [16],
          diameterLines: [
            DiameterLine(
              diameter: 16,
              planned: 200,
              ordered: 0,
              delivered: 0,
              progressPercent: 25,
            ),
          ],
          planned: 200,
          ordered: 0,
          delivered: 0,
          pending: 0,
        ),
      ];

      final rows = buildProjectProgressRows(imalats);

      expect(rows, hasLength(3));
      expect(rows[0].imalatName, 'Temel');
      expect(rows[0].diameter, 16);
      expect(rows[0].expectedTonnage, closeTo(24, 0.001));
      expect(rows[1].imalatName, 'Temel');
      expect(rows[1].diameter, 20);
      expect(rows[1].expectedTonnage, closeTo(20, 0.001));
      expect(rows[2].imalatName, 'Perde');
      expect(rows[2].diameter, 16);
      expect(rows[2].expectedTonnage, closeTo(50, 0.001));
    });

    test('overall progress is total expected divided by total survey tonnage', () {
      final project = SurveyProject(
        projectName: 'Test',
        date: DateTime(2026, 1, 1),
        revision: 'A',
        imalats: [
          SurveyImalat(
            id: 'temel',
            name: 'Temel',
            totalTonnage: 100,
            progressPercent: 40,
            diameters: [16],
            diameterLines: [
              DiameterLine(
                diameter: 16,
                planned: 60,
                ordered: 0,
                delivered: 0,
                progressPercent: 40,
              ),
            ],
            planned: 100,
            ordered: 0,
            delivered: 0,
            pending: 0,
          ),
        ],
      );

      final rows = buildProjectProgressRows(project.imalats);
      final totalExpected =
          rows.fold(0.0, (sum, row) => sum + row.expectedTonnage);
      final summary = ProjectProgressSummary(
        rows: rows,
        totalPlanned: project.totalPlanned,
        totalExpected: totalExpected,
      );

      expect(summary.totalExpected, closeTo(24, 0.001));
      expect(summary.totalPlanned, 100);
      expect(summary.overallProgressPercent, closeTo(24, 0.001));
    });

    test('aggregate planned usage matches sum of row beklenen by diameter', () {
      const imalats = [
        SurveyImalat(
          id: 'temel',
          name: 'Temel',
          totalTonnage: 100,
          progressPercent: 40,
          diameters: [16, 20],
          diameterLines: [
            DiameterLine(
              diameter: 16,
              planned: 60,
              ordered: 0,
              delivered: 0,
              progressPercent: 40,
            ),
            DiameterLine(
              diameter: 20,
              planned: 40,
              ordered: 0,
              delivered: 0,
              progressPercent: 50,
            ),
          ],
          planned: 100,
          ordered: 0,
          delivered: 0,
          pending: 0,
        ),
        SurveyImalat(
          id: 'perde',
          name: 'Perde',
          totalTonnage: 200,
          progressPercent: 25,
          diameters: [16],
          diameterLines: [
            DiameterLine(
              diameter: 16,
              planned: 200,
              ordered: 0,
              delivered: 0,
              progressPercent: 25,
            ),
          ],
          planned: 200,
          ordered: 0,
          delivered: 0,
          pending: 0,
        ),
      ];

      final rows = buildProjectProgressRows(imalats);
      final aggregated = aggregatePlannedUsageByDiameter(rows);

      expect(aggregated[16], closeTo(24 + 50, 0.001));
      expect(aggregated[20], closeTo(20, 0.001));
    });
  });
}
