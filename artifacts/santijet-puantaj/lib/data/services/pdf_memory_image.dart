import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_image_optimizer.dart';

/// PDF’e görsel gömmek için tek kapı — çözünürlük korunarak sıkıştırır.
pw.MemoryImage pdfMemoryImage(Uint8List bytes) {
  return pw.MemoryImage(PdfImageOptimizer.optimizeForEmbed(bytes));
}
