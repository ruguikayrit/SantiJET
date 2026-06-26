import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';

void main() {
  const parser = RebarTextParser();

  group('RebarTextParser — üst/alt dağıtım formatı', () {
    test('üst.1670Ø22/15 l=1200', () {
      final entry = parser.parseOne('üst.1670Ø22/15 l=1200');
      expect(entry?.diameter, 22);
      expect(entry?.lengthM, closeTo(1.2, 0.001));
      expect(entry?.quantity, 12);
    });

    test('üst.334Ø22/15 l=1200 → 3 adet × 1,20 m', () {
      final entry = parser.parseOne('üst.334Ø22/15 l=1200');
      expect(entry?.diameter, 22);
      expect(entry?.quantity, 3);
      expect(entry?.lengthM, closeTo(1.2, 0.001));
      expect(entry!.quantity * entry.lengthM, closeTo(3.6, 0.001));
    });

    test('alt.1670Ø22/15 l=640', () {
      final entry = parser.parseOne('alt.1670Ø22/15 l=640');
      expect(entry?.diameter, 22);
      expect(entry?.lengthM, closeTo(0.64, 0.001));
      expect(entry?.quantity, 12);
    });

    test('12Ø22/15 l=1200 — küçük sayı doğrudan adet', () {
      final entry = parser.parseOne('12Ø22/15 l=1200');
      expect(entry?.quantity, 12);
      expect(entry?.diameter, 22);
    });

    test('AutoCAD %%c çap kodu', () {
      final entry = parser.parseOne('üst.1670%%c22/15 l=1200');
      expect(entry?.diameter, 22);
      expect(entry?.lengthM, closeTo(1.2, 0.001));
      expect(entry?.quantity, 12);
    });

    test('MTEXT biçim kodlu metin', () {
      final entry = parser.parseOne(
        '{\\fArial|b0|i0;c162;üst.1670Ø22/15 l=1200}',
      );
      expect(entry?.diameter, 22);
      expect(entry?.quantity, 12);
    });
  });

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
