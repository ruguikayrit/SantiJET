import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_tahvil/domain/engine/engine.dart';

BeamTahvilInput _input({
  BeamRegion region = BeamRegion.spanBottom,
  int projectDia = 20,
  int projectCount = 3,
  int newDia = 16,
  int newCount = 5,
  double width = 250,
  double height = 500,
  double stirrupSpacing = 100,
}) {
  return BeamTahvilInput(
    widthMm: width,
    heightMm: height,
    coverMm: 25,
    region: region,
    projectDiameterMm: projectDia,
    projectCount: projectCount,
    newDiameterMm: newDia,
    newCount: newCount,
    stirrupDiameterMm: 8,
    stirrupSpacingMm: 100,
    newStirrupDiameterMm: 8,
    newStirrupSpacingMm: stirrupSpacing,
    stirrupZone: StirrupZone.confinement,
  );
}

void main() {
  const calc = BeamTahvilCalculator();

  test('3Ø20 → 5Ø16 As ve yerleşim sağlanır', () {
    final result = calc.evaluate(_input());
    expect(result.projectAs, closeTo(942.5, 0.5));
    expect(result.newAs, closeTo(1005.3, 0.5));
    expect(result.newAs! + 1e-6, greaterThanOrEqualTo(result.projectAs!));
    expect(
      result.checks.where((c) => c.id == 'placement').single.status,
      CheckStatus.passed,
    );
    expect(result.verdict, isNot(TahvilVerdict.notSuitable));
  });

  test('yetersiz alt donatı uygun değil', () {
    final result = calc.evaluate(_input(newCount: 2));
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'as').single.status,
      CheckStatus.failed,
    );
  });

  test('yetersiz üst donatı uygun değil', () {
    final result = calc.evaluate(
      _input(region: BeamRegion.supportTop, newCount: 2),
    );
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'as').single.status,
      CheckStatus.failed,
    );
  });

  test('kesite sığmayan donatı uygun değil', () {
    final result = calc.evaluate(
      _input(newDia: 20, newCount: 8, width: 200, height: 400),
    );
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'placement').single.status,
      CheckStatus.failed,
    );
  });

  test('etriye aralığı kritik bölgede uygun değil', () {
    final result = calc.evaluate(_input(stirrupSpacing: 300));
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'stirrup').single.status,
      CheckStatus.failed,
    );
  });

  test('mesnet bölgesi mühendis kontrolü üretir', () {
    final result = calc.evaluate(_input(region: BeamRegion.supportTop));
    expect(result.checks.any((c) => c.id == 'region'), isTrue);
    if (result.checks.every((c) => c.status != CheckStatus.failed)) {
      expect(result.verdict, TahvilVerdict.engineerReview);
    }
  });
}
