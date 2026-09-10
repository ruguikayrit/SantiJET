import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Tablo JPG ön işleme — OCR doğruluğunu artırır.
abstract final class OcrImagePreprocess {
  /// Gri ton + kontrast + keskinleştirme; tablo JPG için ~2200px genişlik.
  static Uint8List prepareJpeg(List<int> bytes, {int minWidth = 2200}) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      return Uint8List.fromList(bytes);
    }

    var image = img.bakeOrientation(decoded);
    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 1.35, brightness: 1.03);
    image = img.convolution(
      image,
      filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ],
      div: 1,
    );

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
