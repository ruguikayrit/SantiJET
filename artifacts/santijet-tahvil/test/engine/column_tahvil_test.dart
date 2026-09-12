import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_tahvil/domain/engine/engine.dart';

ColumnTahvilInput _input({
  int newDia = 14,
  int newCount = 6,
  double width = 300,
  double height = 300,
  double stirrupSpacing = 100,
  int newStirrupDia = 8,
  bool lap = false,
}) {
  return ColumnTahvilInput(
    widthMm: width,
    heightMm: height,
    storyHeightMm: 3000,
    coverMm: 25,
    projectDiameterMm: 16,
    projectCount: 4,
    newDiameterMm: newDia,
    newCount: newCount,
    stirrupDiameterMm: 8,
    stirrupSpacingMm: 100,
    newStirrupDiameterMm: newStirrupDia,
    newStirrupSpacingMm: stirrupSpacing,
    stirrupZone: StirrupZone.confinement,
    hasLap: lap,
  );
}

void main() {
  const calc = ColumnTahvilCalculator();

  test('4Ø16 → 6Ø14 As yeterli, yerleşir, mühendis kontrolü', () {
    final result = calc.evaluate(_input());
    expect(result.isValid, isTrue);
    expect(result.projectAs, closeTo(804.2, 0.5));
    expect(result.newAs, closeTo(923.6, 0.5));
    expect(result.newAs! + 1e-6, greaterThanOrEqualTo(result.projectAs!));
    expect(
      result.checks.where((c) => c.id == 'as').single.status,
      CheckStatus.passed,
    );
    expect(
      result.checks.where((c) => c.id == 'placement').single.status,
      CheckStatus.passed,
    );
    expect(result.verdict, TahvilVerdict.engineerReview);
    expect(result.checks.any((c) => c.id == 'seismic'), isTrue);
  });

  test('yetersiz As uygun değil', () {
    final result = calc.evaluate(_input(newCount: 4));
    expect(result.newAs! + 1e-6, lessThan(result.projectAs!));
    expect(result.verdict, TahvilVerdict.notSuitable);
  });

  test('fazla donatı oranı uygun değil', () {
    final result = calc.evaluate(
      _input(newDia: 32, newCount: 16, width: 250, height: 250),
    );
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'ratio').single.status,
      CheckStatus.failed,
    );
  });

  test('kesite sığmayan donatı uygun değil', () {
    final result = calc.evaluate(
      _input(newDia: 16, newCount: 16, width: 200, height: 200),
    );
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'placement').single.status,
      CheckStatus.failed,
    );
  });

  test('hatalı etriye aralığı uygun değil', () {
    final result = calc.evaluate(_input(stirrupSpacing: 300));
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'stirrup').single.status,
      CheckStatus.failed,
    );
  });
}
