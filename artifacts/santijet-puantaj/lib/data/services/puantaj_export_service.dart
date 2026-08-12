import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_info.dart';
import '../../domain/enums/attendance_status.dart';
import 'puantaj_report_builder.dart';
import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;

/// Puantaj cetvelini PDF / Excel olarak üretir ve paylaşır.
///
/// PDF, uygulamadaki renkli durum rozetleri + firma bandı düzenini takip eder.
class PuantajExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  static const _electricBlue = PdfColor.fromInt(0xFF0055FF);
  static const _electricBlueSoft = PdfColor.fromInt(0xFFE8F0FF);
  static const _emptyCell = PdfColor.fromInt(0xFFD1D5DB);
  static const _rowBorder = PdfColor.fromInt(0xFFE5E7EB);
  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const _brandDark = PdfColor.fromInt(0xFF05070A);

  pw.MemoryImage? _boltImage;
  pw.MemoryImage? _wordmarkImage;

  Future<pw.ThemeData> _pdfTheme() async {
    _regularFont ??= await PdfGoogleFonts.notoSansRegular();
    _boldFont ??= await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );
  }

  // ignore: deprecated_member_use — Flutter SDK Color.value
  static PdfColor _fromFlutter(Color c) => PdfColor.fromInt(c.value);

  Future<void> exportPdf(
    PuantajReportData report, {
    String companyName = '',
    String companyLogoBase64 = '',
  }) async {
    final bytes = await _buildPdfBytes(
      report,
      companyName: companyName,
      companyLogoBase64: companyLogoBase64,
    );
    await file_access.downloadBytesFile(
      fileName: 'santijet-puantaj-${report.fileStem}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: report.title,
    );
  }

  Future<void> exportExcel(PuantajReportData report) async {
    final bytes = _buildExcelBytes(report);
    await file_access.downloadBytesFile(
      fileName: 'santijet-puantaj-${report.fileStem}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: report.title,
    );
  }

  Future<Uint8List> _buildPdfBytes(
    PuantajReportData report, {
    String companyName = '',
    String companyLogoBase64 = '',
  }) async {
    final theme = await _pdfTheme();
    await _loadBrandAssets();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();
    final pageFormat =
        report.landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          _brandHeader(
            companyName: companyName,
            companyLogo: _decodeLogo(companyLogoBase64),
          ),
          pw.SizedBox(height: 8),
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
            '${now.minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
          ),
          pw.SizedBox(height: 10),
          _legend(),
          pw.SizedBox(height: 10),
          if (report.visual.isMatrix)
            _matrixTable(report.visual)
          else
            _dailyTable(report.visual),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  Future<void> _loadBrandAssets() async {
    try {
      _boltImage ??= pw.MemoryImage(
        (await rootBundle.load('assets/images/splash_bolt.png'))
            .buffer
            .asUint8List(),
      );
      _wordmarkImage ??= pw.MemoryImage(
        (await rootBundle.load('assets/images/splash_wordmark_light.png'))
            .buffer
            .asUint8List(),
      );
    } catch (_) {
      // Marka görselleri yüklenemezse başlık metinle üretilir.
    }
  }

  pw.MemoryImage? _decodeLogo(String base64Data) {
    if (base64Data.trim().isEmpty) return null;
    try {
      return pw.MemoryImage(base64Decode(base64Data));
    } catch (_) {
      return null;
    }
  }

  /// Sol üst: firma logosu — sağ üst: ŞantiJET logo + tipografisi.
  pw.Widget _brandHeader({
    required String companyName,
    pw.MemoryImage? companyLogo,
  }) {
    final bolt = _boltImage;
    final wordmark = _wordmarkImage;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
              height: 40,
              width: 170,
              alignment: pw.Alignment.centerLeft,
              child: companyLogo != null
                  ? pw.Image(
                      companyLogo,
                      fit: pw.BoxFit.contain,
                      alignment: pw.Alignment.centerLeft,
                    )
                  : pw.Text(
                      companyName,
                      maxLines: 2,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
            ),
            pw.Container(
              height: 40,
              width: 170,
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (bolt != null) ...[
                        pw.Container(
                          width: 22,
                          height: 22,
                          padding: const pw.EdgeInsets.all(3),
                          decoration: pw.BoxDecoration(
                            color: _brandDark,
                            borderRadius: pw.BorderRadius.circular(5),
                          ),
                          child: pw.Image(bolt, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(width: 6),
                      ],
                      if (wordmark != null)
                        pw.SizedBox(
                          width: 92,
                          height: 15,
                          child: pw.Image(wordmark, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Text(
                          AppInfo.displayName,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    AppInfo.productLabel,
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.8,
                      color: _electricBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 0.8, color: _rowBorder),
      ],
    );
  }

  pw.Widget _legend() {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final s in AttendanceStatus.values)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _statusBadge(s, size: 12),
              pw.SizedBox(width: 3),
              pw.Text(
                s.label,
                style: const pw.TextStyle(fontSize: 7, color: _inkMuted),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _statusBadge(AttendanceStatus? status, {double size = 11}) {
    final bg = status != null ? _fromFlutter(status.color) : _emptyCell;
    final label = status?.short ?? '–';
    final fontSize = label.length > 1 ? size * 0.55 : size * 0.72;
    return pw.Container(
      width: size + 2,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          color: status != null ? PdfColors.white : _inkMuted,
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _matrixTable(PuantajReportVisual visual) {
    final dayCount = visual.dayHeaders.length;
    // A4 landscape ~842pt kullanılabilir; isim + günler + durum özetleri.
    const nameW = 72.0;
    const summaryW = 29.0;
    const totalW = 34.0;
    final summaryTotalW = AttendanceStatus.values.length * summaryW;
    final dayW = dayCount <= 0
        ? 14.0
        : ((842 - 36 - nameW - summaryTotalW - totalW) / dayCount)
            .clamp(8.0, 22.0);
    final tableW = nameW + dayCount * dayW + summaryTotalW + totalW;

    pw.Widget dayCell(pw.Widget child) => pw.SizedBox(
          width: dayW,
          child: pw.Center(child: child),
        );
    pw.Widget summaryCell(pw.Widget child) => pw.SizedBox(
          width: summaryW,
          child: pw.Center(child: child),
        );
    final statusTotals = List<int>.filled(AttendanceStatus.values.length, 0);
    for (final company in visual.companies) {
      for (final row in company.rows) {
        for (var i = 0; i < row.statusCounts.length; i++) {
          statusTotals[i] += row.statusCounts[i];
        }
      }
    }
    final generalTotal = statusTotals.asMap().entries.fold<int>(
          0,
          (sum, entry) {
            final status = AttendanceStatus.values[entry.key];
            return status.countsInGeneralTotal ? sum + entry.value : sum;
          },
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.SizedBox(
              width: nameW,
              child: pw.Text(
                'Personel',
                style: const pw.TextStyle(fontSize: 7, color: _inkMuted),
              ),
            ),
            for (final h in visual.dayHeaders)
              dayCell(
                pw.Text(
                  h,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 6, color: _inkMuted),
                ),
              ),
            for (final s in AttendanceStatus.values)
              summaryCell(
                pw.Text(
                  switch (s) {
                    AttendanceStatus.present => 'Mevcut',
                    AttendanceStatus.half => 'Yarım',
                    AttendanceStatus.giris => 'Giriş',
                    AttendanceStatus.cikis => 'Çıkış',
                    AttendanceStatus.izinli => 'İzinli',
                    AttendanceStatus.raporlu => 'Raporlu',
                    AttendanceStatus.mazeret => 'Maz.',
                    AttendanceStatus.tatil => 'Res.\nTatil',
                    AttendanceStatus.haftaTatili => 'HT',
                    AttendanceStatus.absent => 'Yok',
                  },
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 5.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _fromFlutter(s.color),
                  ),
                ),
              ),
            pw.SizedBox(
              width: totalW,
              child: pw.Text(
                'Genel\nToplam',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7, color: _inkMuted),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        for (final company in visual.companies) ...[
          pw.Container(
            width: tableW,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            color: _electricBlueSoft,
            child: pw.Text(
              company.name,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _electricBlue,
              ),
            ),
          ),
          for (final row in company.rows)
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _rowBorder, width: 0.5),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: nameW,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            row.name,
                            maxLines: 2,
                            style: const pw.TextStyle(fontSize: 7, color: _ink),
                          ),
                          for (final line in row.employmentDateLines)
                            pw.Text(
                              line,
                              maxLines: 1,
                              style: const pw.TextStyle(
                                fontSize: 5.5,
                                color: _inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  for (final s in row.statuses)
                    dayCell(_statusBadge(s, size: dayW > 14 ? 11 : 9)),
                  for (var i = 0; i < AttendanceStatus.values.length; i++)
                    summaryCell(
                      pw.Text(
                        i < row.statusCounts.length
                            ? '${row.statusCounts[i]}'
                            : '0',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: _fromFlutter(
                            AttendanceStatus.values[i].color,
                          ),
                        ),
                      ),
                    ),
                  pw.SizedBox(
                    width: totalW,
                    child: pw.Text(
                      row.totalLabel,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: row.totalLabel == '–'
                            ? _inkMuted
                            : _fromFlutter(AttendanceStatus.present.color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (visual.footerPresentCounts.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.SizedBox(
                width: nameW,
                child: pw.Text(
                  'Toplam',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              for (final c in visual.footerPresentCounts)
                dayCell(
                  pw.Text(
                    c > 0 ? '$c' : '–',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: c > 0
                          ? _fromFlutter(AttendanceStatus.present.color)
                          : _inkMuted,
                    ),
                  ),
                ),
              for (var i = 0; i < AttendanceStatus.values.length; i++)
                summaryCell(
                  pw.Text(
                    '${statusTotals[i]}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: _fromFlutter(AttendanceStatus.values[i].color),
                    ),
                  ),
                ),
              pw.SizedBox(
                width: totalW,
                child: pw.Text(
                  '$generalTotal',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: _fromFlutter(AttendanceStatus.present.color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget _dailyTable(PuantajReportVisual visual) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final company in visual.companies) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: _electricBlueSoft,
            child: pw.Text(
              company.name,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _electricBlue,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          for (final row in company.rows)
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _rowBorder, width: 0.5),
                ),
              ),
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          row.name,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                        if (row.team.isNotEmpty)
                          pw.Text(
                            row.team,
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: _inkMuted,
                            ),
                          ),
                        for (final line in row.employmentDateLines)
                          pw.Text(
                            line,
                            style: const pw.TextStyle(
                              fontSize: 6.5,
                              color: _inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _statusBadge(
                    row.statuses.isEmpty ? null : row.statuses.first,
                    size: 14,
                  ),
                  pw.SizedBox(width: 6),
                  pw.SizedBox(
                    width: 70,
                    child: pw.Text(
                      (row.statuses.isEmpty ? null : row.statuses.first)
                              ?.label ??
                          '—',
                      style: const pw.TextStyle(fontSize: 8, color: _ink),
                    ),
                  ),
                  pw.SizedBox(
                    width: 48,
                    child: pw.Text(
                      row.yevmiye.isEmpty ? '' : '${row.yevmiye} yv',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 8),
        ],
      ],
    );
  }

  List<int> _buildExcelBytes(PuantajReportData report) {
    final excel = Excel.createExcel();
    final sheet = excel['Puantaj'];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow(
      [TextCellValue('${AppInfo.displayName} — ${report.title}')],
    );
    sheet.appendRow([TextCellValue(report.subtitle)]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(report.headers.map(TextCellValue.new).toList());
    for (final row in report.rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }

    return excel.encode()!;
  }
}

final puantajExportService = PuantajExportService();
