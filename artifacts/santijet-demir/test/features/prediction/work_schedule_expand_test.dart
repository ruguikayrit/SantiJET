import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';

void main() {
  test('expands imalat date range into daily planned tonnage', () {
    final survey = SurveyProject(
      projectName: 'T',
      date: DateTime(2026, 7, 1),
      revision: '1',
      imalats: [
        SurveyImalat(
          id: 'i1',
          name: 'KİRİŞ',
          totalTonnage: 10,
          progressPercent: 0,
          diameters: const [16],
          diameterLines: const [
            DiameterLine(
              diameter: 16,
              planned: 10,
              ordered: 0,
              delivered: 0,
              progressPercent: 0,
            ),
          ],
          planned: 10,
          ordered: 0,
          delivered: 0,
          pending: 0,
        ),
      ],
    );

    final days = expandWorkScheduleToDays(
      items: [
        WorkScheduleImalat(
          id: 'ws1',
          imalatId: 'i1',
          imalatName: 'KİRİŞ',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 5),
        ),
      ],
      survey: survey,
    );

    expect(days, hasLength(5));
    expect(days.first.totalPlannedTonnage, closeTo(2.0, 1e-9));
    expect(days.last.date, DateTime(2026, 7, 5));
  });

  test('formats duration inclusive of start and end', () {
    final item = WorkScheduleImalat(
      id: 'ws1',
      imalatId: 'i1',
      imalatName: 'PERDE',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 10),
    );
    expect(item.durationDays, 10);
  });
}
