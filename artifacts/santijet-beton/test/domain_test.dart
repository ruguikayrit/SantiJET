import 'package:flutter_test/flutter_test.dart';

import 'package:santijet_beton/domain/entities/pour_plan.dart';
import 'package:santijet_beton/domain/entities/quality_sample.dart';

void main() {
  test('PourPlanStatus labels are Turkish', () {
    expect(PourPlanStatus.planned.label, 'Planlandı');
    expect(PourPlanStatus.completed.label, 'Tamamlandı');
  });

  test('QualitySample pending when strength missing', () {
    const sample = QualitySample(
      id: '1',
      projectId: 'p',
      sampleDate: '01.01.2026',
      sampleCode: 'N-1',
    );
    expect(sample.isPending, isTrue);
  });
}
