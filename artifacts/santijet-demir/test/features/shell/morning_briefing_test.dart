import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';
import 'package:santijet_demir/features/shell/morning_briefing.dart';

void main() {
  const builder = MorningBriefingBuilder();

  test('sabah selamı ve planlı tüketim', () {
    final briefing = builder.build(
      now: DateTime(2026, 7, 19, 8),
      displayName: 'Uğur Yılmaz',
      todaySchedule: WorkScheduleDay(
        date: DateTime(2026, 7, 19),
        activities: [
          WorkActivity(
            id: '1',
            imalatName: 'KİRİŞ',
            plannedTonnageByDiameter: const {16: 8.2},
          ),
        ],
      ),
      reconciliation: const [],
    );

    expect(briefing.greetingLine, 'Günaydın Uğur');
    expect(
      briefing.bullets.any((b) => b.contains('8.2') || b.contains('8,2')),
      isTrue,
    );
    expect(briefing.bullets.any((b) => b.contains('teslimat')), isTrue);
    expect(
      briefing.bullets.any((b) => b.toLowerCase().contains('fire')),
      isTrue,
    );
  });

  test('stok yeterli ve sipariş önerisi', () {
    final briefing = builder.build(
      now: DateTime(2026, 7, 19, 9),
      displayName: 'Uğur',
      snapshot: PredictionSnapshot(
        id: 't1',
        projectId: 'p1',
        createdAt: DateTime(2026, 7, 19),
        dataGaps: const [],
        canPredict: true,
        diameters: const [
          DiameterPrediction(
            diameter: 16,
            currentStock: 40,
            actualDailyConsumption: 3,
            plannedDailyConsumption: 3,
            daysRemaining: 13,
            remainingRequirement: 10,
            inTransit: 0,
            recommendedPurchase: 0,
            risk: PredictionRiskLevel.green,
          ),
          DiameterPrediction(
            diameter: 12,
            currentStock: 8,
            actualDailyConsumption: 2,
            plannedDailyConsumption: 2,
            daysRemaining: 4,
            remainingRequirement: 20,
            inTransit: 0,
            recommendedPurchase: 12,
            risk: PredictionRiskLevel.orange,
          ),
        ],
        purchase: const PurchaseRecommendation(
          totalRequired: 12,
          byDiameter: {12: 12},
          requiredPurchaseDate: null,
          supplierLeadDays: 5,
        ),
      ),
    );

    expect(
      briefing.bullets.any((b) => b.contains('Ø16') && b.contains('13')),
      isTrue,
    );
    expect(
      briefing.bullets.any((b) => b.contains('Ø12') && b.contains('sipariş')),
      isTrue,
    );
  });

  test('fire riski düşük / yüksek', () {
    final low = builder.build(
      now: DateTime(2026, 7, 19),
      displayName: 'Ali',
      reconciliation: const [
        ReconciliationRow(
          diameter: 16,
          survey: 100,
          ordered: 80,
          delivered: 80,
          plannedUsage: 40,
          expectedStock: 40,
          counted: 40,
          used: 40,
        ),
      ],
    );
    expect(low.bullets.any((b) => b.contains('Fire riski düşük')), isTrue);

    final high = builder.build(
      now: DateTime(2026, 7, 19),
      displayName: 'Ali',
      reconciliation: const [
        ReconciliationRow(
          diameter: 14,
          survey: 100,
          ordered: 80,
          delivered: 80,
          plannedUsage: 40,
          expectedStock: 40,
          counted: 30,
          used: 50,
        ),
      ],
    );
    expect(
      high.bullets.any((b) => b.contains('Ø14') && b.contains('fire')),
      isTrue,
    );
  });
}
