import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/cad_text_preprocessor.dart';

void main() {
  group('preprocessCadText', () {
    test('%%c çap kodunu Ø yapar', () {
      expect(
        preprocessCadText('üst.1670%%c22/15 l=1200'),
        'üst.1670Ø22/15 l=1200',
      );
    });

    test('MTEXT biçim kodunu temizler', () {
      expect(
        preprocessCadText('{\\fArial|b0;üst.1670Ø22/15 l=1200}'),
        'üst.1670Ø22/15 l=1200',
      );
    });
  });
}
