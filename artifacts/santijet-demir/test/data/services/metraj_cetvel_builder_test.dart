import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/cad_text_entity.dart';
import 'package:santijet_demir/data/services/element_header_parser.dart';
import 'package:santijet_demir/data/services/metraj_cetvel_builder.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';

void main() {
  const headerParser = ElementHeaderParser();
  const builder = MetrajCetvelBuilder();

  group('ElementHeaderParser', () {
    test('S1[100/160] 182 ADET', () {
      final header = headerParser.tryParse('S1[100/160] 182 ADET');
      expect(header, isNotNull);
      expect(header!.code, 'S1');
      expect(header.type, StructuralElementType.column);
      expect(header.dimensionText, '100/160');
      expect(header.benzerCount, 182);
      expect(header.title, 'S1 - 100/160');
    });

    test('P1[40/240] 36 ADET', () {
      final header = headerParser.tryParse('P1[40/240] 36 ADET');
      expect(header?.code, 'P1');
      expect(header?.type, StructuralElementType.wall);
      expect(header?.benzerCount, 36);
    });

    test('K2[30/50] başlık benzer olmadan', () {
      final header = headerParser.tryParse('K2[30/50]');
      expect(header?.code, 'K2');
      expect(header?.type, StructuralElementType.beam);
      expect(header?.benzerCount, 1);
    });

    test('182 ADET ayrı satır', () {
      expect(headerParser.tryParseBenzerOnly('182 ADET'), 182);
      expect(headerParser.tryParseBenzerOnly('36 adt'), 36);
    });
  });

  group('MetrajCetvelBuilder', () {
    test('S1 kolonu benzer ile çarpılır', () {
      final entities = [
        const CadTextEntity(entityType: 'TEXT', text: 'S1[100/160] 182 ADET'),
        const CadTextEntity(entityType: 'TEXT', text: '42Ø28 L=280'),
        const CadTextEntity(entityType: 'TEXT', text: 'etr*18Ø12/10 L=510'),
        const CadTextEntity(entityType: 'TEXT', text: 'Çiroz*12Ø12 L=170'),
      ];

      final result = builder.build(entities);

      expect(result.cetvel.length, 1);
      final entry = result.cetvel.single;
      expect(entry.title, 'S1 - 100/160');
      expect(entry.benzerCount, 182);
      expect(entry.rows.length, 3);

      final longitudinal = entry.rows.firstWhere(
        (row) => row.role == RebarLabelRole.longitudinal,
      );
      expect(longitudinal.unitQuantity, 42);
      expect(longitudinal.totalQuantity, 42 * 182);

      final stirrup = entry.rows.firstWhere(
        (row) => row.role == RebarLabelRole.stirrup,
      );
      expect(stirrup.unitQuantity, 18);
      expect(stirrup.totalQuantity, 18 * 182);

      final detail = result.textDetails.firstWhere(
        (d) => d.rebarRole == RebarLabelRole.longitudinal,
      );
      expect(detail.benzerCount, 182);
      expect(detail.unitQuantity, 42);
      expect(detail.quantity, 42 * 182);
    });

    test('P1 perde benzer ayrı satırda', () {
      final entities = [
        const CadTextEntity(entityType: 'TEXT', text: 'P1[40/240]'),
        const CadTextEntity(entityType: 'TEXT', text: '36 ADET'),
        const CadTextEntity(entityType: 'TEXT', text: '34Ø16 L=325'),
        const CadTextEntity(entityType: 'TEXT', text: '34Ø16 L=185'),
      ];

      final result = builder.build(entities);

      expect(result.cetvel.single.benzerCount, 36);
      expect(result.cetvel.single.rows.length, 2);
      expect(
        result.textDetails.every((detail) => detail.benzerCount == 36),
        isTrue,
      );
    });

    test('başlıksız etiketler gruplanmaz', () {
      final entities = [
        const CadTextEntity(entityType: 'TEXT', text: '42Ø28 L=280'),
      ];

      final result = builder.build(entities);

      expect(result.cetvel, isEmpty);
      expect(result.unassignedCount, 1);
      expect(result.textDetails.single.benzerCount, 1);
    });

    test('iki eleman sırayla gruplanır', () {
      final entities = [
        const CadTextEntity(entityType: 'TEXT', text: 'S1[100/160] 2 ADET'),
        const CadTextEntity(entityType: 'TEXT', text: '42Ø28 L=280'),
        const CadTextEntity(entityType: 'TEXT', text: 'P1[40/240] 3 ADET'),
        const CadTextEntity(entityType: 'TEXT', text: '34Ø16 L=325'),
      ];

      final result = builder.build(entities);

      expect(result.cetvel.length, 2);
      expect(result.cetvel[0].elementCode, 'S1');
      expect(result.cetvel[0].benzerCount, 2);
      expect(result.cetvel[1].elementCode, 'P1');
      expect(result.cetvel[1].benzerCount, 3);
    });
  });
}
