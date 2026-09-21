import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:santijet_puantaj/data/services/pdf_image_optimizer.dart';
import 'package:santijet_puantaj/data/services/pdf_optimization_service.dart';

void main() {
  test('PdfImageOptimizer keeps width/height', () {
    final raw = img.Image(width: 640, height: 480);
    for (var y = 0; y < raw.height; y++) {
      for (var x = 0; x < raw.width; x++) {
        raw.setPixelRgb(x, y, (x * 3) % 255, (y * 5) % 255, (x + y) % 255);
      }
    }
    final high = Uint8List.fromList(img.encodeJpg(raw, quality: 100));
    final out = PdfImageOptimizer.optimizeForEmbed(high);
    final decoded = img.decodeImage(out);
    expect(decoded, isNotNull);
    expect(decoded!.width, 640);
    expect(decoded.height, 480);
    expect(out.length, lessThanOrEqualTo(high.length));
  });

  test('PdfOptimizationService returns original for non-pdf', () async {
    final input = Uint8List.fromList([1, 2, 3, 4, 5]);
    final out = await PdfOptimizationService.optimize(input);
    expect(out, same(input));
  });

  test('PdfOptimizationService keeps valid pdf header', () async {
    final input = Uint8List.fromList(
      '%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF\n'.codeUnits,
    );
    final out = await PdfOptimizationService.optimize(input);
    expect(out[0], 0x25);
    expect(out[1], 0x50);
    expect(out[2], 0x44);
    expect(out[3], 0x46);
  });
}
