import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/kasa_import_format.dart';
import '../domain/money_format.dart';
import 'demo_data.dart';

/// Örnek içe aktarım şablonu — Excel + referans JPG.
class KasaImportTemplateService {
  static final _date = DateFormat('dd.MM.yyyy');

  Future<void> shareExampleJpg() async {
    final data = await rootBundle.load(KasaImportFormat.jpgAssetPath);
    final bytes = data.buffer.asUint8List();
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'santijet_kasa_ornek_tablo.jpg',
          mimeType: 'image/jpeg',
        ),
      ],
      subject: 'ŞantiJET Kasa — örnek içe aktarım tablosu',
      fileNameOverrides: ['santijet_kasa_ornek_tablo.jpg'],
    );
  }

  Future<void> shareExampleExcel() async {
    final bytes = buildTemplateExcelBytes();
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'santijet_kasa_ornek_tablo.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: 'ŞantiJET Kasa — örnek içe aktarım tablosu',
      fileNameOverrides: ['santijet_kasa_ornek_tablo.xlsx'],
    );
  }

  Uint8List buildTemplateExcelBytes() {
    final excel = Excel.createExcel();
    final sheet = excel['İçe Aktarım'];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue('ŞantiJET KASA — İş Avansı ve Harcama Tablosu (örnek)'),
    ]);
    sheet.appendRow([
      TextCellValue(
        'Bu dosyayı doldurup Excel olarak içe aktarın veya net ekran '
        'görüntüsünü JPG/PDF yapın.',
      ),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(KasaImportFormat.headers.map(TextCellValue.new).toList());

    final sample = buildDemoHareketler(now: DateTime(2026, 9, 8)).take(6);
    for (final h in sample) {
      sheet.appendRow([
        TextCellValue(_date.format(h.tarih)),
        TextCellValue(h.tedarikci),
        TextCellValue(h.aciklama),
        TextCellValue(h.gelir != null ? MoneyFormat.format(h.gelir!) : ''),
        TextCellValue(h.gider != null ? MoneyFormat.format(h.gider!) : ''),
        TextCellValue(h.odemeSekli),
        TextCellValue(h.belgeTuru),
        TextCellValue(h.santiye),
        TextCellValue(h.ekAciklama),
      ]);
    }

    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 16);
    sheet.setColumnWidth(8, 32);

    return Uint8List.fromList(excel.encode()!);
  }
}

final kasaImportTemplateService = KasaImportTemplateService();
