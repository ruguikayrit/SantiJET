import 'dart:io';
import 'dart:ui' show Rect;

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Çok bölümlü PDF raporu için tek bölüm tanımı.
class PdfReportSection {
  const PdfReportSection({
    required this.title,
    this.subtitle,
    this.headers = const [],
    this.rows = const [],
    this.keyValues = const [],
    this.cutCards = const [],
    this.stockLengthM = 12,
    this.compact = false,
    this.cellTones,
    this.emphasizeTotals = false,
  });

  final String title;
  final String? subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final List<(String, String)> keyValues;
  /// Uygulamadaki kesim özet kartlarıyla aynı içerik (görsel bar + formül).
  final List<PdfCutCardData> cutCards;
  final double stockLengthM;
  final bool compact;

  /// Satır/sütun ile aynı boyutta. 1 yeşil, -1 kırmızı, 0 normal.
  final List<List<int>>? cellTones;

  /// Renkli çıktıda TOPLAM satır ve sütunlarına dolgu verir.
  final bool emphasizeTotals;
}

/// PDF’te çizilecek tek kesim özet kartı.
class PdfCutCardData {
  const PdfCutCardData({
    required this.title,
    required this.formula,
    required this.remainder,
    required this.segments,
  });

  final String title;
  final String formula;
  final String remainder;
  final List<PdfCutSegmentData> segments;
}

class PdfCutSegmentData {
  const PdfCutSegmentData({
    required this.lengthM,
    required this.label,
    this.subtitle = '',
    this.isWaste = false,
  });

  final double lengthM;
  final String label;
  final String subtitle;
  final bool isWaste;
}

class ExcelReportSheet {
  const ExcelReportSheet({
    required this.name,
    required this.title,
    required this.headers,
    required this.rows,
    this.cellTones,
    this.emphasizeTotals = false,
  });

  final String name;
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  /// Satır/sütun ile aynı boyutta. 1 yeşil, -1 kırmızı, 0 normal.
  final List<List<int>>? cellTones;

  /// TOPLAM satır ve sütunlarına dolgu verir.
  final bool emphasizeTotals;
}

class ExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<pw.ThemeData> _pdfTheme() async {
    try {
      _regularFont ??= await PdfGoogleFonts.notoSansRegular();
      _boldFont ??= await PdfGoogleFonts.notoSansBold();
      return pw.ThemeData.withFont(
        base: _regularFont!,
        bold: _boldFont!,
      );
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  Future<void> sharePdf({
    required String title,
    required List<List<String>> rows,
    required List<String> headers,
    Rect? sharePositionOrigin,
  }) async {
    final bytes = await _buildPdfBytes(title: title, headers: headers, rows: rows);
    await _shareBytes(
      bytes: bytes,
      fileName: '${_safeFileName(title)}.pdf',
      mimeType: 'application/pdf',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> shareExcel({
    required String title,
    required List<List<String>> rows,
    required List<String> headers,
    Rect? sharePositionOrigin,
  }) async {
    final bytes = _buildExcelBytes(title: title, headers: headers, rows: rows);
    await _shareBytes(
      bytes: bytes,
      fileName: '${_safeFileName(title)}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> previewPdf({
    required String title,
    required List<List<String>> rows,
    required List<String> headers,
  }) async {
    final bytes = await _buildPdfBytes(title: title, headers: headers, rows: rows);
    await previewPdfBytes(bytes);
  }

  Future<void> previewPdfBytes(List<int> bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => Uint8List.fromList(bytes),
    );
  }

  Future<void> sharePdfBytes({
    required List<int> bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  }) async {
    await _shareBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> shareMultiSectionPdf({
    required String title,
    required List<PdfReportSection> sections,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    Rect? sharePositionOrigin,
  }) async {
    final bytes = await buildMultiSectionPdfBytes(
      title: title,
      sections: sections,
      pageFormat: pageFormat,
    );
    await sharePdfBytes(
      bytes: bytes,
      fileName: '${_safeFileName(title)}.pdf',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> previewMultiSectionPdf({
    required String title,
    required List<PdfReportSection> sections,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool colored = true,
  }) async {
    final bytes = await buildMultiSectionPdfBytes(
      title: title,
      sections: sections,
      pageFormat: pageFormat,
      colored: colored,
    );
    await previewPdfBytes(bytes);
  }

  Future<void> shareExcelSheets({
    required String title,
    required List<ExcelReportSheet> sheets,
    Rect? sharePositionOrigin,
    bool stacked = false,
  }) async {
    final bytes = _buildExcelSheetBytes(sheets, stacked: stacked);
    await _shareBytes(
      bytes: bytes,
      fileName: '${_safeFileName(title)}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<List<int>> buildMultiSectionPdfBytes({
    required String title,
    required List<PdfReportSection> sections,
    String? subtitle,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool colored = true,
  }) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    final landscape = pageFormat.width > pageFormat.height;
    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: landscape
            ? const pw.EdgeInsets.all(16)
            : const pw.EdgeInsets.all(32),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              'ŞantiJET DEMİR',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
            pw.SizedBox(height: 4),
            pw.Text(
              'Oluşturulma: ${now.day}.${now.month}.${now.year} '
              '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 24),
          ];

          for (final section in sections) {
            widgets.addAll(_buildSectionWidgets(section, colored: colored));
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  List<pw.Widget> _buildSectionWidgets(
    PdfReportSection section, {
    bool colored = true,
  }) {
    return [
      _SectionGroup(
        unitCount: _sectionUnitCount(section),
        buildLeading: () => _sectionLeading(section, colored: colored),
        buildSlice: (start, end) =>
            _sectionSlice(section, start, end, colored: colored),
      ),
      pw.SizedBox(height: 16),
    ];
  }

  int _sectionUnitCount(PdfReportSection section) {
    if (section.cutCards.isNotEmpty) return section.cutCards.length;
    if (section.rows.isNotEmpty) return section.rows.length;
    if (section.headers.isNotEmpty) return 1;
    return 0;
  }

  pw.Widget _sectionLeading(
    PdfReportSection section, {
    required bool colored,
  }) {
    final navy = PdfColor.fromHex('#1F4E79');
    final polished = colored && section.emphasizeTotals;
    final children = <pw.Widget>[
      if (polished)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(left: 6, bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: navy, width: 3),
              bottom: pw.BorderSide(
                color: PdfColor.fromHex('#D6E6F5'),
                width: 0.8,
              ),
            ),
          ),
          child: pw.Text(
            section.title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: navy,
            ),
          ),
        )
      else
        pw.Text(
          section.title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
    ];

    if (section.subtitle != null && section.subtitle!.isNotEmpty) {
      children.addAll([
        pw.SizedBox(height: 4),
        pw.Text(
          section.subtitle!,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ]);
    }

    if (section.keyValues.isNotEmpty) {
      children.addAll([
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(3),
          },
          children: [
            for (final entry in section.keyValues)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: pw.Text(
                      entry.$1,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: pw.Text(
                      entry.$2,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ]);
    }

    children.add(pw.SizedBox(height: 8));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _sectionSlice(
    PdfReportSection section,
    int start,
    int end, {
    required bool colored,
  }) {
    if (section.cutCards.isNotEmpty) {
      final cards = <pw.Widget>[];
      for (var index = start; index < end; index++) {
        if (cards.isNotEmpty) cards.add(pw.SizedBox(height: 8));
        cards.add(
          _buildCutCardWidget(
            section.cutCards[index],
            stockLengthM: section.stockLengthM,
          ),
        );
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: cards,
      );
    }

    if (section.rows.isEmpty) {
      return pw.Text(
        'Bu bölümde gösterilecek veri yok.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    }

    final rows = section.rows.sublist(start, end);
    final tones = section.cellTones == null
        ? null
        : [
            for (var index = start; index < end && index < section.cellTones!.length; index++)
              section.cellTones![index],
          ];
    final slice = PdfReportSection(
      title: section.title,
      headers: section.headers,
      rows: rows,
      cellTones: tones,
      compact: section.compact,
      emphasizeTotals: section.emphasizeTotals,
    );
    final headerSize = section.compact ? 6.0 : 9.0;
    final cellSize = section.compact ? 5.5 : 8.0;
    final headerColor = colored ? PdfColor.fromHex('#1F4E79') : PdfColors.white;
    final headerText = colored ? PdfColors.white : PdfColors.black;
    final borderColor = colored ? PdfColor.fromHex('#1F4E79') : PdfColors.grey600;
    if (slice.cellTones != null || slice.emphasizeTotals) {
      return _styledTable(
        slice,
        headerSize: headerSize,
        cellSize: cellSize,
        headerColor: headerColor,
        headerText: headerText,
        borderColor: borderColor,
        colored: colored,
      );
    }
    return pw.TableHelper.fromTextArray(
      headers: slice.headers,
      data: slice.rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: headerSize,
        color: headerText,
      ),
      cellStyle: pw.TextStyle(fontSize: cellSize, color: PdfColors.black),
      headerDecoration: pw.BoxDecoration(color: headerColor),
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      cellAlignment:
          section.compact ? pw.Alignment.center : pw.Alignment.centerLeft,
      cellPadding: pw.EdgeInsets.symmetric(
        horizontal: section.compact ? 2 : 5,
        vertical: section.compact ? 2 : 3,
      ),
    );
  }

  pw.Widget _styledTable(
    PdfReportSection section, {
    required double headerSize,
    required double cellSize,
    required PdfColor headerColor,
    required PdfColor headerText,
    required PdfColor borderColor,
    required bool colored,
  }) {
    final totalFill = PdfColor.fromHex('#D6E6F5');
    final totalCrossFill = PdfColor.fromHex('#9FC2E0');
    final stripe = PdfColor.fromHex('#F4F8FC');

    pw.Widget cell(
      String text, {
      required pw.TextStyle style,
      PdfColor? fill,
    }) {
      return pw.Container(
        color: fill,
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.symmetric(
          horizontal: section.compact ? 2 : 5,
          vertical: section.compact ? 2 : 3,
        ),
        child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
      );
    }

    pw.TextStyle toneStyle(int tone, {required bool strong}) {
      final color = switch (tone) {
        > 0 => PdfColor.fromHex('#15803D'),
        < 0 => PdfColor.fromHex('#DC2626'),
        _ => PdfColors.black,
      };
      return pw.TextStyle(
        fontSize: cellSize,
        color: color,
        fontWeight: strong || tone != 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: headerSize,
      color: headerText,
    );

    PdfColor? bodyFill({
      required bool totalRow,
      required bool totalColumn,
      required int rowIndex,
    }) {
      if (!colored || !section.emphasizeTotals) {
        return rowIndex.isOdd && colored ? stripe : null;
      }
      if (totalRow && totalColumn) return totalCrossFill;
      if (totalRow || totalColumn) return totalFill;
      return rowIndex.isOdd ? stripe : null;
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            for (final header in section.headers)
              cell(header, style: headerStyle, fill: headerColor),
          ],
        ),
        for (var rowIndex = 0; rowIndex < section.rows.length; rowIndex++)
          pw.TableRow(
            children: [
              for (var column = 0; column < section.rows[rowIndex].length; column++)
                () {
                  final tone = section.cellTones != null &&
                          rowIndex < section.cellTones!.length &&
                          column < section.cellTones![rowIndex].length
                      ? section.cellTones![rowIndex][column]
                      : 0;
                  final totalRow = section.rows[rowIndex].isNotEmpty &&
                      section.rows[rowIndex].first == 'TOPLAM';
                  final totalColumn = column < section.headers.length &&
                      section.headers[column] == 'TOPLAM';
                  return cell(
                    section.rows[rowIndex][column],
                    style: toneStyle(tone, strong: totalRow || totalColumn),
                    fill: bodyFill(
                      totalRow: totalRow,
                      totalColumn: totalColumn,
                      rowIndex: rowIndex,
                    ),
                  );
                }(),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildCutCardWidget(
    PdfCutCardData card, {
    required double stockLengthM,
  }) {
    final total = stockLengthM <= 0 ? 1.0 : stockLengthM;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            card.title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.SizedBox(
            height: 28,
            child: pw.Row(
              children: [
                for (final segment in card.segments)
                  pw.Expanded(
                    flex: ((segment.lengthM / total) * 1000).round().clamp(1, 100000),
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(right: 1),
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: segment.isWaste
                            ? PdfColors.grey300
                            : PdfColors.indigo100,
                        border: pw.Border.all(
                          color: segment.isWaste
                              ? PdfColors.grey500
                              : PdfColors.indigo400,
                          width: 0.6,
                        ),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                        child: segment.isWaste
                            ? pw.Text(
                                'F',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey700,
                                ),
                              )
                            : pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  if (segment.label.isNotEmpty)
                                    pw.Text(
                                      segment.label,
                                      maxLines: 1,
                                      style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  if (segment.subtitle.isNotEmpty)
                                    pw.Text(
                                      '${segment.subtitle} m',
                                      maxLines: 1,
                                      style: const pw.TextStyle(fontSize: 6),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            card.formula,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            card.remainder,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<int>> _buildPdfBytes({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'ŞantiJET DEMİR',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Oluşturulma: ${now.day}.${now.month}.${now.year} '
            '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ],
      ),
    );

    return doc.save();
  }

  List<int> _buildExcelBytes({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Rapor'];
    excel.setDefaultSheet('Rapor');
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([TextCellValue('ŞantiJET DEMİR — $title')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final row in rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }

    return _encodeExcel(excel);
  }

  List<int> _buildExcelSheetBytes(
    List<ExcelReportSheet> sheets, {
    bool stacked = false,
  }) {
    final excel = Excel.createExcel();
    if (stacked && sheets.isNotEmpty) {
      final sheet = excel[sheets.first.name];
      var rowIndex = 0;
      for (final item in sheets) {
        sheet.appendRow([TextCellValue(item.title)]);
        if (item.emphasizeTotals) {
          sheet.updateCell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            TextCellValue(item.title),
            cellStyle: CellStyle(
              bold: true,
              fontSize: 14,
              fontColorHex: ExcelColor.fromHexString('FF1F4E79'),
            ),
          );
        }
        rowIndex++;
        sheet.appendRow(item.headers.map(TextCellValue.new).toList());
        if (item.emphasizeTotals) {
          _paintExcelHeader(
            sheet,
            rowIndex: rowIndex,
            headers: item.headers,
          );
        }
        rowIndex++;
        for (var index = 0; index < item.rows.length; index++) {
          final row = item.rows[index];
          sheet.appendRow(row.map(TextCellValue.new).toList());
          _paintExcelRow(
            sheet,
            rowIndex: rowIndex,
            row: row,
            headers: item.headers,
            tones: item.cellTones != null && index < item.cellTones!.length
                ? item.cellTones![index]
                : const [],
            emphasizeTotals: item.emphasizeTotals,
          );
          rowIndex++;
        }
        sheet.appendRow([TextCellValue('')]);
        rowIndex++;
      }
      excel.setDefaultSheet(sheets.first.name);
    } else {
      for (final item in sheets) {
        final sheet = excel[item.name];
        sheet.appendRow([TextCellValue(item.title)]);
        sheet.appendRow([TextCellValue('')]);
        sheet.appendRow(item.headers.map(TextCellValue.new).toList());
        for (final row in item.rows) {
          sheet.appendRow(row.map(TextCellValue.new).toList());
        }
      }
      if (sheets.isNotEmpty) {
        excel.setDefaultSheet(sheets.first.name);
      }
    }
    if (excel.sheets.containsKey('Sheet1') &&
        sheets.every((item) => item.name != 'Sheet1')) {
      excel.delete('Sheet1');
    }
    return _encodeExcel(excel);
  }

  void _paintExcelHeader(
    Sheet sheet, {
    required int rowIndex,
    required List<String> headers,
  }) {
    for (var column = 0; column < headers.length; column++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
        TextCellValue(headers[column]),
        cellStyle: CellStyle(
          bold: true,
          fontColorHex: ExcelColor.white,
          backgroundColorHex: ExcelColor.fromHexString('FF1F4E79'),
          horizontalAlign: HorizontalAlign.Center,
        ),
      );
    }
  }

  void _paintExcelRow(
    Sheet sheet, {
    required int rowIndex,
    required List<String> row,
    required List<String> headers,
    required List<int> tones,
    required bool emphasizeTotals,
  }) {
    final totalRow = row.isNotEmpty && row.first == 'TOPLAM';
    for (var column = 0; column < row.length; column++) {
      final tone = column < tones.length ? tones[column] : 0;
      final totalColumn =
          column < headers.length && headers[column] == 'TOPLAM';
      if (!emphasizeTotals && (tone == 0 || row[column].isEmpty)) continue;
      if (emphasizeTotals && !totalRow && !totalColumn && tone == 0) {
        continue;
      }
      final background = !emphasizeTotals
          ? ExcelColor.none
          : totalRow && totalColumn
              ? ExcelColor.fromHexString('FF9FC2E0')
              : totalRow || totalColumn
                  ? ExcelColor.fromHexString('FFD6E6F5')
                  : ExcelColor.none;
      final font = switch (tone) {
        > 0 => ExcelColor.green,
        < 0 => ExcelColor.red,
        _ => ExcelColor.black,
      };
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
        TextCellValue(row[column]),
        cellStyle: CellStyle(
          bold: tone != 0 || totalRow || totalColumn,
          fontColorHex: font,
          backgroundColorHex: background,
          horizontalAlign: HorizontalAlign.Center,
        ),
      );
    }
  }

  List<int> _encodeExcel(Excel excel) {
    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Excel dosyası oluşturulamadı');
    }
    return encoded;
  }

  Future<void> _shareBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    Rect? sharePositionOrigin,
  }) async {
    final origin = sharePositionOrigin ?? const Rect.fromLTWH(8, 8, 8, 8);
    if (kIsWeb) {
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: fileName);
      return;
    }

    final safeName = fileName.isEmpty ? 'rapor' : fileName;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType, name: safeName)],
      text: safeName,
      sharePositionOrigin: origin,
    );
  }

  String _safeFileName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

final exportService = ExportService();

class _GroupContext extends pw.WidgetContext {
  int startRow = 0;
  int endRow = 0;
  bool pending = false;

  @override
  void apply(covariant _GroupContext other) {
    startRow = other.startRow;
    endRow = other.endRow;
    pending = other.pending;
  }

  @override
  pw.WidgetContext clone() {
    final copy = _GroupContext();
    copy.apply(this);
    return copy;
  }
}

/// Başlık ile tablonun ilk satırı aynı sayfada kalır.
/// Uzun tablo devam sayfalarında başlık ve sütun başlığı yeniden yazılır.
class _SectionGroup extends pw.Widget with pw.SpanningWidget {
  _SectionGroup({
    required this.unitCount,
    required this.buildLeading,
    required this.buildSlice,
  });

  final int unitCount;
  final pw.Widget Function() buildLeading;
  final pw.Widget Function(int start, int end) buildSlice;

  final _GroupContext _context = _GroupContext();
  pw.Widget? _child;

  @override
  bool get canSpan => true;

  @override
  bool get hasMoreWidgets => _context.pending || _context.endRow < unitCount;

  @override
  pw.WidgetContext saveContext() => _context;

  @override
  void restoreContext(covariant _GroupContext context) {
    _context
      ..startRow = context.endRow
      ..endRow = context.endRow
      ..pending = false;
  }

  @override
  void layout(
    pw.Context context,
    pw.BoxConstraints constraints, {
    bool parentUsesSize = false,
  }) {
    final width = constraints.maxWidth;
    final start = _context.startRow;
    if (!constraints.hasBoundedHeight) {
      _place(context, width, start, unitCount);
      _context
        ..endRow = unitCount
        ..pending = false;
      return;
    }

    final leadingHeight = _measure(context, width, buildLeading());
    final minBody = start < unitCount
        ? _measure(context, width, buildSlice(start, start + 1))
        : 0.0;
    final fitsTogether = leadingHeight + minBody <= constraints.maxHeight + 0.5;
    if (!fitsTogether && constraints.maxHeight <= 480) {
      _child = null;
      box = PdfRect(0, 0, width, 0);
      _context.pending = true;
      return;
    }

    final budget = constraints.maxHeight - leadingHeight;
    var end = _lastFittingEnd(context, width, start, budget);
    if (end == start && start < unitCount) end = start + 1;
    _place(context, width, start, end);
    _context
      ..endRow = end
      ..pending = false;
  }

  int _lastFittingEnd(
    pw.Context context,
    double width,
    int start,
    double budget,
  ) {
    if (start >= unitCount || budget <= 0) return start;
    if (_measure(context, width, buildSlice(start, start + 1)) > budget + 0.5) {
      return start;
    }
    var best = start + 1;
    var low = start + 1;
    var high = unitCount;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final height = _measure(context, width, buildSlice(start, mid));
      if (height <= budget + 0.5) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return best;
  }

  double _measure(pw.Context context, double width, pw.Widget child) {
    child.layout(context, pw.BoxConstraints(maxWidth: width));
    return child.box?.height ?? 0;
  }

  void _place(pw.Context context, double width, int start, int end) {
    final children = <pw.Widget>[buildLeading()];
    if (end > start) children.add(buildSlice(start, end));
    final column = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
    column.layout(context, pw.BoxConstraints(maxWidth: width));
    _child = column;
    final columnWidth = column.box?.width ?? width;
    final columnHeight = column.box?.height ?? 0;
    box = PdfRect(
      0,
      0,
      columnWidth > width ? columnWidth : width,
      columnHeight,
    );
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final child = _child;
    final bounds = box;
    if (child == null || bounds == null || child.box == null) return;
    child.box = PdfRect(
      bounds.x,
      bounds.y,
      child.box!.width,
      child.box!.height,
    );
    child.paint(context);
  }
}
