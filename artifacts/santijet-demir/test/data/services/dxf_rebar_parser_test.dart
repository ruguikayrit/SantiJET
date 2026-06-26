import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';
import 'package:santijet_demir/data/services/dxf_rebar_parser.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';

const sampleRebarDxf = '''
0
SECTION
2
ENTITIES
0
TEXT
8
MOBILYA
1
Ø12/350
0
TEXT
8
DONATI_16
1
5xØ16/450
0
TEXT
8
NOTLAR
1
PROJE ADI
0
ENDSEC
0
EOF
''';

void main() {
  group('DxfAsciiParser', () {
    test('reads TEXT entities from ENTITIES section', () {
      final texts = DxfAsciiParser.parseAllTexts(sampleRebarDxf);

      expect(texts.length, 3);
      expect(texts[0], 'Ø12/350');
      expect(texts[1], '5xØ16/450');
    });

    test('detects binary DXF header', () {
      final bytes = 'AutoCAD Binary DXF\r\n'.codeUnits;
      expect(DxfAsciiParser.isBinaryDxf(bytes), isTrue);
    });
  });

  group('RebarTextParser', () {
    const parser = RebarTextParser();

    test('parses Ø12/350', () {
      final entry = parser.parseOne('Ø12/350');
      expect(entry?.diameter, 12);
      expect(entry?.lengthM, closeTo(3.5, 0.001));
      expect(entry?.quantity, 1);
    });

    test('parses quantity prefix 5xØ16/450', () {
      final entry = parser.parseOne('5xØ16/450');
      expect(entry?.diameter, 16);
      expect(entry?.lengthM, closeTo(4.5, 0.001));
      expect(entry?.quantity, 5);
    });

    test('ignores text without diameter and length', () {
      expect(parser.parseOne('PROJE ADI'), isNull);
    });
  });

  group('DxfRebarParser', () {
    test('extracts rebar from text labels and ignores unrelated text', () {
      final parser = DxfRebarParser();
      final result = parser.parse(
        fileName: 'test.dxf',
        content: sampleRebarDxf,
      );

      expect(result.lines.length, 2);
      expect(result.totalBarCount, 6);
      expect(result.lines.first.diameter, 12);
      expect(result.lines.first.totalLengthM, closeTo(3.5, 0.001));
      expect(result.lines.last.diameter, 16);
      expect(result.lines.last.totalLengthM, closeTo(22.5, 0.001));
      expect(result.skippedEntityCount, 1);
      expect(result.textDetails.length, 3);
      expect(result.includedTextCount, 2);
      expect(result.textDetails.first.included, isTrue);
      expect(result.textDetails.first.sourceText, 'Ø12/350');
      expect(result.textDetails.last.included, isFalse);
    });

    test('throws readable error for binary DXF bytes', () {
      expect(
        () => DxfRebarParser().parseBytes(
          fileName: 'binary.dxf',
          bytes: 'AutoCAD Binary DXF\r\n'.codeUnits,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
