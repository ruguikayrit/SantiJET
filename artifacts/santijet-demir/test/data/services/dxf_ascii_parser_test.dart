import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';

void main() {
  test('parses LWPOLYLINE length', () {
    const dxf = '''
0
SECTION
2
ENTITIES
0
LWPOLYLINE
8
DONAT_14
90
3
70
0
10
0
20
0
10
4
20
0
10
4
20
3
0
ENDSEC
0
EOF
''';

    final segments = DxfAsciiParser.parseAllSegments(dxf);
    expect(segments.single.layerName, 'DONAT_14');
    expect(segments.single.length, 7);
  });
}
