import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_tahvil/domain/engine/engine.dart';

SlabTahvilInput _input({
  int newDia = 8,
  double newSpacingMm = 125,
  double thicknessMm = 150,
  double coverMm = 20,
}) {
  return SlabTahvilInput(
    thicknessMm: thicknessMm,
    coverMm: coverMm,
    projectDiameterMm: 10,
    projectSpacingMm: 200,
    newDiameterMm: newDia,
    newSpacingMm: newSpacingMm,
    layer: RebarLayer.bottom,
    direction: RebarDirection.x,
  );
}

void main() {
  const calc = SlabTahvilCalculator();

  test('Ø10/20 → Ø8/12,5 As/m ve kontroller', () {
    final result = calc.evaluate(_input());
    expect(result.isValid, isTrue);
    expect(result.projectAs, closeTo(392.7, 0.2));
    expect(result.newAs, closeTo(402.1, 0.2));
    expect(result.asDelta, closeTo(9.4, 0.3));
    expect(result.asDeltaPercent, closeTo(2.4, 0.2));
    expect(result.verdict, TahvilVerdict.suitable);
  });

  test('yetersiz As/m uygun değil', () {
    final result = calc.evaluate(_input(newDia: 8, newSpacingMm: 250));
    expect(result.newAs! + 1e-6, lessThan(result.projectAs!));
    expect(result.verdict, TahvilVerdict.notSuitable);
  });

  test('maksimum aralık aşımı uygun değil', () {
    final result = calc.evaluate(_input(newDia: 16, newSpacingMm: 300));
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'max_spacing').single.status,
      CheckStatus.failed,
    );
  });

  test('minimum donatı ihlali uygun değil', () {
    final result = calc.evaluate(
      _input(newDia: 8, newSpacingMm: 200, thicknessMm: 400, coverMm: 20),
    );
    expect(
      result.checks.where((c) => c.id == 'min_rebar').single.status,
      CheckStatus.failed,
    );
    expect(result.verdict, TahvilVerdict.notSuitable);
  });
}
