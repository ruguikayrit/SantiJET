import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Fotoğraf baytlarını saat yönünde 90° döndürür (PNG çıktı).
Future<Uint8List?> rotateImageBytesCw90(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final rotated = await rotateUiImageCw90(src);
    src.dispose();
    final data = await rotated.toByteData(format: ui.ImageByteFormat.png);
    rotated.dispose();
    if (data == null) return null;
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Saat yönü 90° — yeni boyut: (height × width).
Future<ui.Image> rotateUiImageCw90(ui.Image src) async {
  final w = src.width;
  final h = src.height;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(h.toDouble(), 0);
  canvas.rotate(math.pi / 2);
  canvas.drawImage(src, ui.Offset.zero, ui.Paint());
  final picture = recorder.endRecording();
  return picture.toImage(h, w);
}

/// Hedef yönelim: [landscape] true → yatay (geniş ≥ yüksek).
Future<Uint8List?> rotateImageBytesToOrientation(
  Uint8List bytes, {
  required bool landscape,
}) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final isLandscape = src.width >= src.height;
    if (landscape == isLandscape) {
      src.dispose();
      return bytes;
    }
    final rotated = await rotateUiImageCw90(src);
    src.dispose();
    final data = await rotated.toByteData(format: ui.ImageByteFormat.png);
    rotated.dispose();
    if (data == null) return null;
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
