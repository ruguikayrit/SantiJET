import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/app_format.dart';
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Analiz PDF dışa aktarma servisi.
///
/// ŞantiJET Demir `ExportService` yaklaşımı (`pdf` + `printing`) ve React Native
/// `analizExport.ts` rapor yapısı (marka başlığı, bilgi grid'i, kalem bölümleri,
/// maliyet özeti, notlar) birleştirilmiştir. PDF'ler A4 portrait üretilir.
class AnalizPdfExportService {
  Future<Uint8List> buildBytes(PozAnaliz analiz) async {
    final fontBytes = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final font = pw.Font.ttf(fontBytes);
    final boldBytes = await rootBundle.load('assets/fonts/Rajdhani-Bold.ttf');
    final titleFont = pw.Font.ttf(boldBytes);
    final doc = pw.Document();
    final hesap = AnalizHesap.hesapla(analiz);
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: font, bold: titleFont),
        build: (context) => [
          _header(analiz, now),
          pw.SizedBox(height: 14),
          _infoGrid(analiz, hesap),
          if (analiz.pozTarifi.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _textSection('Poz Tarifi', analiz.pozTarifi),
          ],
          pw.SizedBox(height: 14),
          for (final tip in AnalizKalemTip.values)
            ..._kalemSection(analiz, tip),
          pw.SizedBox(height: 12),
          _costSummary(analiz, hesap),
          if (analiz.yapimSartlari.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _textSection('Yapım Şartları', analiz.yapimSartlari),
          ],
          if ((analiz.notlar ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _textSection('Notlar', analiz.notlar!),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'ŞantiJET BFA bilgi amaçlıdır. Nihai doğrulama için güncel resmi yayınlar esas alınmalıdır.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> share(PozAnaliz analiz) async {
    final bytes = await buildBytes(analiz);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeFileName(analiz.pozNo)}.pdf',
    );
  }

  Future<void> preview(PozAnaliz analiz) async {
    final bytes = await buildBytes(analiz);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  pw.Widget _header(PozAnaliz analiz, DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#16213E'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ŞANTİJET BFA',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Birim Fiyat Analiz Raporu',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${analiz.pozNo} · ${analiz.analizAdi}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoGrid(PozAnaliz analiz, AnalizHesapSonucu hesap) {
    final rows = [
      ['Poz No', analiz.pozNo, 'Birim', analiz.olcuBirimi],
      ['Kategori', analiz.kategori, 'Disiplin', _disciplineLabel(analiz)],
      [
        'Yüklenici Kârı',
        '%${AppFormat.decimal(analiz.yukleniciKarOrani, fractionDigits: 0)}',
        'Birim Fiyat',
        AppFormat.currency(hesap.birimFiyati),
      ],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2.3),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(2.3),
      },
      children: [
        for (final r in rows)
          pw.TableRow(
            children: [
              _labelCell(r[0]),
              _valueCell(r[1]),
              _labelCell(r[2]),
              _valueCell(r[3]),
            ],
          ),
      ],
    );
  }

  List<pw.Widget> _kalemSection(PozAnaliz analiz, AnalizKalemTip tip) {
    final items = analiz.kalemler.where((k) => k.tip == tip).toList();
    if (items.isEmpty) return const [];
    final toplam = items.fold<double>(0, (sum, k) => sum + k.tutar);
    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 5, top: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              _tipLabel(tip),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              AppFormat.currency(toplam),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Poz No',
          'Tanım',
          'Birim',
          'Miktar',
          'Birim Fiyat',
          'Tutar'
        ],
        data: [
          for (final k in items)
            [
              k.pozNo,
              k.tanim,
              k.olcuBirimi,
              AppFormat.decimal(k.miktar, fractionDigits: 4),
              AppFormat.currency(k.birimFiyati),
              AppFormat.currency(k.tutar),
            ],
        ],
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(3.4),
          2: const pw.FlexColumnWidth(0.7),
          3: const pw.FlexColumnWidth(0.9),
          4: const pw.FlexColumnWidth(1.1),
          5: const pw.FlexColumnWidth(1.1),
        },
      ),
      pw.SizedBox(height: 8),
    ];
  }

  pw.Widget _costSummary(PozAnaliz analiz, AnalizHesapSonucu hesap) {
    final rows = [
      [
        'Malzeme + İşçilik + Ekipman',
        AppFormat.currency(hesap.malzemeIscilikToplami)
      ],
      ['Yüklenici Kârı', AppFormat.currency(hesap.yukleniciKarTutari)],
      [
        'Birim Fiyat (${analiz.olcuBirimi})',
        AppFormat.currency(hesap.birimFiyati)
      ],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1.4)
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#16213E')),
          children: [
            _darkCell('Maliyet Özeti'),
            _darkCell('Tutar', alignRight: true),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i == rows.length - 1
                  ? PdfColor.fromHex('#F1F5F9')
                  : PdfColors.white,
            ),
            children: [
              _valueCell(rows[i][0], bold: i == rows.length - 1),
              _valueCell(rows[i][1],
                  alignRight: true, bold: i == rows.length - 1),
            ],
          ),
      ],
    );
  }

  pw.Widget _textSection(String title, String body) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text(body.trim(),
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 2)),
        ],
      ),
    );
  }

  pw.Widget _labelCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      color: PdfColor.fromHex('#F1F5F9'),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _valueCell(
    String text, {
    bool alignRight = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _darkCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  String _disciplineLabel(PozAnaliz analiz) {
    return (analiz.discipline ?? AnalizDiscipline.insaat).label;
  }

  String _tipLabel(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => 'Malzeme Kalemleri',
        AnalizKalemTip.iscilik => 'İşçilik Kalemleri',
        AnalizKalemTip.ekipman => 'Ekipman Kalemleri',
      };

  String _safeFileName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

final analizPdfExportService = AnalizPdfExportService();
