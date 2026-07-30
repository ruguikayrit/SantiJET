import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_beton_r1/domain/entities/pour_plan.dart';
import 'package:santijet_beton_r1/domain/entities/quality_sample.dart';

void main() {
  test('PourPlanStatus Turkish labels', () {
    expect(PourPlanStatus.planned.label, 'Planlandı');
  });

  test('QualitySample pending without strength', () {
    const s = QualitySample(
      id: '1',
      projectId: 'p',
      sampleDate: '01.01.2026',
      sampleCode: 'N-1',
    );
    expect(s.isPending, isTrue);
  });
}
