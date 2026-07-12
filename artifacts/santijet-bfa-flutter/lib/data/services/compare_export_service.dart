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
import '../../domain/calc/analiz_compare.dart';
import '../../domain/enums/app_enums.dart';

/// Karşılaştırma raporu dışa aktarma.
class CompareExportService {
  Future<void> sharePdf(AnalizCompareResult compare) async {
    final bytes = await _buildPdf(compare);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'karsilastirma_${_stamp()}.pdf',
    );
  }

  Future<void> shareExcel(AnalizCompareResult compare) async {
    final bytes = buildExcelBytes(compare);
    final fileName = 'karsilastirma_${_stamp()}.xlsx';
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

  Future<Uint8List> _buildPdf(AnalizCompareResult compare) async {
    final fontBytes = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final font = pw.Font.ttf(fontBytes);
    final boldBytes = await rootBundle.load('assets/fonts/Rajdhani-Bold.ttf');
    final titleFont = pw.Font.ttf(boldBytes);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: font, bold: titleFont),
        build: (context) => [
          pw.Text('ŞantiJET BFA — Analiz Karşılaştırması',
              style: pw.TextStyle(font: titleFont, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Text('Tarih: ${AppFormat.date(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
          _summaryTable(compare),
          pw.SizedBox(height: 16),
          pw.Text('Kalem Karşılaştırması',
              style: pw.TextStyle(font: titleFont, fontSize: 12)),
          pw.SizedBox(height: 6),
          _kalemTable(compare),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _summaryTable(AnalizCompareResult compare) {
    return pw.Table.fromTextArray(
      headers: [
        'Analiz',
        ...compare.analizler.map((a) => a.pozNo),
      ],
      data: [
        [
          'Malzeme + İşçilik',
          ...compare.analizler
              .map((a) => '${AppFormat.decimal(a.malzemeIscilikToplami)} TL'),
        ],
        [
          'Yüklenici Karı',
          ...compare.analizler
              .map((a) => '${AppFormat.decimal(a.yukleniciKarTutari)} TL'),
        ],
        [
          '1 Birim Fiyatı',
          ...compare.analizler
              .map((a) => '${AppFormat.decimal(a.birimFiyati)} TL / ${a.olcuBirimi}'),
        ],
      ],
      headerStyle: const pw.TextStyle(fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
    );
  }

  pw.Widget _kalemTable(AnalizCompareResult compare) {
    final headers = [
      'Tip',
      'Poz',
      'Tanım',
      ...compare.analizler.map((a) => a.pozNo),
    ];
    final data = <List<String>>[];
    for (final row in compare.kalemRows) {
      data.add([
        _tipLabel(row.tip),
        row.pozNo,
        row.tanim,
        ...compare.analizler.map((a) {
          final val = row.values[a.id];
          return val == null ? '—' : AppFormat.decimal(val.tutar);
        }),
      ]);
    }
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: const pw.TextStyle(fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 7),
    );
  }

  Uint8List buildExcelBytes(AnalizCompareResult compare) {
    return _buildExcel(compare);
  }

  Uint8List _buildExcel(AnalizCompareResult compare) {
    final rows = <List<String>>[
      ['ŞantiJET BFA — Analiz Karşılaştırması'],
      ['Tarih', AppFormat.date(DateTime.now())],
      [],
      ['Birim Fiyat Özeti', ...compare.analizler.map((a) => a.pozNo)],
      [
        'Malzeme + İşçilik',
        ...compare.analizler.map((a) => a.malzemeIscilikToplami.toString()),
      ],
      [
        'Yüklenici Karı',
        ...compare.analizler.map((a) => a.yukleniciKarTutari.toString()),
      ],
      [
        '1 Birim Fiyatı',
        ...compare.analizler.map((a) => a.birimFiyati.toString()),
      ],
      [],
      ['Kalem Karşılaştırması'],
      [
        'Tip',
        'Poz',
        'Tanım',
        ...compare.analizler.map((a) => a.pozNo),
      ],
    ];
    for (final row in compare.kalemRows) {
      rows.add([
        _tipLabel(row.tip),
        row.pozNo,
        row.tanim,
        ...compare.analizler.map((a) {
          final val = row.values[a.id];
          return val == null ? '' : val.tutar.toString();
        }),
      ]);
    }
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
        '<?xml version="1.0"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Karsilastirma" sheetId="1" r:id="rId1"/></sheets></workbook>');
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

  String _tipLabel(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => 'Malzeme',
        AnalizKalemTip.iscilik => 'İşçilik',
        AnalizKalemTip.ekipman => 'Ekipman',
      };

  String _stamp() => DateTime.now().toIso8601String().substring(0, 10);
}

final compareExportService = CompareExportService();
