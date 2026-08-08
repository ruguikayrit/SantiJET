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

/// Karşılaştırma PDF görünüm stili.
enum ComparePdfStyle {
  /// Renkli font + min/max dolgu.
  colorFilled,

  /// Siyah-beyaz font, dolgusuz (yalnızca çerçeve).
  monoPlain,
}

/// Karşılaştırma raporu dışa aktarma.
class CompareExportService {
  Future<void> sharePdf(
    AnalizCompareResult compare, {
    ComparePdfStyle style = ComparePdfStyle.colorFilled,
  }) async {
    final bytes = await buildPdfBytes(compare, style: style);
    final suffix =
        style == ComparePdfStyle.colorFilled ? 'renkli' : 'siyah_beyaz';
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'karsilastirma_${suffix}_${_stamp()}.pdf',
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

  Future<Uint8List> buildPdfBytes(
    AnalizCompareResult compare, {
    ComparePdfStyle style = ComparePdfStyle.colorFilled,
  }) async {
    final fontBytes = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final font = pw.Font.ttf(fontBytes);
    final boldBytes = await rootBundle.load('assets/fonts/Rajdhani-Bold.ttf');
    final titleFont = pw.Font.ttf(boldBytes);
    final palette = _PdfPalette.forStyle(style);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: font, bold: titleFont),
        build: (context) => [
          pw.Text(
            'ŞantiJET Maliyet — Analiz Karşılaştırması',
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 16,
              color: palette.title,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Tarih: ${AppFormat.date(DateTime.now())} · '
            '${style == ComparePdfStyle.colorFilled ? 'Renkli ve dolgulu' : 'Siyah-beyaz ve dolgusuz'}',
            style: pw.TextStyle(fontSize: 9, color: palette.muted),
          ),
          if (style == ComparePdfStyle.colorFilled) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Yeşil: en düşük tutar · Kırmızı: en yüksek tutar',
              style: pw.TextStyle(fontSize: 8, color: palette.muted),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Text(
            'Birim Fiyat Özeti',
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 12,
              color: palette.title,
            ),
          ),
          pw.SizedBox(height: 6),
          _summaryTable(compare, palette),
          pw.SizedBox(height: 16),
          pw.Text(
            'Kalem Karşılaştırması',
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 12,
              color: palette.title,
            ),
          ),
          pw.SizedBox(height: 6),
          _kalemTable(compare, palette),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _summaryTable(AnalizCompareResult compare, _PdfPalette palette) {
    final headers = ['Analiz', ...compare.analizler.map((a) => a.pozNo)];
    final rows = <_StyledRow>[
      _StyledRow(
        cells: [
          'Malzeme + İşçilik',
          ...compare.analizler.map(
            (a) => '${AppFormat.decimal(a.malzemeIscilikToplami)} TL',
          ),
        ],
      ),
      _StyledRow(
        cells: [
          'Yüklenici Karı',
          ...compare.analizler.map(
            (a) => '${AppFormat.decimal(a.yukleniciKarTutari)} TL',
          ),
        ],
      ),
      _StyledRow(
        cells: [
          '1 Birim Fiyatı',
          ...compare.analizler.map(
            (a) =>
                '${AppFormat.decimal(a.birimFiyati)} TL / ${a.olcuBirimi}',
          ),
        ],
        highlights: [
          _CellTone.none,
          ...compare.analizler.map((a) {
            if (compare.analizler.length < 2) return _CellTone.none;
            if (a.birimFiyati == compare.minBirimFiyati) return _CellTone.min;
            if (a.birimFiyati == compare.maxBirimFiyati) return _CellTone.max;
            return _CellTone.none;
          }),
        ],
      ),
    ];
    return _styledTable(headers: headers, rows: rows, palette: palette);
  }

  pw.Widget _kalemTable(AnalizCompareResult compare, _PdfPalette palette) {
    final headers = [
      'Tip',
      'Poz',
      'Tanım',
      ...compare.analizler.map((a) => a.pozNo),
    ];
    final rows = <_StyledRow>[];
    for (final row in compare.kalemRows) {
      final amounts = compare.analizler
          .map((a) => row.values[a.id]?.tutar)
          .whereType<double>()
          .toList();
      final min =
          amounts.isEmpty ? null : amounts.reduce((a, b) => a < b ? a : b);
      final max =
          amounts.isEmpty ? null : amounts.reduce((a, b) => a > b ? a : b);

      rows.add(
        _StyledRow(
          cells: [
            _tipLabel(row.tip),
            row.pozNo,
            row.tanim,
            ...compare.analizler.map((a) {
              final val = row.values[a.id];
              return val == null ? '—' : AppFormat.decimal(val.tutar);
            }),
          ],
          highlights: [
            _CellTone.none,
            _CellTone.none,
            _CellTone.none,
            ...compare.analizler.map((a) {
              final tutar = row.values[a.id]?.tutar;
              if (tutar == null || min == null || max == null) {
                return _CellTone.none;
              }
              if (min == max) return _CellTone.none;
              if (tutar == min) return _CellTone.min;
              if (tutar == max) return _CellTone.max;
              return _CellTone.none;
            }),
          ],
        ),
      );
    }
    return _styledTable(
      headers: headers,
      rows: rows,
      palette: palette,
      headerFontSize: 8,
      cellFontSize: 7,
    );
  }

  pw.Widget _styledTable({
    required List<String> headers,
    required List<_StyledRow> rows,
    required _PdfPalette palette,
    double headerFontSize = 9,
    double cellFontSize = 8,
  }) {
    pw.Widget cell(
      String text, {
      required bool header,
      _CellTone tone = _CellTone.none,
    }) {
      final fill = header
          ? palette.headerFill
          : switch (tone) {
              _CellTone.min => palette.minFill,
              _CellTone.max => palette.maxFill,
              _CellTone.none => palette.cellFill,
            };
      final color = header
          ? palette.headerText
          : switch (tone) {
              _CellTone.min => palette.minText,
              _CellTone.max => palette.maxText,
              _CellTone.none => palette.cellText,
            };

      return pw.Container(
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: fill == null
            ? null
            : pw.BoxDecoration(color: fill),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: header ? headerFontSize : cellFontSize,
            color: color,
            fontWeight: header || tone != _CellTone.none
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: palette.border, width: 0.6),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          children: [
            for (final h in headers) cell(h, header: true),
          ],
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              for (var i = 0; i < row.cells.length; i++)
                cell(
                  row.cells[i],
                  header: false,
                  tone: i < row.highlights.length
                      ? row.highlights[i]
                      : _CellTone.none,
                ),
            ],
          ),
      ],
    );
  }

  Uint8List buildExcelBytes(AnalizCompareResult compare) {
    return _buildExcel(compare);
  }

  Uint8List _buildExcel(AnalizCompareResult compare) {
    final rows = <List<String>>[
      ['ŞantiJET Maliyet — Analiz Karşılaştırması'],
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

enum _CellTone { none, min, max }

class _StyledRow {
  _StyledRow({
    required this.cells,
    List<_CellTone>? highlights,
  }) : highlights = highlights ?? List.filled(cells.length, _CellTone.none);

  final List<String> cells;
  final List<_CellTone> highlights;
}

class _PdfPalette {
  const _PdfPalette({
    required this.title,
    required this.muted,
    required this.border,
    required this.headerFill,
    required this.headerText,
    required this.cellFill,
    required this.cellText,
    required this.minFill,
    required this.minText,
    required this.maxFill,
    required this.maxText,
  });

  final PdfColor title;
  final PdfColor muted;
  final PdfColor border;
  final PdfColor? headerFill;
  final PdfColor headerText;
  final PdfColor? cellFill;
  final PdfColor cellText;
  final PdfColor? minFill;
  final PdfColor minText;
  final PdfColor? maxFill;
  final PdfColor maxText;

  static _PdfPalette forStyle(ComparePdfStyle style) {
    if (style == ComparePdfStyle.monoPlain) {
      return const _PdfPalette(
        title: PdfColors.black,
        muted: PdfColors.grey700,
        border: PdfColors.black,
        headerFill: null,
        headerText: PdfColors.black,
        cellFill: null,
        cellText: PdfColors.black,
        minFill: null,
        minText: PdfColors.black,
        maxFill: null,
        maxText: PdfColors.black,
      );
    }
    return const _PdfPalette(
      title: PdfColor.fromInt(0xFF0B1220),
      muted: PdfColor.fromInt(0xFF6B7A90),
      border: PdfColor.fromInt(0xFFD5DEEA),
      headerFill: PdfColor.fromInt(0xFF0055FF),
      headerText: PdfColors.white,
      cellFill: PdfColors.white,
      cellText: PdfColor.fromInt(0xFF0B1220),
      minFill: PdfColor.fromInt(0xFFD1FAE5),
      minText: PdfColor.fromInt(0xFF047857),
      maxFill: PdfColor.fromInt(0xFFFEE2E2),
      maxText: PdfColor.fromInt(0xFFB91C1C),
    );
  }
}

final compareExportService = CompareExportService();
