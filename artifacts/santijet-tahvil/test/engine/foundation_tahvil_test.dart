import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_tahvil/domain/engine/engine.dart';

FoundationTahvilInput _input({
  double spacingMm = 150,
  int newDia = 12,
  double newSpacingMm = 150,
  bool anchorage = false,
  double thicknessMm = 300,
  double coverMm = 50,
}) {
  return FoundationTahvilInput(
    kind: FoundationKind.raft,
    widthMm: 2000,
    lengthMm: 2000,
    thicknessMm: thicknessMm,
    coverMm: coverMm,
    projectDiameterMm: 12,
    projectSpacingMm: spacingMm,
    newDiameterMm: newDia,
    newSpacingMm: newSpacingMm,
    layer: RebarLayer.bottom,
    direction: RebarDirection.x,
    includeAnchorageReview: anchorage,
  );
}

void main() {
  const calc = FoundationTahvilCalculator();

  test('aynı donatı aynı As ve uygunluk üretir', () {
    final result = calc.evaluate(_input());
    expect(result.isValid, isTrue);
    expect(result.projectAs, closeTo(result.newAs!, 1e-6));
    expect(result.verdict, TahvilVerdict.suitable);
    expect(result.checks.any((c) => c.id == 'as'), isTrue);
  });

  test('daha fazla As uygun', () {
    final result = calc.evaluate(_input(newDia: 14, newSpacingMm: 150));
    expect(result.newAs! + 1e-6, greaterThanOrEqualTo(result.projectAs!));
    expect(result.verdict, TahvilVerdict.suitable);
  });

  test('daha az As uygun değil', () {
    final result = calc.evaluate(_input(newDia: 10, newSpacingMm: 200));
    expect(result.newAs! + 1e-6, lessThan(result.projectAs!));
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'as').single.status,
      CheckStatus.failed,
    );
  });

  test('aralık sınırı aşımı uygun değil', () {
    final result = calc.evaluate(_input(newDia: 16, newSpacingMm: 300));
    expect(result.verdict, TahvilVerdict.notSuitable);
    expect(
      result.checks.where((c) => c.id == 'max_spacing').single.status,
      CheckStatus.failed,
    );
  });

  test('kenetlenme uyarısı mühendis kontrolü üretir', () {
    final result = calc.evaluate(_input(anchorage: true));
    expect(result.verdict, TahvilVerdict.engineerReview);
  });
}
