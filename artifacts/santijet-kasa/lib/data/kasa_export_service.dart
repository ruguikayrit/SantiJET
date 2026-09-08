import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/kasa_hareket.dart';
import '../domain/kasa_rules.dart';
import '../domain/kasa_transfer_format.dart';
import '../domain/money_format.dart';

/// Kasa hareketlerini JPG / PDF / Excel olarak dışa aktarır.
class KasaExportService {
  static final _date = DateFormat('dd.MM.yyyy');
  static final _stamp = DateFormat('yyyyMMdd_HHmm');

  /// Çıktı sütunları — Ek Açıklama yok. Açıklama hariç tek satır.
  static const headers = <String>[
    'Tarih',
    'Tedarikçi',
    'Açıklama',
    'Gelir',
    'Gider',
    'Ödeme Şekli',
    'Belge Türü',
    'Şantiye',
  ];

  /// Açıklama sütun indeksi — tek satır kısıtı yok; daralma buraya yansır.
  static const aciklamaColumnIndex = 2;

  Future<void> export(
    KasaTransferFormat format, {
    required List<KasaHareket> hareketler,
    DateTime? from,
    DateTime? to,
  }) async {
    switch (format) {
      case KasaTransferFormat.jpg:
        await exportJpg(hareketler: hareketler, from: from, to: to);
      case KasaTransferFormat.pdf:
        await exportPdf(hareketler: hareketler, from: from, to: to);
      case KasaTransferFormat.excel:
        await exportExcel(hareketler: hareketler, from: from, to: to);
    }
  }

  Future<void> exportJpg({
    required List<KasaHareket> hareketler,
    DateTime? from,
    DateTime? to,
  }) async {
    final pdfBytes = await buildPdfBytes(
      hareketler: hareketler,
      from: from,
      to: to,
    );
    Uint8List? jpgBytes;
    await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 144)) {
      final png = await page.toPng();
      final decoded = img.decodeImage(png);
      if (decoded == null) {
        throw StateError('JPG oluşturulamadı.');
      }
      jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 88));
      break;
    }
    if (jpgBytes == null) {
      throw StateError('JPG sayfası üretilemedi.');
    }
    final name = 'santijet_kasa_${_stamp.format(DateTime.now())}.jpg';
    await Share.shareXFiles(
      [
        XFile.fromData(
          jpgBytes,
          name: name,
          mimeType: 'image/jpeg',
        ),
      ],
      subject: 'ŞantiJET Kasa — Rapor',
      fileNameOverrides: [name],
    );
  }

  Future<void> exportPdf({
    required List<KasaHareket> hareketler,
    DateTime? from,
    DateTime? to,
  }) async {
    final bytes = await buildPdfBytes(
      hareketler: hareketler,
      from: from,
      to: to,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'santijet_kasa_${_stamp.format(DateTime.now())}.pdf',
    );
  }

  Future<void> exportExcel({
    required List<KasaHareket> hareketler,
    DateTime? from,
    DateTime? to,
  }) async {
    final bytes = buildExcelBytes(
      hareketler: hareketler,
      from: from,
      to: to,
    );
    final name = 'santijet_kasa_${_stamp.format(DateTime.now())}.xlsx';
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: name,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: 'ŞantiJET Kasa — Hareketler',
      fileNameOverrides: [name],
    );
  }

  Future<Uint8List> buildPdfBytes({
    required List<KasaHareket> hareketler,
    DateTime? from,
    DateTime? to,
  }) async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final doc = pw.Document(theme: theme);
    final ozet = hesaplaOzet(hareketler);
    final now = DateTime.now();
    final rangeLabel = _rangeLabel(from, to);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'ŞantiJET KASA',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'İş Avansı ve Harcama Tablosu',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dönem: $rangeLabel  ·  '
            '${now.day}.${now.month}.${now.year} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _pdfOzetBox('Toplam Gelir', MoneyFormat.format(ozet.toplamGelir)),
              pw.SizedBox(width: 10),
              _pdfOzetBox('Toplam Gider', MoneyFormat.format(ozet.toplamGider)),
              pw.SizedBox(width: 10),
              _pdfOzetBox(
                'Güncel Kasa',
                MoneyFormat.formatSigned(ozet.guncelKasa),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _pdfTable(hareketler),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  /// Açıklama hariç dar sabit sütunlar + tek satır; kalan genişlik açıklamada.
  pw.Widget _pdfTable(List<KasaHareket> hareketler) {
    final headerStyle =
        pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5);
    const cellStyle = pw.TextStyle(fontSize: 7);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FixedColumnWidth(48), // Tarih
        1: pw.FixedColumnWidth(68), // Tedarikçi
        2: pw.FlexColumnWidth(3.2), // Açıklama — daralma buraya
        3: pw.FixedColumnWidth(52), // Gelir
        4: pw.FixedColumnWidth(52), // Gider
        5: pw.FixedColumnWidth(62), // Ödeme
        6: pw.FixedColumnWidth(42), // Belge
        7: pw.FixedColumnWidth(64), // Şantiye
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            for (var i = 0; i < headers.length; i++)
              _pdfCell(
                headers[i],
                style: headerStyle,
                singleLine: true,
              ),
          ],
        ),
        for (final h in hareketler)
          pw.TableRow(
            children: [
              for (var i = 0; i < headers.length; i++)
                _pdfCell(
                  rowCells(h)[i],
                  style: cellStyle,
                  singleLine: i != aciklamaColumnIndex,
                ),
            ],
          ),
      ],
    );
  }

  pw.Widget _pdfCell(
    String text, {
    required pw.TextStyle style,
    required bool singleLine,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: pw.Text(
        text,
        style: style,
        maxLines: singleLine ? 1 : null,
        softWrap: !singleLine,
      ),
    );
  }

  Uint8List buildExcelBytes({
    required List<KasaHareket> hareketler,
    DateTime? from,
    DateTime? to,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Kasa'];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final ozet = hesaplaOzet(hareketler);
    sheet.appendRow([
      TextCellValue('ŞantiJET KASA — İş Avansı ve Harcama Tablosu'),
    ]);
    sheet.appendRow([TextCellValue('Dönem: ${_rangeLabel(from, to)}')]);
    sheet.appendRow([
      TextCellValue('Toplam Gelir'),
      TextCellValue(MoneyFormat.format(ozet.toplamGelir)),
      TextCellValue('Toplam Gider'),
      TextCellValue(MoneyFormat.format(ozet.toplamGider)),
      TextCellValue('Güncel Kasa'),
      TextCellValue(MoneyFormat.formatSigned(ozet.guncelKasa)),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final h in hareketler) {
      sheet.appendRow(rowCells(h).map(TextCellValue.new).toList());
    }

    // Dar sütunlar + açıklama geniş — Excel’de de aynı mantık
    sheet.setColumnWidth(0, 11); // Tarih
    sheet.setColumnWidth(1, 14); // Tedarikçi
    sheet.setColumnWidth(2, 36); // Açıklama
    sheet.setColumnWidth(3, 12); // Gelir
    sheet.setColumnWidth(4, 12); // Gider
    sheet.setColumnWidth(5, 14); // Ödeme
    sheet.setColumnWidth(6, 10); // Belge
    sheet.setColumnWidth(7, 14); // Şantiye

    return Uint8List.fromList(excel.encode()!);
  }

  List<String> rowCells(KasaHareket h) => [
        _date.format(h.tarih),
        h.tedarikci,
        h.aciklama,
        h.gelir != null ? MoneyFormat.format(h.gelir!) : '',
        h.gider != null ? MoneyFormat.format(h.gider!) : '',
        h.odemeSekli,
        h.belgeTuru,
        h.santiye,
      ];

  String _rangeLabel(DateTime? from, DateTime? to) {
    if (from == null && to == null) return 'Tüm zamanlar';
    final a = from != null ? _date.format(from) : '…';
    final b = to != null ? _date.format(to) : '…';
    return '$a – $b';
  }

  pw.Widget _pdfOzetBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

final kasaExportService = KasaExportService();
