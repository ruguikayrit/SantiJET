import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/app_format.dart';
import '../../domain/entities/kesif.dart';

/// Keşif / metraj cetveli dışa aktarma.
class KesifExportService {
  Future<void> sharePdf(KesifProject project) async {
    final bytes = await _buildPdf(project);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'kesif_${_safe(project.ad)}.pdf',
    );
  }

  Future<void> shareExcel(KesifProject project) async {
    final bytes = buildExcelBytes(project);
    final fileName = 'kesif_${_safe(project.ad)}.xlsx';
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: fileName,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
        ),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Future<Uint8List> _buildPdf(KesifProject project) async {
    final fontBytes = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final font = pw.Font.ttf(fontBytes);
    final boldBytes = await rootBundle.load('assets/fonts/Rajdhani-Bold.ttf');
    final titleFont = pw.Font.ttf(boldBytes);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: font, bold: titleFont),
        build: (context) => [
          pw.Text('METRAJ / KEŞİF CETVELİ',
              style: pw.TextStyle(font: titleFont, fontSize: 16),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 10),
          pw.Text('Proje: ${project.ad}'),
          if (project.aciklama.trim().isNotEmpty)
            pw.Text('Açıklama: ${project.aciklama}'),
          pw.Text('Tarih: ${AppFormat.date(DateTime.tryParse(project.guncellemeTarihi) ?? DateTime.now())}'),
          pw.Text('Poz Sayısı: ${project.satirlar.length}'),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: const ['#', 'Poz No', 'Tanım', 'Birim', 'Miktar', 'B.F.', 'Tutar'],
            data: [
              for (var i = 0; i < project.satirlar.length; i++)
                [
                  '${i + 1}',
                  project.satirlar[i].pozNo,
                  project.satirlar[i].analizAdi,
                  project.satirlar[i].olcuBirimi,
                  AppFormat.decimal(project.satirlar[i].miktar),
                  AppFormat.decimal(project.satirlar[i].birimFiyati),
                  AppFormat.decimal(project.satirlar[i].tutar),
                ],
              if (project.satirlar.isEmpty) ['', '', 'Henüz poz yok', '', '', '', ''],
              ['', '', '', '', '', 'GENEL TOPLAM', AppFormat.decimal(project.toplam)],
            ],
            headerStyle: const pw.TextStyle(fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Uint8List buildExcelBytes(KesifProject project) {
    return _buildExcel(project);
  }

  Uint8List _buildExcel(KesifProject project) {
    final rows = <List<String>>[
      ['METRAJ / KEŞİF CETVELİ'],
      ['Proje', project.ad],
      if (project.aciklama.trim().isNotEmpty) ['Açıklama', project.aciklama],
      ['Tarih', AppFormat.date(DateTime.tryParse(project.guncellemeTarihi) ?? DateTime.now())],
      [],
      ['#', 'Poz No', 'Tanım', 'Birim', 'Miktar', 'Birim Fiyat', 'Tutar'],
      for (var i = 0; i < project.satirlar.length; i++)
        [
          '${i + 1}',
          project.satirlar[i].pozNo,
          project.satirlar[i].analizAdi,
          project.satirlar[i].olcuBirimi,
          project.satirlar[i].miktar.toString(),
          project.satirlar[i].birimFiyati.toString(),
          project.satirlar[i].tutar.toString(),
        ],
      ['', '', '', '', '', 'GENEL TOPLAM', project.toplam.toString()],
    ];
    return _simpleXlsx(rows);
  }

  Uint8List _simpleXlsx(List<List<String>> rows) {
    final archive = Archive();
    void add(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }
    final sheetRows = StringBuffer();
    var rowIndex = 1;
    for (final row in rows) {
      sheetRows.writeln('<row r="$rowIndex">');
      var col = 0;
      for (final cell in row) {
        col++;
        final colRef = _colName(col);
        sheetRows.writeln(
          '<c r="$colRef$rowIndex" t="inlineStr"><is><t>${_esc(cell)}</t></is></c>',
        );
      }
      sheetRows.writeln('</row>');
      rowIndex++;
    }
    add('[Content_Types].xml',
        '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>');
    add('_rels/.rels',
        '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>');
    add('xl/workbook.xml',
        '<?xml version="1.0"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Kesif" sheetId="1" r:id="rId1"/></sheets></workbook>');
    add('xl/_rels/workbook.xml.rels',
        '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>');
    add('xl/worksheets/sheet1.xml',
        '<?xml version="1.0"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>$sheetRows</sheetData></worksheet>');
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  String _colName(int index) {
    var n = index;
    final buf = StringBuffer();
    while (n > 0) {
      n--;
      buf.writeCharCode(65 + (n % 26));
      n ~/= 26;
    }
    return buf.toString().split('').reversed.join();
  }

  String _esc(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _safe(String ad) =>
      ad.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_').replaceAll(RegExp(r'_+'), '_');
}

final kesifExportService = KesifExportService();
