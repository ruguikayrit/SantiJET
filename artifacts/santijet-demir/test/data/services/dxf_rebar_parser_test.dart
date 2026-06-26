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

    test('adetsiz Ø12/350 reddedilir', () {
      expect(parser.parseOne('Ø12/350'), isNull);
    });

    test('5xØ16/450 kabul edilir', () {
      final entry = parser.parseOne('5xØ16/450');
      expect(entry?.diameter, 16);
      expect(entry?.lengthM, closeTo(4.5, 0.001));
      expect(entry?.quantity, 5);
    });

    test('proje adı reddedilir', () {
      expect(parser.parseOne('PROJE ADI'), isNull);
    });
  });

  group('DxfRebarParser', () {
    test('sadece adet+çap+boy içeren etiketleri metraja alır', () {
      final parser = DxfRebarParser();
      final result = parser.parse(
        fileName: 'test.dxf',
        content: sampleRebarDxf,
      );

      expect(result.lines.length, 1);
      expect(result.lines.single.diameter, 16);
      expect(result.lines.single.totalLengthM, closeTo(22.5, 0.001));
      expect(result.totalBarCount, 5);
      expect(result.textDetails.length, 1);
      expect(result.textDetails.single.sourceText, '5xØ16/450');
      expect(result.skippedEntityCount, 2);
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
