import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';

void main() {
  const parser = RebarTextParser();

  group('üst/alt formatı — adet doğrudan, aralık etkisiz', () {
    test('üst.334Ø22/15 l=1200 → 334 ad × 12 m', () {
      final entry = parser.parseOne('üst.334Ø22/15 l=1200');
      expect(entry?.quantity, 334);
      expect(entry?.diameter, 22);
      expect(entry?.lengthM, closeTo(12, 0.001));
      expect(entry!.quantity * entry.lengthM, closeTo(4008, 0.001));
    });

    test('üst.334Ø22/15 l=695 → 334 ad × 6,95 m', () {
      final entry = parser.parseOne('üst.334Ø22/15 l=695');
      expect(entry?.quantity, 334);
      expect(entry?.lengthM, closeTo(6.95, 0.001));
    });

    test('üst.180Ø22/15 l=805 → 180 ad × 8,05 m', () {
      final entry = parser.parseOne('üst.180Ø22/15 l=805');
      expect(entry?.quantity, 180);
      expect(entry?.lengthM, closeTo(8.05, 0.001));
    });

    test('üst.334Ø22/15 l=120 → 334 ad × 1,2 m (120 cm)', () {
      final entry = parser.parseOne('üst.334Ø22/15 l=120');
      expect(entry?.quantity, 334);
      expect(entry?.lengthM, closeTo(1.2, 0.001));
    });

    test('aralık (/15) adeti değiştirmez', () {
      final withSpacing = parser.parseOne('üst.334Ø22/15 l=1200');
      final withoutSpacing = parser.parseOne('üst.334Ø22/20 l=1200');
      expect(withSpacing?.quantity, withoutSpacing?.quantity);
      expect(withSpacing?.lengthM, withoutSpacing?.lengthM);
    });
  });

  group('doğrudan adet + l= formatı', () {
    test('15000Ø16 l=200 → 15000 ad × 2 m', () {
      final entry = parser.parseOne('15000Ø16 l=200');
      expect(entry?.quantity, 15000);
      expect(entry?.diameter, 16);
      expect(entry?.lengthM, closeTo(2, 0.001));
      expect(
        RebarWeightCalculator.weightKg(
          diameterMm: 16,
          lengthM: entry!.quantity * entry.lengthM,
        ),
        closeTo(15000 * 2 * (16 * 16 / 162), 0.1),
      );
    });

    test('5xØ16/450', () {
      final entry = parser.parseOne('5xØ16/450');
      expect(entry?.quantity, 5);
      expect(entry?.lengthM, closeTo(4.5, 0.001));
    });
  });

  group('reddedilen etiketler', () {
    test('adetsiz Ø12/350', () {
      expect(parser.parseOne('Ø12/350'), isNull);
    });

    test('proje adı', () {
      expect(parser.parseOne('PROJE ADI'), isNull);
    });
  });
}
