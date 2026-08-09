import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/app_date.dart';
import '../../domain/entities/entities.dart';

/// Standart malzeme teklif formu PDF — boş birim fiyat sütunu.
class QuotePdfService {
  Future<void> shareQuoteForm({
    required Project project,
    required MaterialRequest request,
    String supplierPlaceholder = '',
  }) async {
    final bytes = await buildPdfBytes(
      project: project,
      request: request,
      supplierPlaceholder: supplierPlaceholder,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'teklif_${request.id}_${_stamp()}.pdf',
    );
  }

  Future<Uint8List> buildPdfBytes({
    required Project project,
    required MaterialRequest request,
    String supplierPlaceholder = '',
  }) async {
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
          pw.Text(
            'ŞantiJET Malzeme — Teklif Formu',
            style: pw.TextStyle(
              font: titleFont,
              fontSize: 16,
              color: const PdfColor.fromInt(0xFF0B1220),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Proje: ${project.name}'
            '${project.code.isEmpty ? '' : ' (${project.code})'}'
            ' · Tarih: ${AppDate.format(AppDate.today())}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF6B7A90),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Talep: ${request.title}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Firma: ${supplierPlaceholder.isEmpty ? '________________' : supplierPlaceholder}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 14),
          _table(request.lines),
          pw.SizedBox(height: 16),
          pw.Text(
            'Not: Birim fiyat ve teslim süresi tedarikçi tarafından doldurulur. '
            'Aynı form her firmaya gönderilir.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF6B7A90),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _table(List<MaterialRequestLine> lines) {
    const headers = [
      'Poz',
      'Malzeme',
      'Birim',
      'Miktar',
      'Birim Fiyat',
      'Tutar',
    ];

    pw.Widget cell(String text, {required bool header}) {
      return pw.Container(
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: pw.BoxDecoration(
          color: header
              ? const PdfColor.fromInt(0xFF0055FF)
              : PdfColors.white,
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: header ? 8 : 7.5,
            color: header ? PdfColors.white : const PdfColor.fromInt(0xFF0B1220),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFD0D7E2),
        width: 0.5,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2.8),
        2: pw.FlexColumnWidth(0.8),
        3: pw.FlexColumnWidth(1.0),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          children: [for (final h in headers) cell(h, header: true)],
        ),
        for (final line in lines)
          pw.TableRow(
            children: [
              cell(line.pozNo, header: false),
              cell(line.materialName, header: false),
              cell(line.birim, header: false),
              cell(_fmtQty(line.miktar), header: false),
              cell('', header: false),
              cell('', header: false),
            ],
          ),
      ],
    );
  }

  String _fmtQty(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _stamp() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}_'
        '${n.hour.toString().padLeft(2, '0')}'
        '${n.minute.toString().padLeft(2, '0')}';
  }
}
