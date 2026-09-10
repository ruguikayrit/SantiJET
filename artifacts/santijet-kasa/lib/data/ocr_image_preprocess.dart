import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Tablo JPG ön işleme — OCR doğruluğunu artırır.
abstract final class OcrImagePreprocess {
  /// Gri ton + kontrast; tablo JPG için ~1600px genişlik.
  /// Keskinleştirme rakamları bozar — uygulama.
  static Uint8List prepareJpeg(List<int> bytes, {int minWidth = 1600}) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      return Uint8List.fromList(bytes);
    }

    var image = img.bakeOrientation(decoded);
    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 1.25, brightness: 1.02);

    if (image.width < minWidth) {
      final scale = minWidth / image.width;
      image = img.copyResize(
        image,
        width: minWidth,
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }

    // Çok büyükse OCR.space limitine yaklaşmasın (~1MB free tier)
    if (image.width > 3200) {
      image = img.copyResize(
        image,
        width: 3200,
        height: (image.height * (3200 / image.width)).round(),
        interpolation: img.Interpolation.average,
      );
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 92));
  }
}
