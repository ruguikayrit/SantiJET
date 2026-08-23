import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_tahvil/domain/tahvil_record.dart';
import 'package:santijet_tahvil/domain/tahvil_record_display.dart';

void main() {
  group('TahvilRecordDisplay', () {
    test('uses structured fields when present', () {
      final record = TahvilRecord(
        id: '1',
        createdAt: DateTime(2026, 8, 23),
        basis: '2 çeşit · Adet',
        summary: 'legacy summary',
        detail: 'legacy detail',
        isAllowed: true,
        sourceLine: '4×Ø14 · 6×Ø20',
        targetLine: '8×Ø10 · 6×Ø20',
        sourceAs: 2500.7,
        targetAs: 2513.3,
        asUnit: 'mm²',
      );

      final display = TahvilRecordDisplay.from(record);
      expect(display.sourceLine, '4×Ø14 · 6×Ø20');
      expect(display.targetLine, '8×Ø10 · 6×Ø20');
      expect(display.sourceAs, 2500.7);
      expect(display.targetAs, 2513.3);
      expect(display.asUnit, 'mm²');
    });

    test('parses legacy dual quantity record', () {
      final record = TahvilRecord(
        id: '2',
        createdAt: DateTime(2026, 8, 23),
        basis: '2 çeşit · Adet',
        summary: '4×Ø14 → 8×Ø10 · 6×Ø20 (aynı)',
        detail: '2 çeşit · As 2500.7 → 2513.3 mm²',
        isAllowed: true,
      );

      final display = TahvilRecordDisplay.from(record);
      expect(display.sourceLine, '4×Ø14 · 6×Ø20');
      expect(display.targetLine, '8×Ø10 · 6×Ø20');
      expect(display.sourceAs, 2500.7);
      expect(display.targetAs, 2513.3);
      expect(display.asUnit, 'mm²');
    });
  });
}
