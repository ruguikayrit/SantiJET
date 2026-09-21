import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// PDF gömme öncesi görsel sıkıştırma.
///
/// Kurallar:
/// - width / height değişmez
/// - downsampling yok
/// - JPEG quality ~80; çıktı daha büyükse orijinal korunur
/// - alpha’lı PNG korunur (şeffaflık kaybı yok)
abstract final class PdfImageOptimizer {
  /// JPEG kalite hedefi (78–82 aralığı).
  static const int jpegQuality = 80;

  /// Fotoğraf / grafik baytlarını PDF’e gömmeden önce optimize et.
  static Uint8List optimizeForEmbed(Uint8List input) {
    if (input.isEmpty) return input;
    try {
      final decoded = img.decodeImage(input);
      if (decoded == null) return input;

      final width = decoded.width;
      final height = decoded.height;
      if (width <= 0 || height <= 0) return input;

      final hasAlpha = decoded.numChannels >= 4 && _hasTransparentPixel(decoded);

      if (hasAlpha) {
        // Şeffaflık gerekli → PNG kalır; yalnız sıkıştırma seviyesi.
        final png = img.encodePng(decoded, level: 9);
        final out = Uint8List.fromList(png);
        if (out.length >= input.length) return input;
        final check = img.decodeImage(out);
        if (check == null ||
            check.width != width ||
            check.height != height) {
          return input;
        }
        return out;
      }

      // RGB → JPEG (çözünürlük aynı).
      final jpg = img.encodeJpg(decoded, quality: jpegQuality);
      final out = Uint8List.fromList(jpg);
      if (out.length >= input.length) return input;

      final check = img.decodeImage(out);
      if (check == null ||
          check.width != width ||
          check.height != height) {
        return input;
      }
      return out;
    } catch (e, st) {
      debugPrint('PdfImageOptimizer.optimizeForEmbed: $e\n$st');
      return input;
    }
  }

  static bool _hasTransparentPixel(img.Image image) {
    // Örnekleyerek bak (tam tarama büyük görsellerde pahalı).
    final stepX = (image.width / 64).ceil().clamp(1, image.width);
    final stepY = (image.height / 64).ceil().clamp(1, image.height);
    for (var y = 0; y < image.height; y += stepY) {
      for (var x = 0; x < image.width; x += stepX) {
        if (image.getPixel(x, y).a < 255) return true;
      }
    }
    // Köşeler + merkez
    final points = <(int, int)>[
      (0, 0),
      (image.width - 1, 0),
      (0, image.height - 1),
      (image.width - 1, image.height - 1),
      (image.width ~/ 2, image.height ~/ 2),
    ];
    for (final (x, y) in points) {
      if (image.getPixel(x, y).a < 255) return true;
    }
    return false;
  }
}
