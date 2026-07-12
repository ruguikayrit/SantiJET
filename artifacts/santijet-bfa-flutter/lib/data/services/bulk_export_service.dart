import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/poz_analiz.dart';
import 'analiz_excel_export_service.dart';
import 'analiz_pdf_export_service.dart';

/// Toplu analiz dışa aktarma — ZIP içinde PDF veya Excel dosyaları.
class BulkExportService {
  Future<Uint8List> buildZipBytes({
    required List<PozAnaliz> analizler,
    required bool asPdf,
  }) async {
    if (analizler.isEmpty) return Uint8List(0);
    final archive = Archive();
    for (final analiz in analizler) {
      final bytes = asPdf
          ? await analizPdfExportService.buildBytes(analiz)
          : analizExcelExportService.buildBytes(analiz);
      final ext = asPdf ? 'pdf' : 'xlsx';
      archive.addFile(
        ArchiveFile(
          '${_safeName(analiz.pozNo)}.$ext',
          bytes.length,
          bytes,
        ),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<void> shareZip({
    required List<PozAnaliz> analizler,
    required bool asPdf,
  }) async {
    if (analizler.isEmpty) return;
    final zipBytes = await buildZipBytes(analizler: analizler, asPdf: asPdf);
    final fileName =
        'santijet_bfa_toplu_${DateTime.now().toIso8601String().substring(0, 10)}.zip';

    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(zipBytes, name: fileName, mimeType: 'application/zip'),
          ],
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(zipBytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/zip')]),
    );
  }

  String _safeName(String pozNo) =>
      pozNo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_').replaceAll(RegExp(r'_+'), '_');
}

final bulkExportService = BulkExportService();
