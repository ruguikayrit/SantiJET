import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Analiz Excel dışa aktarma servisi.
///
/// `excel` paketi güncel `pdf` paketiyle `xml` sürümü açısından çakıştığı için
/// burada standart OpenXML `.xlsx` dosyası doğrudan üretilir (ZIP + XML).
/// Bu yöntem deprecated paket kullanmaz ve Excel/LibreOffice/Numbers ile uyumludur.
class AnalizExcelExportService {
  Uint8List buildBytes(PozAnaliz analiz) {
    final rows = _buildRows(analiz);
    final archive = Archive();
    void add(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    add('[Content_Types].xml', _contentTypesXml);
    add('_rels/.rels', _rootRelsXml);
    add('xl/workbook.xml', _workbookXml);
    add('xl/_rels/workbook.xml.rels', _workbookRelsXml);
    add('xl/styles.xml', _stylesXml);
    add('xl/worksheets/sheet1.xml', _sheetXml(rows));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<void> share(PozAnaliz analiz) async {
    final bytes = buildBytes(analiz);
    final fileName = '${_safeFileName(analiz.pozNo)}.xlsx';

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
    await SharePlus.instance.share(
      ShareParams(
        text: fileName,
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
      ),
    );
  }

  List<List<_Cell>> _buildRows(PozAnaliz analiz) {
    final hesap = AnalizHesap.hesapla(analiz);
    final rows = <List<_Cell>>[
      [_Cell.text('ŞantiJET BFA — Birim Fiyat Analiz Raporu', style: 1)],
      [_Cell.text('${analiz.pozNo} · ${analiz.analizAdi}')],
      [],
      [_Cell.text('Poz No', style: 2), _Cell.text(analiz.pozNo)],
      [_Cell.text('Tanım', style: 2), _Cell.text(analiz.analizAdi)],
      [_Cell.text('Kategori', style: 2), _Cell.text(analiz.kategori)],
      [
        _Cell.text('Disiplin', style: 2),
        _Cell.text((analiz.discipline ?? AnalizDiscipline.insaat).label),
      ],
      [_Cell.text('Birim', style: 2), _Cell.text(analiz.olcuBirimi)],
      [],
      [
        _Cell.text('Tip', style: 3),
        _Cell.text('Poz No', style: 3),
        _Cell.text('Tanım', style: 3),
        _Cell.text('Birim', style: 3),
        _Cell.text('Miktar', style: 3),
        _Cell.text('Birim Fiyat', style: 3),
        _Cell.text('Tutar', style: 3),
      ],
    ];

    for (final tip in AnalizKalemTip.values) {
      final items = analiz.kalemler.where((k) => k.tip == tip).toList();
      for (final k in items) {
        rows.add([
          _Cell.text(_tipLabel(tip)),
          _Cell.text(k.pozNo),
          _Cell.text(k.tanim),
          _Cell.text(k.olcuBirimi),
          _Cell.number(k.miktar),
          _Cell.number(k.birimFiyati, style: 4),
          _Cell.number(k.tutar, style: 4),
        ]);
      }
    }

    rows.addAll([
      [],
      [_Cell.text('Maliyet Özeti', style: 1)],
      [
        _Cell.text('Malzeme + İşçilik + Ekipman', style: 2),
        _Cell.number(hesap.malzemeIscilikToplami, style: 4),
      ],
      [
        _Cell.text('Yüklenici Kârı', style: 2),
        _Cell.number(hesap.yukleniciKarTutari, style: 4),
      ],
      [
        _Cell.text('Birim Fiyat (${analiz.olcuBirimi})', style: 2),
        _Cell.number(hesap.birimFiyati, style: 4),
      ],
    ]);

    if (analiz.pozTarifi.trim().isNotEmpty) {
      rows.addAll([
        [],
        [_Cell.text('Poz Tarifi', style: 1)],
        [_Cell.text(analiz.pozTarifi.trim())],
      ]);
    }
    if (analiz.yapimSartlari.trim().isNotEmpty) {
      rows.addAll([
        [],
        [_Cell.text('Yapım Şartları', style: 1)],
        [_Cell.text(analiz.yapimSartlari.trim())],
      ]);
    }
    if ((analiz.notlar ?? '').trim().isNotEmpty) {
      rows.addAll([
        [],
        [_Cell.text('Notlar', style: 1)],
        [_Cell.text(analiz.notlar!.trim())],
      ]);
    }
    return rows;
  }

  String _sheetXml(List<List<_Cell>> rows) {
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<cols>'
      '<col min="1" max="1" width="18" customWidth="1"/>'
      '<col min="2" max="2" width="16" customWidth="1"/>'
      '<col min="3" max="3" width="52" customWidth="1"/>'
      '<col min="4" max="4" width="12" customWidth="1"/>'
      '<col min="5" max="7" width="15" customWidth="1"/>'
      '</cols><sheetData>',
    );

    for (var r = 0; r < rows.length; r++) {
      buffer.write('<row r="${r + 1}">');
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        buffer.write(row[c].toXml(_cellRef(c, r)));
      }
      buffer.write('</row>');
    }
    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  String _cellRef(int col, int row) => '${_colName(col)}${row + 1}';

  String _colName(int index) {
    var n = index + 1;
    final chars = <String>[];
    while (n > 0) {
      final rem = (n - 1) % 26;
      chars.insert(0, String.fromCharCode(65 + rem));
      n = (n - rem - 1) ~/ 26;
    }
    return chars.join();
  }

  String _tipLabel(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => 'Malzeme',
        AnalizKalemTip.iscilik => 'İşçilik',
        AnalizKalemTip.ekipman => 'Ekipman',
      };

  String _safeFileName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class _Cell {
  const _Cell._(this.value, {required this.type, this.style = 0});

  factory _Cell.text(String value, {int style = 0}) =>
      _Cell._(value, type: 'inlineStr', style: style);

  factory _Cell.number(num value, {int style = 0}) =>
      _Cell._(value, type: 'n', style: style);

  final Object value;
  final String type;
  final int style;

  String toXml(String ref) {
    final styleAttr = style > 0 ? ' s="$style"' : '';
    if (type == 'n') {
      return '<c r="$ref"$styleAttr><v>${_num(value as num)}</v></c>';
    }
    return '<c r="$ref" t="inlineStr"$styleAttr><is><t>${_esc(value.toString())}</t></is></c>';
  }

  String _num(num value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 4);
}

String _esc(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const _contentTypesXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
    '</Types>';

const _rootRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
    '</Relationships>';

const _workbookXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets><sheet name="Analiz" sheetId="1" r:id="rId1"/></sheets>'
    '</workbook>';

const _workbookRelsXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '</Relationships>';

const _stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<fonts count="3">'
    '<font><sz val="11"/><name val="Inter"/></font>'
    '<font><b/><sz val="14"/><name val="Inter"/><color rgb="FFFFFFFF"/></font>'
    '<font><b/><sz val="11"/><name val="Inter"/></font>'
    '</fonts>'
    '<fills count="3"><fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FF16213E"/><bgColor indexed="64"/></patternFill></fill>'
    '</fills>'
    '<borders count="2"><border/><border><left style="thin"/><right style="thin"/><top style="thin"/><bottom style="thin"/></border></borders>'
    '<cellXfs count="5">'
    '<xf fontId="0" fillId="0" borderId="0"/>'
    '<xf fontId="1" fillId="2" borderId="1" applyFont="1" applyFill="1" applyBorder="1"/>'
    '<xf fontId="2" fillId="0" borderId="1" applyFont="1" applyBorder="1"/>'
    '<xf fontId="2" fillId="2" borderId="1" applyFont="1" applyFill="1" applyBorder="1"/>'
    '<xf fontId="0" fillId="0" borderId="1" numFmtId="4" applyBorder="1" applyNumberFormat="1"/>'
    '</cellXfs>'
    '</styleSheet>';

final analizExcelExportService = AnalizExcelExportService();
