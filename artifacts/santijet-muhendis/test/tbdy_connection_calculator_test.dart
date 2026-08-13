import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_muhendis/data/catalog/steel_profile_catalog.dart';
import 'package:santijet_muhendis/domain/tbdy/steel_grade.dart';
import 'package:santijet_muhendis/domain/tbdy/tbdy_connection_calculator.dart';
import 'package:santijet_muhendis/domain/tbdy/tbdy_connection_input.dart';

void main() {
  group('TBDY Excel doğrulama örneği', () {
    test('S235 + HEB260 + IPE300 + w=9 + L=4.5', () {
      final column = SteelProfileCatalog.find('IPB (HE-B) 260')!;
      final beam = SteelProfileCatalog.find('IPE 300')!;

      final result = TbdyConnectionCalculator.calculate(
        TbdyConnectionInput(
          steelGrade: SteelGrades.s235,
          column: column,
          beam: beam,
          distributedLoadKnPerM: 9,
          spanLengthM: 4.5,
        ),
      );

      expect(result.cpr, 1.2);
      expect(result.cprRaw, closeTo(1.26596, 0.001));
      expect(result.mprKNm, closeTo(248.092, 0.01));
      expect(result.lhM, closeTo(4.24, 0.001));
      expect(result.vhKn, closeTo(136.105, 0.02));
      expect(result.mfKNm, closeTo(248.092, 0.01));
      expect(result.vuKn, closeTo(136.105, 0.02));
      expect(result.webSlenderness, closeTo(35.01, 0.05));
      expect(result.webSlendernessLimit, closeTo(65.3, 0.2));
      expect(result.phiVnKn, closeTo(300.33, 0.05));
      expect(result.allPassed, isTrue);
    });

    test('geçersiz açıklık (L ≤ d_kolon) hata verir', () {
      final column = SteelProfileCatalog.find('IPB (HE-B) 260')!;
      final beam = SteelProfileCatalog.find('IPE 300')!;

      expect(
        () => TbdyConnectionCalculator.calculate(
          TbdyConnectionInput(
            steelGrade: SteelGrades.s235,
            column: column,
            beam: beam,
            distributedLoadKnPerM: 9,
            spanLengthM: 0.2,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
