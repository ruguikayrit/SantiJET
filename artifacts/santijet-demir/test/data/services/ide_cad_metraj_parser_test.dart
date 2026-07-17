import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/cad_text_entity.dart';
import 'package:santijet_demir/data/services/cad_text_preprocessor.dart';
import 'package:santijet_demir/data/services/drawing_style_catalog.dart';
import 'package:santijet_demir/data/services/element_header_parser.dart';
import 'package:santijet_demir/data/services/metraj_cetvel_builder.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';

void main() {
  const headerParser = ElementHeaderParser();
  const builder = MetrajCetvelBuilder();
  const catalog = DrawingStyleCatalog();

  group('preprocessCadText Φ', () {
    test('Φ ve boşlukları Ø yapar', () {
      expect(preprocessCadText('42Φ10 Etr. L=130'), '42Ø10 Etr. L=130');
      expect(preprocessCadText('2 Φ 12 L=441'), '2Ø12 L=441');
      expect(preprocessCadText('15 Φ 10 / 25'), '15Ø10 / 25');
    });
  });

  group('ElementHeaderParser IdeCAD', () {
    test('SB107 (35/30)', () {
      final h = headerParser.tryParse('SB107 (35/30)');
      expect(h?.code, 'SB107');
      expect(h?.type, StructuralElementType.column);
      expect(h?.dimensionText, '35/30');
      expect(h?.benzerCount, 1);
    });

    test('SB101 - SB102 (30/80) benzer=2', () {
      final h = headerParser.tryParse('SB101 - SB102 (30/80)');
      expect(h?.code, 'SB101-SB102');
      expect(h?.benzerCount, 2);
      expect(h?.dimensionText, '30/80');
      expect(h?.type, StructuralElementType.column);
    });

    test('PS01 PERDE DETAYI', () {
      final h = headerParser.tryParse('PS01 PERDE DETAYI');
      expect(h?.code, 'PS01');
      expect(h?.type, StructuralElementType.wall);
    });

    test('KB101 (30/50)', () {
      final h = headerParser.tryParse('KB101 (30/50)');
      expect(h?.code, 'KB101');
      expect(h?.type, StructuralElementType.beam);
    });

    test('KZ01 (30/50)', () {
      final h = headerParser.tryParse('KZ01 (30/50)');
      expect(h?.type, StructuralElementType.beam);
    });

    test('K101 / 28 Adet', () {
      final h = headerParser.tryParse('K101 / 28 Adet');
      expect(h?.code, 'K101');
      expect(h?.benzerCount, 28);
      expect(h?.type, StructuralElementType.beam);
    });

    test('PSB102 25/255 döşeme paneli', () {
      final h = headerParser.tryParse('PSB102 25/255');
      expect(h?.code, 'PSB102');
      expect(h?.type, StructuralElementType.slab);
      expect(h?.dimensionText, '25/255');
    });

    test('S01-S02 KOLON DETAYI', () {
      final h = headerParser.tryParse('S01-S02 KOLON DETAYI');
      expect(h?.code, 'S01-S02');
      expect(h?.benzerCount, 2);
      expect(h?.type, StructuralElementType.column);
    });

    test('KESIT A-A KB102-KB103-KB104', () {
      final h = headerParser.tryParse('KESİT A-A KB102-KB103-KB104');
      expect(h?.benzerCount, 3);
      expect(h?.code, 'KB102-KB103-KB104');
      expect(h?.type, StructuralElementType.beam);
    });

    test('klasik S1[100/160] 182 ADET korunur', () {
      final h = headerParser.tryParse('S1[100/160] 182 ADET');
      expect(h?.code, 'S1');
      expect(h?.benzerCount, 182);
      expect(h?.dimensionText, '100/160');
    });
  });

  group('DrawingStyleCatalog', () {
    test('kolon detay stilini tanır', () {
      final match = catalog.detect([
        'SB107 (35/30)',
        '42Φ10/15/7/15/10 Etr. L=130',
        '108Φ10 Çiroz L=53',
      ]);
      expect(match.primary.id, CadDrawingStyleId.ideCadColumnDetail);
    });

    test('kiriş detay stilini tanır', () {
      final match = catalog.detect([
        'KB101 (30/50)',
        '3Φ14 ilave',
        'K101 / 28 Adet',
      ]);
      expect(match.primary.id, CadDrawingStyleId.ideCadBeamDetail);
    });

    test('klasik köşeli başlık', () {
      final match = catalog.detect([
        'S1[100/160] 182 ADET',
        'etr*18Ø12/10 L=510',
      ]);
      expect(match.primary.id, CadDrawingStyleId.classicBracketHeader);
    });
  });

  group('MetrajCetvelBuilder IdeCAD', () {
    test('SB107 kolon detayı etriye + çiroz', () {
      final result = builder.build([
        const CadTextEntity(entityType: 'TEXT', text: 'SB107 (35/30)'),
        const CadTextEntity(
          entityType: 'TEXT',
          text: '42Φ10/15/7/15/10 Etr. L=130',
        ),
        const CadTextEntity(entityType: 'TEXT', text: '108Φ10 Çiroz L=53'),
      ]);

      expect(result.cetvel.length, 1);
      expect(result.cetvel.single.elementCode, 'SB107');
      expect(result.cetvel.single.rows.length, 2);
      expect(
        result.cetvel.single.rows.any((r) => r.role == RebarLabelRole.stirrup),
        isTrue,
      );
      expect(
        result.cetvel.single.rows.any((r) => r.role == RebarLabelRole.crosstie),
        isTrue,
      );
    });

    test('SB101-SB102 benzer ×2', () {
      final result = builder.build([
        const CadTextEntity(entityType: 'TEXT', text: 'SB101 - SB102 (30/80)'),
        const CadTextEntity(
          entityType: 'TEXT',
          text: '35Φ10/15/9/10/10 Etr. L=220',
        ),
      ]);

      expect(result.cetvel.single.benzerCount, 2);
      final etr = result.cetvel.single.rows.single;
      expect(etr.unitQuantity, 35);
      expect(etr.totalQuantity, 70);
    });

    test('kısmi Etz birleştirme', () {
      final result = builder.build([
        const CadTextEntity(entityType: 'TEXT', text: 'PS01 PERDE DETAYI'),
        const CadTextEntity(entityType: 'TEXT', text: '15 Φ 10 / 25'),
        const CadTextEntity(entityType: 'TEXT', text: 'Etz. L=330'),
      ]);

      expect(result.textDetails, isNotEmpty);
      expect(result.cetvel.single.rows.single.diameter, 10);
      expect(result.cetvel.single.rows.single.unitQuantity, 15);
    });
  });
}
