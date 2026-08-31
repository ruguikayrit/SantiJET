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
      bytes: bytes,
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

    for (final group in groups) {
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
      out.add(pw.SizedBox(height: 10));
    }

    return out;
  }

  List<pw.Widget> _photoRows(List<TaskPhoto> photos) {
    const perRow = 3;
    const cellHeight = 110.0;
    final out = <pw.Widget>[];

    for (var i = 0; i < photos.length; i += perRow) {
      final chunk = photos.skip(i).take(perRow).toList();
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
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
      margin: const pw.EdgeInsets.symmetric(horizontal: 3),
      child: img != null
          ? pw.Container(
              height: height,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border, width: 0.6),
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
                style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
              ),
            ),
    );
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    final flatHeaders = [
      for (final h in headers) h.replaceAll('\n', ' '),
    ];
    return pw.TableHelper.fromTextArray(
      headers: flatHeaders,
      data: [
        for (final row in rows)
          [
            for (var i = 0; i < flatHeaders.length; i++)
              i < row.length ? row[i] : '',
          ],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _blue,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(2.2),
        2: const pw.FixedColumnWidth(48),
        3: const pw.FlexColumnWidth(1.1),
        4: const pw.FlexColumnWidth(1.3),
        5: const pw.FixedColumnWidth(54),
        6: const pw.FixedColumnWidth(54),
        7: const pw.FixedColumnWidth(54),
        8: const pw.FixedColumnWidth(54),
        9: const pw.FixedColumnWidth(54),
        10: const pw.FlexColumnWidth(1.8),
      },
    );
  }

  List<int> _buildExcelBytes(TaskReportData report) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel['Görevler'];
    for (var c = 0; c < report.headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = TextCellValue(report.headers[c].replaceAll('\n', ' '));
    }
    for (var r = 0; r < report.rows.length; r++) {
      final row = report.rows[r];
      for (var c = 0; c < report.headers.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(c < row.length ? row[c] : '');
      }
    }
    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: report.rows.length + 2,
          ),
        )
        .value = TextCellValue(
      '${report.title} · ${report.subtitle} · ${report.taskCount} görev',
    );
    return excel.encode()!;
  }
}

final taskExportService = TaskExportService();
