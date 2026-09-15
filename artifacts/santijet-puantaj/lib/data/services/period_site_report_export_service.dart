import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_info.dart';
import '../../domain/enums/attendance_status.dart';
import '../../features/daily_report/widgets/period_production_chart_slices.dart';
import 'period_site_report_builder.dart';
import 'period_site_report_export_sections.dart';
import 'period_site_report_pdf_chart_capture.dart';
import 'production_chart_options.dart';
import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;

/// Haftalık / aylık birleşik saha raporu — puantaj + imalat + verim.
class PeriodSiteReportExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const _headerBg = PdfColor.fromInt(0xFFE8F0FF);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _line = PdfColor.fromInt(0xFFCBD5E1);

  PeriodSiteReportPdfChartBundle? _chartsForPdf(
    PeriodSiteReportPdfChartBundle? charts,
  ) {
    if (charts == null) return null;
    final hasAny =
        charts.imalatBlocks.isNotEmpty || charts.verimBlocks.isNotEmpty;
    return hasAny ? charts : null;
  }

  Future<pw.ThemeData> _pdfTheme() async {
    _regularFont ??= await PdfGoogleFonts.notoSansRegular();
    _boldFont ??= await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );
  }

  Future<void> exportPdf(
    PeriodSiteReportData report, {
    required String projectName,
    String companyName = '',
    PeriodSiteReportExportSections sections =
        const PeriodSiteReportExportSections(),
    PeriodSiteReportPdfChartBundle? charts,
  }) async {
    final effectiveCharts = _chartsForPdf(charts);
    final bytes = await _buildPdfBytes(
      report,
      projectName: projectName,
      companyName: companyName,
      sections: sections,
      charts: effectiveCharts,
    );
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: '${report.periodLabel} saha raporu',
    );
  }

  Future<void> exportExcel(
    PeriodSiteReportData report, {
    required String projectName,
    PeriodSiteReportExportSections sections =
        const PeriodSiteReportExportSections(),
    ProductionChartOptions chartOptions = const ProductionChartOptions(),
  }) async {
    final bytes = _buildExcelBytes(
      report,
      projectName: projectName,
      sections: sections,
      chartOptions: chartOptions,
    );
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: '${report.periodLabel} saha raporu',
    );
  }

  Future<Uint8List> _buildPdfBytes(
    PeriodSiteReportData report, {
    required String projectName,
    required String companyName,
    required PeriodSiteReportExportSections sections,
    PeriodSiteReportPdfChartBundle? charts,
  }) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();
    final body = <pw.Widget>[
      pw.Text(
        '${report.periodLabel} Saha Raporu',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '$projectName · ${report.rangeLabel}',
        style: const pw.TextStyle(fontSize: 10, color: _inkMuted),
      ),
      if (companyName.isNotEmpty)
        pw.Text(
          companyName,
          style: const pw.TextStyle(fontSize: 9, color: _inkMuted),
        ),
      pw.Text(
        '${AppInfo.displayName} · ${now.day.toString().padLeft(2, '0')}.'
        '${now.month.toString().padLeft(2, '0')}.${now.year}',
        style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
      ),
      pw.SizedBox(height: 12),
    ];

    /// Sonraki başlık yeni sayfada açılsın (puantaj özeti+personel hariç).
    var breakBeforeNextSection = false;

    void startSectionPage() {
      if (breakBeforeNextSection) {
        body.add(pw.NewPage());
      }
      breakBeforeNextSection = true;
    }

    if (sections.puantajCounts) {
      body.add(_pdfSectionTitle('Puantaj özeti'));
      body.add(pw.SizedBox(height: 6));
      body.add(_pdfPuantajOzet(report.puantajOzet));
      body.add(pw.SizedBox(height: 12));
    }
    if (sections.personel) {
      body.add(_pdfSectionTitle('Personel puantajı'));
      body.add(pw.SizedBox(height: 6));
      body.add(
        _pdfTable(
          PeriodPersonelSummary.headers,
          report.personelSummary.exportRows,
        ),
      );
      if (report.personelSummary.summaryLines.isNotEmpty) {
        body.add(pw.SizedBox(height: 4));
        for (final line in report.personelSummary.summaryLines) {
          body.add(
            pw.Text(
              line,
              style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
            ),
          );
        }
      }
      body.add(pw.SizedBox(height: 12));
    }
    // Özet + personel aynı sayfada; sonraki başlıklar ayrı sayfa.
    if (sections.puantajCounts || sections.personel) {
      breakBeforeNextSection = true;
    }

    if (sections.ekip) {
      startSectionPage();
      body.add(_pdfSectionTitle('Ekip puantajı'));
      body.add(pw.SizedBox(height: 6));
      body.add(
        _pdfTable(
          report.ekipPuantaj.headers,
          report.ekipPuantaj.rowsWithTotals,
        ),
      );
      if (report.ekipPuantaj.summaryLines.isNotEmpty) {
        body.add(pw.SizedBox(height: 4));
        for (final line in report.ekipPuantaj.summaryLines) {
          body.add(
            pw.Text(
              line,
              style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
            ),
          );
        }
      }
      body.add(pw.SizedBox(height: 12));
    }
    if (sections.yevmiyeli) {
      startSectionPage();
      body.add(_pdfSectionTitle('Yevmiyeli işler'));
      body.add(pw.SizedBox(height: 6));
      body.add(
        _pdfTable(report.yevmiyeli.headers, report.yevmiyeli.rowsWithTotals),
      );
      if (report.yevmiyeli.summaryLines.isNotEmpty) {
        body.add(pw.SizedBox(height: 4));
        for (final line in report.yevmiyeli.summaryLines) {
          body.add(
            pw.Text(
              line,
              style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
            ),
          );
        }
      }
      body.add(pw.SizedBox(height: 12));
    }
    if (sections.imalat) {
      startSectionPage();
      body.add(_pdfSectionTitle('Yapılan işler (İmalat)'));
      body.add(pw.SizedBox(height: 6));
      if (charts != null && charts.imalatBlocks.isNotEmpty) {
        for (final block in charts.imalatBlocks) {
          body.add(_pdfEmbeddedChart(block));
          body.add(pw.SizedBox(height: 10));
        }
      } else {
        final metrajBars = [
          for (final r in report.imalatRows)
            (label: r.name, value: r.periodQty, unit: r.unit),
        ]..sort((a, b) => b.value.compareTo(a.value));
        if (metrajBars.isNotEmpty) {
          body.add(_pdfSectionSubtitle('Dönem metraj grafiği'));
          body.add(pw.SizedBox(height: 4));
          body.add(
            _pdfBarChart(
              metrajBars.take(10).map((e) => (e.label, e.value)).toList(),
              unitHint: metrajBars.first.unit,
            ),
          );
          body.add(pw.SizedBox(height: 8));
        }
        body.add(_pdfSectionSubtitle('İmalat detayı'));
        body.add(pw.SizedBox(height: 4));
        body.add(
          _pdfTable(
            const [
              'İmalat',
              'Konum',
              'Ekip',
              'Dönem',
              'Birim',
              'Adam-gün',
              'Kümülatif',
              'Plan',
              '%',
            ],
            [
              for (final r in report.imalatRows)
                [
                  r.name,
                  r.location,
                  r.teamName,
                  _fmt(r.periodQty),
                  r.unit,
                  _fmt(r.periodLaborDays),
                  _fmt(r.totalQty),
                  _fmt(r.plannedQty),
                  '${r.progressPct.toStringAsFixed(0)}%',
                ],
            ],
          ),
        );
      }
      body.add(pw.SizedBox(height: 12));
    }
    if (sections.verim) {
      startSectionPage();
      body.add(_pdfSectionTitle('Verim'));
      body.add(pw.SizedBox(height: 6));
      if (charts != null && charts.verimBlocks.isNotEmpty) {
        for (final block in charts.verimBlocks) {
          body.add(_pdfEmbeddedChart(block));
          body.add(pw.SizedBox(height: 10));
        }
      } else {
        var planAg = 0.0;
        var actualAg = 0.0;
        for (final r in report.verimRows) {
          planAg += r.plannedWorkerDays;
          actualAg += r.periodActualWorkerDays;
        }
        if (planAg > 0 || actualAg > 0) {
          body.add(_pdfSectionSubtitle('Adam-gün · plan ve dönem'));
          body.add(pw.SizedBox(height: 4));
          body.add(
            _pdfBarChart([
              ('Plan', planAg),
              ('Dönem', actualAg),
            ], unitHint: 'AG'),
          );
          body.add(pw.SizedBox(height: 8));
        }
        final effBars = [
          for (final r in report.verimRows)
            if (r.unitEfficiency != null)
              (r.imalatName, r.unitEfficiency! * 100),
        ]..sort((a, b) => b.$2.compareTo(a.$2));
        if (effBars.isNotEmpty) {
          body.add(_pdfSectionSubtitle('Birim verim (dönem, %)'));
          body.add(pw.SizedBox(height: 4));
          body.add(
            _pdfBarChart(
              effBars.take(10).map((e) => (e.$1, e.$2)).toList(),
              unitHint: '%',
            ),
          );
          body.add(pw.SizedBox(height: 8));
        }
        body.add(_pdfSectionSubtitle('Verim detayı'));
        body.add(pw.SizedBox(height: 4));
        body.add(
          _pdfTable(
            const [
              'İmalat',
              'Plan AG',
              'Dönem AG',
              'Plan metraj',
              'Dönem metraj',
              'Verim',
            ],
            [
              for (final r in report.verimRows)
                [
                  r.imalatName,
                  _fmt(r.plannedWorkerDays),
                  _fmt(r.periodActualWorkerDays),
                  r.plannedQty != null ? _fmt(r.plannedQty!) : '—',
                  _fmt(r.periodActualQty),
                  r.unitEfficiency != null
                      ? '%${(r.unitEfficiency! * 100).toStringAsFixed(0)}'
                      : '—',
                ],
            ],
          ),
        );
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => body,
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _pdfPuantajOzet(PeriodPuantajOzet ozet) {
    final boxes = <pw.Widget>[
      for (final s in AttendanceStatus.values)
        _statBox(s.label, '${ozet.countOf(s)}'),
      _statBox('Personel', '${ozet.personnelCount}'),
      if (ozet.unrecorded > 0) _statBox('Girilmedi', '${ozet.unrecorded}'),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(children: boxes.take(6).toList()),
        if (boxes.length > 6) ...[
          pw.SizedBox(height: 4),
          pw.Row(children: boxes.skip(6).toList()),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          'Adam-saat: ${_fmt(ozet.totalAdamSaat)} · '
          'Yevmiye: ${PeriodPuantajOzet.fmtYv(ozet.totalYevmiye)}'
          '${ozet.totalTeamWorkers > 0 ? ' · Ekip: ${ozet.totalTeamWorkers} kişi' : ''}',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9, color: _inkMuted),
        ),
      ],
    );
  }

  pw.Widget _statBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.6),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              maxLines: 2,
              style: const pw.TextStyle(fontSize: 6.5, color: _inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
  }

  pw.Widget _pdfEmbeddedChart(PeriodSiteReportPdfChartImage chart) {
    const maxWidth = 760.0;
    final scale = maxWidth / chart.logicalWidth;
    return pw.Image(
      pw.MemoryImage(chart.bytes),
      width: maxWidth,
      height: chart.logicalHeight * scale,
      fit: pw.BoxFit.contain,
    );
  }

  pw.Widget _pdfSectionSubtitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _inkMuted,
      ),
    );
  }

  pw.Widget _pdfBarChart(
    List<(String, double)> items, {
    required String unitHint,
  }) {
    if (items.isEmpty) {
      return pw.Text(
        'Grafik için veri yok',
        style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
      );
    }
    final maxV = items.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    final top = maxV <= 0 ? 1.0 : maxV;
    return pw.Column(
      children: [
        for (final item in items)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 72,
                  child: pw.Text(
                    item.$1,
                    maxLines: 2,
                    style: const pw.TextStyle(fontSize: 7, color: _ink),
                  ),
                ),
                pw.Expanded(
                  child: pw.Container(
                    height: 7,
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      width: (item.$2 / top) * 280,
                      height: 7,
                      color: _headerBg,
                    ),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  unitHint == '%'
                      ? '%${_fmt(item.$2)}'
                      : '${_fmt(item.$2)} $unitHint',
                  style: const pw.TextStyle(fontSize: 7, color: _ink),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _pdfTable(List<String> headers, List<List<String>> rows) {
    if (rows.isEmpty) {
      return pw.Text(
        'Kayıt yok',
        style: const pw.TextStyle(fontSize: 9, color: _inkMuted),
      );
    }
    final flatHeaders = [
      for (final h in headers) h.replaceAll('\n', ' '),
    ];
    return pw.TableHelper.fromTextArray(
      headers: flatHeaders,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: _ink,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      border: pw.TableBorder.all(color: _border, width: 0.4),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
  }

  List<int> _buildExcelBytes(
    PeriodSiteReportData report, {
    required String projectName,
    required PeriodSiteReportExportSections sections,
    ProductionChartOptions chartOptions = const ProductionChartOptions(),
  }) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _writeSheet(
      excel,
      'Kapak',
      ['Alan', 'Değer'],
      [
        ['Proje', projectName],
        ['Dönem', report.periodLabel],
        ['Aralık', report.rangeLabel],
        if (sections.imalat)
          ['İmalat kalemi', '${report.imalatRows.length}'],
        if (sections.verim) ['Verim satırı', '${report.verimRows.length}'],
        if (sections.personel)
          for (final line in report.personelSummary.summaryLines)
            ['Personel puantaj', line],
        if (sections.ekip)
          for (final line in report.ekipPuantaj.summaryLines)
            ['Ekip puantaj', line],
        if (sections.yevmiyeli)
          for (final line in report.yevmiyeli.summaryLines)
            ['Yevmiyeli', line],
      ],
    );
    if (sections.puantajCounts) {
      _writeSheet(
        excel,
        'Puantaj özeti',
        const ['Durum', 'Adet'],
        report.puantajOzet.exportRows,
      );
    }
    if (sections.personel) {
      _writeSheet(
        excel,
        'Personel',
        PeriodPersonelSummary.headers,
        report.personelSummary.exportRows,
      );
    }
    if (sections.ekip) {
      _writeSheet(
        excel,
        'Ekip',
        report.ekipPuantaj.headers,
        report.ekipPuantaj.rowsWithTotals,
      );
    }
    if (sections.yevmiyeli) {
      _writeSheet(
        excel,
        'Yevmiyeli',
        report.yevmiyeli.headers,
        report.yevmiyeli.rowsWithTotals,
      );
    }
    if (sections.imalat) {
      if (report.imalatGroupSummaries.isNotEmpty) {
        _writeSheet(
          excel,
          'İmalat grup',
          const ['Grup', 'İmalat adet', 'Süre', 'Adam-gün'],
          [
            for (final g in report.imalatGroupSummaries)
              [
                g.title,
                '${g.itemCount}',
                g.axes.length > 0 ? g.axes[0].detail : '—',
                g.axes.length > 1 ? g.axes[1].detail : '—',
              ],
          ],
        );
      }
      final imalatSlices = PeriodProductionChartSlices.imalat(
        report,
        chartOptions.imalatMetric,
      );
      if (imalatSlices.isNotEmpty) {
        _writeSheet(
          excel,
          'İmalat grafik',
          const ['Dilim', 'Değer', 'Grafik türü'],
          [
            for (final s in imalatSlices)
              [
                s.label,
                _fmt(s.value),
                chartOptions.imalatKind.label,
              ],
          ],
        );
      }
      _writeSheet(
        excel,
        'İmalat',
        const [
          'İmalat',
          'Konum',
          'Ekip',
          'Dönem',
          'Birim',
          'Adam-gün',
          'Kümülatif',
          'Plan',
          '%',
        ],
        [
          for (final r in report.imalatRows)
            [
              r.name,
              r.location,
              r.teamName,
              _fmt(r.periodQty),
              r.unit,
              _fmt(r.periodLaborDays),
              _fmt(r.totalQty),
              _fmt(r.plannedQty),
              '${r.progressPct.toStringAsFixed(0)}%',
            ],
        ],
      );
    }
    if (sections.verim) {
      final verimSlices = PeriodProductionChartSlices.verim(
        report,
        chartOptions.verimMetric,
      );
      if (verimSlices.isNotEmpty) {
        _writeSheet(
          excel,
          'Verim grafik',
          const ['Dilim', 'Değer', 'Grafik türü'],
          [
            for (final s in verimSlices)
              [
                s.label,
                _fmt(s.value),
                chartOptions.verimKind.label,
              ],
          ],
        );
      }
      _writeSheet(
        excel,
        'Verim',
        const [
          'İmalat',
          'Plan AG',
          'Dönem AG',
          'Plan metraj',
          'Dönem metraj',
          'Verim',
        ],
        [
          for (final r in report.verimRows)
            [
              r.imalatName,
              _fmt(r.plannedWorkerDays),
              _fmt(r.periodActualWorkerDays),
              r.plannedQty != null ? _fmt(r.plannedQty!) : '—',
              _fmt(r.periodActualQty),
              r.unitEfficiency != null
                  ? '%${(r.unitEfficiency! * 100).toStringAsFixed(0)}'
                  : '—',
            ],
        ],
      );
    }

    return excel.encode()!;
  }

  void _writeSheet(
    Excel excel,
    String name,
    List<String> headers,
    List<List<String>> rows,
  ) {
    final sheet = excel[name];
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = TextCellValue(headers[c].replaceAll('\n', ' '));
    }
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(rows[r][c]);
      }
    }
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

final periodSiteReportExportService = PeriodSiteReportExportService();
