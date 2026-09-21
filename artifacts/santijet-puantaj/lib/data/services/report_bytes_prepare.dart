import 'dart:typed_data';

import 'pdf_optimization_service.dart';

/// PDF ise oluşturma sonrası otomatik optimize et; değilse dokunma.
Future<List<int>> prepareBytesForDownload({
  required List<int> bytes,
  required String mimeType,
}) async {
  if (mimeType != 'application/pdf') return bytes;
  final optimized = await PdfOptimizationService.optimize(
    bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
  );
  return optimized;
}
