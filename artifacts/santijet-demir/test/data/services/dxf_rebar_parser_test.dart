import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';
import 'package:santijet_demir/data/services/dxf_rebar_parser.dart';

const sampleRebarDxf = '''
0
SECTION
2
ENTITIES
0
LINE
8
DONATI_12
10
0.0
20
0.0
11
10.0
21
0.0
0
LINE
8
DONATI_16
10
0.0
20
0.0
11
0.0
21
15.0
0
LINE
8
MOBILYA
10
0.0
20
0.0
11
100.0
21
0.0
0
ENDSEC
0
EOF
''';

void main() {
  group('DxfAsciiParser', () {
    test('reads LINE entities from ENTITIES section', () {
      final segments = DxfAsciiParser.parseAllSegments(sampleRebarDxf);

      expect(segments.length, 3);
      expect(segments[0].layerName, 'DONATI_12');
      expect(segments[0].length, 10);
      expect(segments[1].length, 15);
    });

    test('detects binary DXF header', () {
      final bytes = 'AutoCAD Binary DXF\r\n'.codeUnits;
      expect(DxfAsciiParser.isBinaryDxf(bytes), isTrue);
    });
  });

  group('DxfRebarParser', () {
    test('extracts rebar lines from DONAT layers and ignores others', () {
      final parser = DxfRebarParser();
      final result = parser.parse(
        fileName: 'test.dxf',
        content: sampleRebarDxf,
      );

      expect(result.lines.length, 2);
      expect(result.totalLengthM, 25);
      expect(result.totalBarCount, 2);
      expect(result.lines.first.diameter, 12);
      expect(result.lines.last.diameter, 16);
    });

    test('detects diameter from FI prefix in layer name', () {
      const dxf = '''
0
SECTION
2
ENTITIES
0
LINE
8
ARMATUR_FI20
10
0
20
0
11
5
21
0
0
ENDSEC
0
EOF
''';

      final result = DxfRebarParser().parse(fileName: 'fi.dxf', content: dxf);
      expect(result.lines.single.diameter, 20);
      expect(result.lines.single.totalLengthM, 5);
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
