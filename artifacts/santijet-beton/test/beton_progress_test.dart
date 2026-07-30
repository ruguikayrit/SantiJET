import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_beton/domain/beton_progress.dart';

void main() {
  test('keşif ilerleme yüzdesi', () {
    expect(
      BetonProgress.progressPercent(plannedM3: 100, pouredM3: 42),
      42,
    );
    expect(
      BetonProgress.progressPercent(plannedM3: 0, pouredM3: 0),
      0,
    );
  });

  test('sipariş farkı', () {
    expect(
      BetonProgress.orderGap(orderedM3: 50, pouredM3: 42),
      -8,
    );
  });
}
