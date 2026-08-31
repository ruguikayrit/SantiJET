import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/site_task.dart';
import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;
import 'task_report_builder.dart';
import 'xlsx_image_embedder.dart';

/// Saha görevlerini PDF / Excel olarak üretir ve paylaşır.
class TaskExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const _headerBg = PdfColor.fromInt(0xFFE8F0FF);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _blue = PdfColor.fromInt(0xFF0055FF);

  Future<pw.ThemeData> _pdfTheme() async {
    _regularFont ??= await PdfGoogleFonts.notoSansRegular();
    _boldFont ??= await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );
  }

  Future<void> exportPdf(TaskReportData report) async {
    final bytes = await _buildPdfBytes(report);
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: report.title,
    );
  }

  Future<void> exportExcel(TaskReportData report) async {
    final bytes = _buildExcelBytes(report);
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.xlsx',
      bytes: Uint8List.fromList(bytes),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: report.title,
    );
  }

  Future<Uint8List> _buildPdfBytes(TaskReportData report) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          pw.Text(
            report.title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            report.subtitle,
            style: const pw.TextStyle(fontSize: 10, color: _inkMuted),
          ),
          pw.Text(
            'Oluşturulma: ${now.day.toString().padLeft(2, '0')}.'
            '${now.month.toString().padLeft(2, '0')}.${now.year} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')} · '
            '${report.taskCount} görev',
            style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
          ),
          pw.SizedBox(height: 12),
          if (report.rows.isEmpty)
            pw.Text(
              'Seçilen filtrede görev yok.',
              style: const pw.TextStyle(fontSize: 11, color: _inkMuted),
            )
          else
            _table(report.headers, report.rows),
          ..._photoSection(report.photoGroups),
        ],
      ),
    );

    return doc.save();
  }

  List<pw.Widget> _photoSection(List<TaskReportPhotoGroup> groups) {
    if (groups.isEmpty) return const [];

    final out = <pw.Widget>[
      pw.SizedBox(height: 18),
      pw.Text(
        'FOTOĞRAFLAR',
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _blue,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Container(height: 0.8, color: _border),
      pw.SizedBox(height: 10),
    ];

    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            '#${group.index}  ${group.title}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
      );
      out.addAll(_photoRows(group.photos));
      // Madde (görev) fotoğrafları arası yatay ayırıcı.
      out.add(pw.SizedBox(height: 8));
      out.add(pw.Container(height: 0.9, color: _border));
      out.add(pw.SizedBox(height: g < groups.length - 1 ? 10 : 4));
    }

    return out;
  }

  List<pw.Widget> _photoRows(List<TaskPhoto> photos) {
    const perRow = 4;
    const cellHeight = 78.0;
    final out = <pw.Widget>[];

    for (var i = 0; i < photos.length; i += perRow) {
      final chunk = photos.skip(i).take(perRow).toList();
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final photo in chunk)
                pw.Expanded(child: _photoCell(photo, cellHeight)),
              for (var pad = chunk.length; pad < perRow; pad++)
                pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ),
      );
    }
    return out;
  }

  pw.Widget _photoCell(TaskPhoto photo, double height) {
    pw.MemoryImage? img;
    try {
      if (photo.dataBase64.isNotEmpty) {
        img = pw.MemoryImage(base64Decode(photo.dataBase64));
      }
    } catch (_) {
      img = null;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 2),
      child: img != null
          ? pw.Container(
              height: height,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border, width: 0.5),
              ),
              child: pw.Image(
                img,
                height: height - 2,
                fit: pw.BoxFit.contain,
              ),
            )
          : pw.Container(
              height: height * 0.35,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Yüklenemedi',
                style: const pw.TextStyle(fontSize: 7, color: _inkMuted),
              ),
            ),
    );
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    final headerStyle = pw.TextStyle(
      fontSize: 7.5,
      fontWeight: pw.FontWeight.bold,
      color: _blue,
      lineSpacing: 1.5,
    );
    // Widget başlık: \\n satırları ortalanmış kalsın.
    final headerWidgets = <pw.Widget>[
      for (final h in headers)
        pw.Text(
          h,
          textAlign: pw.TextAlign.center,
          style: headerStyle,
        ),
    ];
    return pw.TableHelper.fromTextArray(
      headers: headerWidgets,
      data: [
        for (final row in rows)
          [
            for (var i = 0; i < headers.length; i++)
              i < row.length ? row[i] : '',
          ],
      ],
      headerStyle: headerStyle,
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        1: const pw.FlexColumnWidth(1.6),
        2: const pw.FixedColumnWidth(42),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.1),
        5: const pw.FixedColumnWidth(46),
        6: const pw.FixedColumnWidth(50),
        7: const pw.FixedColumnWidth(42),
        8: const pw.FixedColumnWidth(50),
        9: const pw.FixedColumnWidth(46),
        // Açıklama — kalan alanın büyük kısmı.
        10: const pw.FlexColumnWidth(3.4),
      },
    );
  }

  List<int> _buildExcelBytes(TaskReportData report) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // —— Görevler tablosu (PDF ile aynı kolonlar) ——
    final sheet = excel['Görevler'];
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue(report.title);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = TextCellValue(
      '${report.subtitle} · ${report.taskCount} görev',
    );

    const headerRow = 3;
    // Sütun genişlikleri: tarih kolonları dar (2 satır başlık), Açıklama max.
    const excelColWidths = <double>[
      4, // #
      22, // Başlık
      11, // Etiket
      14, // Kategori
      16, // Atanan
      12, // Planlanan Başlangıç
      13, // Gerçekleşen Başlangıç
      11, // Planlanan Bitiş
      13, // Gerçekleşen Bitiş
      12, // Durum
      48, // Açıklama (maksimum)
    ];
    for (var c = 0; c < excelColWidths.length; c++) {
      sheet.setColumnWidth(c, excelColWidths[c]);
    }
    sheet.setRowHeight(headerRow, 32);

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );
    for (var c = 0; c < report.headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRow),
      );
      cell.value = TextCellValue(report.headers[c]);
      cell.cellStyle = headerStyle;
    }
    for (var r = 0; r < report.rows.length; r++) {
      final row = report.rows[r];
      for (var c = 0; c < report.headers.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: c,
            rowIndex: headerRow + 1 + r,
          ),
        );
        cell.value = TextCellValue(c < row.length ? row[c] : '');
        if (c == 10) {
          cell.cellStyle = CellStyle(textWrapping: TextWrapping.WrapText);
        }
      }
    }

    // —— Fotoğraflar sekmesi (PDF: satırda 4 görsel) ——
    const photosSheetName = 'Fotoğraflar';
    final photosSheet = excel[photosSheetName];
    photosSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('FOTOĞRAFLAR');
    photosSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = TextCellValue(
      report.photoGroups.isEmpty
          ? 'Bu filtrede fotoğraf yok.'
          : '${report.photoGroups.length} görev · satırda 4 fotoğraf',
    );

    for (var c = 0; c < 4; c++) {
      photosSheet.setColumnWidth(c, 18);
    }

    final placements = <XlsxImagePlacement>[];
    var row = 3;
    for (final group in report.photoGroups) {
      photosSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('#${group.index}  ${group.title}');
      row++;

      var col = 0;
      for (final photo in group.photos) {
        Uint8List? bytes;
        try {
          if (photo.dataBase64.trim().isNotEmpty) {
            bytes = base64Decode(photo.dataBase64);
          }
        } catch (_) {
          bytes = null;
        }
        if (bytes == null || bytes.isEmpty) {
          photosSheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
              )
              .value = TextCellValue('(yüklenemedi)');
        } else {
          placements.add(
            XlsxImagePlacement(row: row, column: col, bytes: bytes),
          );
          photosSheet.setRowHeight(row, 72);
        }
        col++;
        if (col >= 4) {
          col = 0;
          row++;
        }
      }
      if (col != 0) row++;
      row++; // görevler arası boşluk
    }

    final encoded = excel.encode();
    if (encoded == null) return const [];
    if (placements.isEmpty) return encoded;

    return embedImagesInXlsx(
      xlsxBytes: encoded,
      sheetName: photosSheetName,
      placements: placements,
      imageWidthPx: 120,
      imageHeightPx: 90,
    );
  }
}

final taskExportService = TaskExportService();
