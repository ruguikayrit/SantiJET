import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';

void main() {
  const parser = RebarTextParser();

  group('RebarTextParser patterns', () {
    test('FI prefix', () {
      final entry = parser.parseOne('FI16/320');
      expect(entry?.diameter, 16);
      expect(entry?.lengthM, closeTo(3.2, 0.001));
    });

    test('diameter symbol after number', () {
      final entry = parser.parseOne('12Ø350');
      expect(entry?.diameter, 12);
      expect(entry?.lengthM, closeTo(3.5, 0.001));
    });

    test('millimeter length', () {
      final entry = parser.parseOne('Ø20 3500');
      expect(entry?.diameter, 20);
      expect(entry?.lengthM, closeTo(3.5, 0.001));
    });

    test('meter length', () {
      final entry = parser.parseOne('Ø14 L=4.50');
      expect(entry?.diameter, 14);
      expect(entry?.lengthM, closeTo(4.5, 0.001));
    });
  });
}
