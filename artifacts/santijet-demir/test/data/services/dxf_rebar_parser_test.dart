import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/dxf_rebar_parser.dart';

const sampleRebarDxf = '''
0
SECTION
2
HEADER
0
ENDSEC
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
30
0.0
11
10.0
21
0.0
31
0.0
0
LINE
8
DONATI_16
10
0.0
20
0.0
30
0.0
11
0.0
21
15.0
31
0.0
0
LINE
8
MOBILYA
10
0.0
20
0.0
30
0.0
11
100.0
21
0.0
31
0.0
0
ENDSEC
0
EOF
''';

void main() {
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
  });
}
