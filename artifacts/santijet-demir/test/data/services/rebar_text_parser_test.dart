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

    test('kesit çağrısı 6Φ16 (L= yok) atlanır', () {
      expect(parser.parseOne('6Φ16'), isNull);
    });

    test('zon etiketi 13Φ10/9 108 (L= yok) atlanır', () {
      expect(parser.parseOne('13Φ10/9 108'), isNull);
    });
  });

  group('kolon/perde etiketleri', () {
    test('42Ø28 L=280 boy demiri', () {
      final entry = parser.parseOne('42Ø28 L=280');
      expect(entry?.quantity, 42);
      expect(entry?.diameter, 28);
      expect(entry?.lengthM, closeTo(2.8, 0.001));
      expect(entry?.role, RebarLabelRole.longitudinal);
    });

    test('üst.180Ø22/15 l=805 → üst montaj', () {
      final entry = parser.parseOne('üst.180Ø22/15 l=805');
      expect(entry?.role, RebarLabelRole.topAssembly);
    });

    test('alt.180Ø22/15 l=805 → alt donatı', () {
      final entry = parser.parseOne('alt.180Ø22/15 l=805');
      expect(entry?.role, RebarLabelRole.bottomLongitudinal);
    });

    test('etr*18Ø12/10 L=510 etriye', () {
      final entry = parser.parseOne('etr*18Ø12/10 L=510');
      expect(entry?.quantity, 18);
      expect(entry?.diameter, 12);
      expect(entry?.lengthM, closeTo(5.1, 0.001));
      expect(entry?.role, RebarLabelRole.stirrup);
    });

    test('Çiroz*12Ø12 L=170', () {
      final entry = parser.parseOne('Çiroz*12Ø12 L=170');
      expect(entry?.quantity, 12);
      expect(entry?.role, RebarLabelRole.crosstie);
    });
  });

  group('IdeCAD referans — kolon detay', () {
    test('42Φ10/15/7/15/10 Etr. L=130', () {
      final entry = parser.parseOne('42Φ10/15/7/15/10 Etr. L=130');
      expect(entry?.quantity, 42);
      expect(entry?.diameter, 10);
      expect(entry?.lengthM, closeTo(1.3, 0.001));
      expect(entry?.role, RebarLabelRole.stirrup);
    });

    test('108Φ10 Çiroz L=53', () {
      final entry = parser.parseOne('108Φ10 Çiroz L=53');
      expect(entry?.quantity, 108);
      expect(entry?.diameter, 10);
      expect(entry?.lengthM, closeTo(0.53, 0.001));
      expect(entry?.role, RebarLabelRole.crosstie);
    });

    test('35Φ10/15/9/10/10 Etr. L=220', () {
      final entry = parser.parseOne('35Φ10/15/9/10/10 Etr. L=220');
      expect(entry?.quantity, 35);
      expect(entry?.diameter, 10);
      expect(entry?.lengthM, closeTo(2.2, 0.001));
      expect(entry?.role, RebarLabelRole.stirrup);
    });

    test('12Φ18 L=270 boy', () {
      final entry = parser.parseOne('12Φ18 L=270');
      expect(entry?.quantity, 12);
      expect(entry?.diameter, 18);
      expect(entry?.lengthM, closeTo(2.7, 0.001));
    });
  });

  group('IdeCAD referans — kiriş / plan', () {
    test('11Φ10/30 L=522 döşeme', () {
      final entry = parser.parseOne('11Φ10/30 L=522');
      expect(entry?.quantity, 11);
      expect(entry?.diameter, 10);
      expect(entry?.lengthM, closeTo(5.22, 0.001));
      expect(entry?.spacingCm, 30);
    });

    test('2 Φ 12 L=441 boşluklu', () {
      final entry = parser.parseOne('2 Φ 12 L=441');
      expect(entry?.quantity, 2);
      expect(entry?.diameter, 12);
      expect(entry?.lengthM, closeTo(4.41, 0.001));
    });

    test('5 2Φ12 L=446 poz + adet', () {
      final entry = parser.parseOne('5 2Φ12 L=446');
      expect(entry?.quantity, 2);
      expect(entry?.diameter, 12);
      expect(entry?.lengthM, closeTo(4.46, 0.001));
    });

    test('1Φ16 L=155', () {
      final entry = parser.parseOne('1Φ16 L=155');
      expect(entry?.quantity, 1);
      expect(entry?.diameter, 16);
      expect(entry?.lengthM, closeTo(1.55, 0.001));
    });
  });

  group('kısmi etiket birleştirme', () {
    test('15 Φ 10 / 25 + Etz. L=330', () {
      final entry = parser.parseJoined('15 Φ 10 / 25', 'Etz. L=330');
      expect(entry?.quantity, 15);
      expect(entry?.diameter, 10);
      expect(entry?.lengthM, closeTo(3.3, 0.001));
      expect(entry?.role, RebarLabelRole.stirrup);
    });

    test('looksIncomplete', () {
      expect(parser.looksIncomplete('15Φ10/25'), isTrue);
      expect(parser.looksIncomplete('Etz. L=330'), isTrue);
      expect(parser.looksIncomplete('42Φ10/15/7/15/10 Etr. L=130'), isFalse);
    });
  });
}
