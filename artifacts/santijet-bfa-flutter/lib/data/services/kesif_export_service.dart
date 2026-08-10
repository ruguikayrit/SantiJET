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
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/kesif.dart';

/// Keşif / metraj / yaklaşık maliyet cetveli dışa aktarma.
class KesifExportService {
  static const defaultPdfTitle = 'ŞANTİJET MALİYET — METRAJ / KEŞİF CETVELİ';
  static const yaklasikMaliyetPdfTitle = 'YAKLAŞIK MALİYET CETVELİ';

  Future<void> sharePdf(
    KesifProject project, {
    String title = defaultPdfTitle,
    String filenamePrefix = 'kesif',
  }) async {
    final bytes = await _buildPdf(project, title: title);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${filenamePrefix}_${_safe(project.ad)}.pdf',
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

  Future<Uint8List> _buildPdf(
    KesifProject project, {
    required String title,
  }) async {
    // Gövde Noto Sans: ₺ glyph'i bold satırlarda da mevcut.
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final titleBytes = await rootBundle.load('assets/fonts/Rajdhani-Bold.ttf');
    final titleFont = pw.Font.ttf(titleBytes);
    final doc = pw.Document();

    const headerStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    const cellStyle = pw.TextStyle(fontSize: 8);
    const cellPad = pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3);

    pw.Widget singleLineCell(
      String text, {
      pw.TextAlign align = pw.TextAlign.center,
      bool bold = false,
    }) {
      return pw.Padding(
        padding: cellPad,
        child: pw.Text(
          text,
          style: bold
              ? cellStyle.copyWith(fontWeight: pw.FontWeight.bold)
              : cellStyle,
          textAlign: align,
          maxLines: 1,
          softWrap: false,
          overflow: pw.TextOverflow.visible,
        ),
      );
    }

    pw.Widget wrapCell(String text) {
      return pw.Padding(
        padding: cellPad,
        child: pw.Text(
          text,
          style: cellStyle,
          textAlign: pw.TextAlign.left,
          // Tanım daralabilir; 2–4 satır kaydırma serbest.
          softWrap: true,
        ),
      );
    }

    pw.Widget headerCell(String text) {
      return pw.Padding(
        padding: cellPad,
        child: pw.Text(
          text,
          style: headerStyle,
          textAlign: pw.TextAlign.center,
          maxLines: 1,
          softWrap: false,
        ),
      );
    }

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          headerCell('#'),
          headerCell('Poz No'),
          headerCell('Tanım'),
          headerCell('Birim'),
          headerCell('Miktar'),
          headerCell('B.F.'),
          headerCell('Tutar'),
        ],
      ),
    ];

    if (project.satirlar.isEmpty) {
      tableRows.add(
        pw.TableRow(
          children: [
            singleLineCell(''),
            singleLineCell(''),
            wrapCell('Henüz poz yok'),
            singleLineCell(''),
            singleLineCell(''),
            singleLineCell(''),
            singleLineCell(''),
          ],
        ),
      );
    } else {
      for (var i = 0; i < project.satirlar.length; i++) {
        final s = project.satirlar[i];
        final miktar = s.hesaplananMetraj;
        final tutar = AnalizHesap.satirTutar(miktar, s.birimFiyati);
        tableRows.add(
          pw.TableRow(
            children: [
              singleLineCell('${i + 1}'),
              singleLineCell(s.pozNo),
              wrapCell(s.analizAdi),
              singleLineCell(
                s.olcuBirimi.trim().isEmpty ? 'ad' : s.olcuBirimi.trim(),
              ),
              singleLineCell(AppFormat.decimal(miktar)),
              singleLineCell(AppFormat.currency(s.birimFiyati)),
              singleLineCell(AppFormat.currency(tutar)),
            ],
          ),
        );
      }
    }

    final genelToplam = project.satirlar.fold<double>(
      0,
      (sum, s) =>
          sum + AnalizHesap.satirTutar(s.hesaplananMetraj, s.birimFiyati),
    );

    tableRows.add(
      pw.TableRow(
        children: [
          singleLineCell(''),
          singleLineCell(''),
          wrapCell(''),
          singleLineCell(''),
          singleLineCell(''),
          singleLineCell('GENEL TOPLAM', bold: true),
          singleLineCell(AppFormat.currency(genelToplam), bold: true),
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(font: titleFont, fontSize: 16),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          pw.Text('Proje: ${project.ad}'),
          if (project.aciklama.trim().isNotEmpty)
            pw.Text('Açıklama: ${project.aciklama}'),
          pw.Text(
            'Tarih: ${AppFormat.date(DateTime.tryParse(project.guncellemeTarihi) ?? DateTime.now())}',
          ),
          pw.Text('Poz Sayısı: ${project.satirlar.length}'),
          pw.SizedBox(height: 12),
          // Poz No / Birim / Miktar / B.F. / Tutar: içerik kadar genişlik (tek satır).
          // Tanım: kalan alanı alır; daralır ve çok satıra kayar.
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: pw.IntrinsicColumnWidth(),
              1: pw.IntrinsicColumnWidth(),
              2: pw.FlexColumnWidth(1),
              3: pw.IntrinsicColumnWidth(),
              4: pw.IntrinsicColumnWidth(),
              5: pw.IntrinsicColumnWidth(),
              6: pw.IntrinsicColumnWidth(),
            },
            children: tableRows,
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
    // Poz No genişliği: başlık veya en uzun poz (tek satır).
    var maxPozChars = 'Poz No'.length;
    for (final s in project.satirlar) {
      if (s.pozNo.length > maxPozChars) maxPozChars = s.pozNo.length;
    }
    final pozWidth = (maxPozChars + 2).clamp(10, 28).toDouble();

    // Stil: 0 meta · 1 başlık · 2 Tanım · 3 vurgu · 4 veri (yatay+düşey orta)
    const sMeta = 0;
    const sHeader = 1;
    const sWrap = 2;
    const sEmphasis = 3;
    const sCenter = 4;

    final rows = <List<_KesifCell>>[
      [_KesifCell('ŞantiJET Maliyet — METRAJ / KEŞİF CETVELİ', style: sEmphasis)],
      [_KesifCell('Proje', style: sHeader), _KesifCell(project.ad, style: sMeta)],
      if (project.aciklama.trim().isNotEmpty)
        [
          _KesifCell('Açıklama', style: sHeader),
          _KesifCell(project.aciklama, style: sMeta),
        ],
      [
        _KesifCell('Tarih', style: sHeader),
        _KesifCell(
          AppFormat.date(
            DateTime.tryParse(project.guncellemeTarihi) ?? DateTime.now(),
          ),
          style: sMeta,
        ),
      ],
      [],
      [
        _KesifCell('#', style: sHeader),
        _KesifCell('Poz No', style: sHeader),
        _KesifCell('Tanım', style: sHeader),
        _KesifCell('Birim', style: sHeader),
        _KesifCell('Miktar', style: sHeader),
        _KesifCell('Birim Fiyat', style: sHeader),
        _KesifCell('Tutar', style: sHeader),
      ],
      for (var i = 0; i < project.satirlar.length; i++)
        [
          _KesifCell('${i + 1}', style: sCenter),
          _KesifCell(project.satirlar[i].pozNo, style: sCenter),
          _KesifCell(project.satirlar[i].analizAdi, style: sWrap),
          _KesifCell(project.satirlar[i].olcuBirimi, style: sCenter),
          _KesifCell(AppFormat.decimal(project.satirlar[i].miktar),
              style: sCenter),
          _KesifCell(AppFormat.currency(project.satirlar[i].birimFiyati),
              style: sCenter),
          _KesifCell(AppFormat.currency(project.satirlar[i].tutar),
              style: sCenter),
        ],
      [
        _KesifCell(''),
        _KesifCell(''),
        _KesifCell(''),
        _KesifCell(''),
        _KesifCell(''),
        _KesifCell('GENEL TOPLAM', style: sEmphasis),
        _KesifCell(AppFormat.currency(project.toplam), style: sEmphasis),
      ],
    ];

    // #: dar · Poz No: dinamik · Tanım: dar (kaydır) · diğerleri rahat.
    // Birim Fiyat / Tutar: başlık + "9.999,99 ₺" tek satır.
    final colWidths = <double>[
      5,
      pozWidth,
      28,
      12,
      12,
      18,
      18,
    ];
    return _simpleXlsx(rows, colWidths);
  }

  Uint8List _simpleXlsx(List<List<_KesifCell>> rows, List<double> colWidths) {
    final archive = Archive();
    void add(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    final colsXml = StringBuffer('<cols>');
    for (var i = 0; i < colWidths.length; i++) {
      final n = i + 1;
      colsXml.write(
        '<col min="$n" max="$n" width="${colWidths[i]}" customWidth="1"/>',
      );
    }
    colsXml.write('</cols>');

    final sheetRows = StringBuffer();
    for (var r = 0; r < rows.length; r++) {
      final rowIndex = r + 1;
      sheetRows.write('<row r="$rowIndex">');
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        sheetRows.write(row[c].toXml('${_colName(c + 1)}$rowIndex'));
      }
      sheetRows.write('</row>');
    }

    add(
      '[Content_Types].xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>',
    );
    add(
      '_rels/.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>',
    );
    add(
      'xl/workbook.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Kesif" sheetId="1" r:id="rId1"/></sheets>'
      '</workbook>',
    );
    add(
      'xl/_rels/workbook.xml.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>',
    );
    add('xl/styles.xml', _kesifStylesXml);
    add(
      'xl/worksheets/sheet1.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '$colsXml'
      '<sheetData>$sheetRows</sheetData>'
      '</worksheet>',
    );
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

  String _safe(String ad) =>
      ad.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_').replaceAll(RegExp(r'_+'), '_');
}

class _KesifCell {
  const _KesifCell(this.value, {this.style = 0});

  final String value;
  final int style;

  String toXml(String ref) {
    final styleAttr = style > 0 ? ' s="$style"' : '';
    return '<c r="$ref" t="inlineStr"$styleAttr>'
        '<is><t>${_escKesif(value)}</t></is></c>';
  }
}

String _escKesif(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// 0: meta · 1: başlık · 2: Tanım kaydır · 3: vurgu · 4: veri ortala
const _kesifStylesXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<fonts count="2">'
    '<font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font>'
    '</fonts>'
    '<fills count="2">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '</fills>'
    '<borders count="2">'
    '<border/>'
    '<border>'
    '<left style="thin"/><right style="thin"/>'
    '<top style="thin"/><bottom style="thin"/>'
    '</border>'
    '</borders>'
    '<cellXfs count="5">'
    // 0 — meta satırlar (sol)
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment wrapText="0" vertical="center" horizontal="left"/>'
    '</xf>'
    // 1 — sütun başlığı
    '<xf fontId="1" fillId="0" borderId="1" applyFont="1" applyBorder="1" applyAlignment="1">'
    '<alignment wrapText="0" vertical="center" horizontal="center"/>'
    '</xf>'
    // 2 — Tanım: kaydırılabilir
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment wrapText="1" vertical="top" horizontal="left"/>'
    '</xf>'
    // 3 — vurgu (toplam / başlık satırı)
    '<xf fontId="1" fillId="0" borderId="1" applyFont="1" applyBorder="1" applyAlignment="1">'
    '<alignment wrapText="0" vertical="center" horizontal="center"/>'
    '</xf>'
    // 4 — sıra/poz/birim/miktar/fiyat/tutar: yatay + düşey orta
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment wrapText="0" vertical="center" horizontal="center"/>'
    '</xf>'
    '</cellXfs>'
    '</styleSheet>';

final kesifExportService = KesifExportService();
