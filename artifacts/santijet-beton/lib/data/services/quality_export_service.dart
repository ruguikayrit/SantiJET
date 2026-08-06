import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/app_date.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/quality_sample.dart';

/// Basınç dayanım raporları PDF / Excel dışa aktarma.
class QualityExportService {
  Future<void> sharePdf({
    required Project project,
    required List<QualitySample> samples,
  }) async {
    final bytes = await buildPdfBytes(project: project, samples: samples);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'basinc_dayanim_${_stamp()}.pdf',
    );
  }

  Future<void> shareExcel({
    required Project project,
    required List<QualitySample> samples,
  }) async {
    final bytes = buildExcelBytes(project: project, samples: samples);
    final fileName = 'basinc_dayanim_${_stamp()}.xlsx';
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: 'ŞantiJET Beton — Basınç Dayanım Raporları',
    );
  }

  Future<Uint8List> buildPdfBytes({
    required Project project,
    required List<QualitySample> samples,
  }) async {
    final fontBytes = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final font = pw.Font.ttf(fontBytes);
    final boldBytes = await rootBundle.load('assets/fonts/Rajdhani-Bold.ttf');
    final titleFont = pw.Font.ttf(boldBytes);

    final sorted = [...samples]
      ..sort((a, b) => b.sampleDate.compareTo(a.sampleDate));

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: font, bold: titleFont),
        build: (context) => [
          pw.Text(
            'ŞantiJET Beton — Basınç Dayanım Raporları',
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 16,
              color: const PdfColor.fromInt(0xFF0B1220),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Proje: ${project.name}'
            '${project.code.isEmpty ? '' : ' (${project.code})'}'
            ' · Tarih: ${AppDate.format(AppDate.today())}'
            ' · ${sorted.length} kayıt',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF6B7A90),
            ),
          ),
          pw.SizedBox(height: 12),
          _table(sorted),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _table(List<QualitySample> samples) {
    const headers = [
      'Tarih',
      'Numune',
      'Rapor No',
      'Eleman',
      'Sınıf',
      'Yaş',
      'Ort. MPa',
      'Min MPa',
      'Uygunluk',
      'Cüruf / Not',
    ];

    pw.Widget cell(String text, {required bool header}) {
      return pw.Container(
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: pw.BoxDecoration(
          color: header
              ? const PdfColor.fromInt(0xFF0055FF)
              : PdfColors.white,
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: header ? 8 : 7,
            color: header
                ? PdfColors.white
                : const PdfColor.fromInt(0xFF0B1220),
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFD5DEEA),
        width: 0.6,
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          children: [for (final h in headers) cell(h, header: true)],
        ),
        for (final s in samples)
          pw.TableRow(
            children: [
              for (final value in _row(s)) cell(value, header: false),
            ],
          ),
      ],
    );
  }

  List<String> _row(QualitySample s) {
    final note = [
      if (s.slagNote.isNotEmpty) s.slagNote,
      if (s.notes.isNotEmpty) s.notes,
    ].join(' · ');
    return [
      s.sampleDate,
      s.sampleCode.isEmpty ? '—' : s.sampleCode,
      s.labReportNo.isEmpty ? '—' : s.labReportNo,
      s.elementGroup.label,
      s.concreteClass,
      '${s.ageDays} gün',
      s.strengthMpa == null ? 'Bekliyor' : s.strengthMpa!.toStringAsFixed(1),
      s.minStrengthMpa == null ? '—' : s.minStrengthMpa!.toStringAsFixed(1),
      _compliance(s),
      note.isEmpty ? '—' : note,
    ];
  }

  String _compliance(QualitySample s) => switch (s.isCompliant) {
        true => 'Uygun',
        false => 'Uygunsuz',
        null => s.isPending ? 'Bekliyor' : 'Karar yok',
      };

  Uint8List buildExcelBytes({
    required Project project,
    required List<QualitySample> samples,
  }) {
    final sorted = [...samples]
      ..sort((a, b) => b.sampleDate.compareTo(a.sampleDate));
    final rows = <List<String>>[
      ['ŞantiJET Beton — Basınç Dayanım Raporları'],
      ['Proje', project.name],
      if (project.code.isNotEmpty) ['Proje Kodu', project.code],
      ['Tarih', AppDate.format(AppDate.today())],
      ['Kayıt sayısı', '${sorted.length}'],
      [],
      [
        'Tarih',
        'Numune Kodu',
        'Rapor No',
        'Eleman Grubu',
        'Beton Sınıfı',
        'Yaş (gün)',
        'Ortalama MPa',
        'Min MPa',
        'Uygunluk',
        'Cüruf / Katkı',
        'Notlar',
      ],
      for (final s in sorted)
        [
          s.sampleDate,
          s.sampleCode,
          s.labReportNo,
          s.elementGroup.label,
          s.concreteClass,
          '${s.ageDays}',
          s.strengthMpa?.toStringAsFixed(1) ?? '',
          s.minStrengthMpa?.toStringAsFixed(1) ?? '',
          _compliance(s),
          s.slagNote,
          s.notes,
        ],
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

    add(
      '[Content_Types].xml',
      '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
    );
    add(
      '_rels/.rels',
      '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    );
    add(
      'xl/workbook.xml',
      '<?xml version="1.0"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Basinc Dayanim" sheetId="1" r:id="rId1"/></sheets></workbook>',
    );
    add(
      'xl/_rels/workbook.xml.rels',
      '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
    );
    add(
      'xl/worksheets/sheet1.xml',
      '<?xml version="1.0"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>$sheetRows</sheetData></worksheet>',
    );
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Excel dosyası oluşturulamadı');
    }
    return Uint8List.fromList(encoded);
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
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _stamp() => DateTime.now().toIso8601String().substring(0, 10);
}

final qualityExportService = QualityExportService();
