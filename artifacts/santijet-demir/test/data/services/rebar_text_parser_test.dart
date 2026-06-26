import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';

void main() {
  const parser = RebarTextParser();

  group('RebarTextParser — adet + çap + boy zorunlu', () {
    test('5xØ16/450', () {
      final entry = parser.parseOne('5xØ16/450');
      expect(entry?.diameter, 16);
      expect(entry?.lengthM, closeTo(4.5, 0.001));
      expect(entry?.quantity, 5);
    });

    test('5Ø12/350', () {
      final entry = parser.parseOne('5Ø12/350');
      expect(entry?.diameter, 12);
      expect(entry?.lengthM, closeTo(3.5, 0.001));
      expect(entry?.quantity, 5);
    });

    test('5 ADET FI12/350', () {
      final entry = parser.parseOne('5 ADET FI12/350');
      expect(entry?.diameter, 12);
      expect(entry?.lengthM, closeTo(3.5, 0.001));
      expect(entry?.quantity, 5);
    });

    test('adetsiz Ø12/350 reddedilir', () {
      expect(parser.parseOne('Ø12/350'), isNull);
    });

    test('adetsiz 12Ø350 reddedilir', () {
      expect(parser.parseOne('12Ø350'), isNull);
    });

    test('adetsiz FI16/320 reddedilir', () {
      expect(parser.parseOne('FI16/320'), isNull);
    });

    test('proje adı reddedilir', () {
      expect(parser.parseOne('PROJE ADI'), isNull);
    });
  });
}
