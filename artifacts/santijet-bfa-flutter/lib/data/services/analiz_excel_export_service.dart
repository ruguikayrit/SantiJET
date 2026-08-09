import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/app_format.dart';
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Analiz Excel dışa aktarma — PDF rapor düzeninin birebir karşılığı.
///
/// `excel` paketi `pdf` ile XML sürüm çakışması yaşadığı için OpenXML
/// `.xlsx` doğrudan üretilir (ZIP + XML).
class AnalizExcelExportService {
  Uint8List buildBytes(PozAnaliz analiz) {
    final sheet = _buildSheet(analiz);
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
    add('xl/worksheets/sheet1.xml', _sheetXml(sheet));

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

  _SheetData _buildSheet(PozAnaliz analiz) {
    final hesap = AnalizHesap.hesapla(analiz);
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final rows = <_RowData>[];
    final merges = <String>[];

    void merge(String ref) => merges.add(ref);

    // —— Marka başlığı (PDF dark banner) ——
    rows.add(
      _RowData(
        height: 18,
        cells: [
          _Cell.text('ŞANTİJET MALİYET', style: _s.brand),
          _Cell.empty(style: _s.headerFill),
          _Cell.empty(style: _s.headerFill),
          _Cell.empty(style: _s.headerFill),
          _Cell.empty(style: _s.headerFill),
          _Cell.text(date, style: _s.headerDate),
        ],
      ),
    );
    merge('A${rows.length}:E${rows.length}');

    rows.add(
      _RowData(
        height: 26,
        cells: [
          _Cell.text('Birim Fiyat Analiz Raporu', style: _s.title),
          for (var i = 0; i < 5; i++) _Cell.empty(style: _s.headerFill),
        ],
      ),
    );
    merge('A${rows.length}:F${rows.length}');

    rows.add(
      _RowData(
        height: 18,
        cells: [
          _Cell.text(
            '${analiz.pozNo} · ${analiz.analizAdi}',
            style: _s.subtitle,
          ),
          for (var i = 0; i < 5; i++) _Cell.empty(style: _s.headerFill),
        ],
      ),
    );
    merge('A${rows.length}:F${rows.length}');

    rows.add(const _RowData(height: 10, cells: []));

    // —— Bilgi grid (PDF 4 kolon: label/value | label/value) ——
    void infoRow(String l1, String v1, String l2, String v2) {
      rows.add(
        _RowData(
          cells: [
            _Cell.text(l1, style: _s.infoLabel),
            _Cell.text(v1, style: _s.infoValue),
            _Cell.empty(style: _s.infoValue),
            _Cell.text(l2, style: _s.infoLabel),
            _Cell.text(v2, style: _s.infoValue),
            _Cell.empty(style: _s.infoValue),
          ],
        ),
      );
      final r = rows.length;
      merge('B$r:C$r');
      merge('E$r:F$r');
    }

    infoRow('Poz No', analiz.pozNo, 'Birim', analiz.olcuBirimi);
    infoRow(
      'Kategori',
      analiz.kategori,
      'Disiplin',
      (analiz.discipline ?? AnalizDiscipline.insaat).label,
    );
    infoRow(
      'Yüklenici Kârı',
      '%${AppFormat.decimal(analiz.yukleniciKarOrani, fractionDigits: 0)}',
      'Birim Fiyat',
      AppFormat.currency(hesap.birimFiyati),
    );

    // —— Poz Tarifi ——
    if (analiz.pozTarifi.trim().isNotEmpty) {
      rows.add(const _RowData(height: 10, cells: []));
      _addTextSection(rows, merges, 'Poz Tarifi', analiz.pozTarifi.trim());
    }

    // —— Kalem bölümleri (PDF ile aynı sıra/etiket) ——
    for (final tip in AnalizKalemTip.values) {
      final items = analiz.kalemler.where((k) => k.tip == tip).toList();
      if (items.isEmpty) continue;
      final toplam = items.fold<double>(0, (s, k) => s + k.tutar);

      rows.add(const _RowData(height: 8, cells: []));
      rows.add(
        _RowData(
          height: 20,
          cells: [
            _Cell.text(_tipLabel(tip), style: _s.sectionTitle),
            _Cell.empty(style: _s.sectionTitle),
            _Cell.empty(style: _s.sectionTitle),
            _Cell.empty(style: _s.sectionTitle),
            _Cell.text(AppFormat.currency(toplam), style: _s.sectionTotal),
            _Cell.empty(style: _s.sectionTotal),
          ],
        ),
      );
      final sr = rows.length;
      merge('A$sr:D$sr');
      merge('E$sr:F$sr');

      rows.add(
        _RowData(
          cells: [
            _Cell.text('Poz No', style: _s.tableHeader),
            _Cell.text('Tanım', style: _s.tableHeader),
            _Cell.text('Birim', style: _s.tableHeader),
            _Cell.text('Miktar', style: _s.tableHeader),
            _Cell.text('Birim Fiyat', style: _s.tableHeader),
            _Cell.text('Tutar', style: _s.tableHeader),
          ],
        ),
      );

      for (final k in items) {
        rows.add(
          _RowData(
            cells: [
              _Cell.text(k.pozNo, style: _s.cellCenter),
              _Cell.text(k.tanim, style: _s.cellWrap),
              _Cell.text(k.olcuBirimi, style: _s.cellCenter),
              _Cell.text(
                AppFormat.decimal(k.miktar, fractionDigits: 4),
                style: _s.cellCenter,
              ),
              _Cell.text(AppFormat.currency(k.birimFiyati), style: _s.cellCenter),
              _Cell.text(AppFormat.currency(k.tutar), style: _s.cellCenter),
            ],
          ),
        );
      }
    }

    // —— Maliyet Özeti ——
    rows.add(const _RowData(height: 10, cells: []));
    rows.add(
      _RowData(
        cells: [
          _Cell.text('Maliyet Özeti', style: _s.summaryHeader),
          for (var i = 0; i < 4; i++) _Cell.empty(style: _s.summaryHeader),
          _Cell.text('Tutar', style: _s.summaryHeaderRight),
        ],
      ),
    );
    merge('A${rows.length}:E${rows.length}');

    void summaryRow(String label, String amount, {bool emphasize = false}) {
      final ls = emphasize ? _s.summaryFinal : _s.summaryLabel;
      final vs = emphasize ? _s.summaryFinalRight : _s.summaryValue;
      rows.add(
        _RowData(
          cells: [
            _Cell.text(label, style: ls),
            for (var i = 0; i < 4; i++) _Cell.empty(style: ls),
            _Cell.text(amount, style: vs),
          ],
        ),
      );
      merge('A${rows.length}:E${rows.length}');
    }

    summaryRow(
      'Malzeme + İşçilik + Ekipman',
      AppFormat.currency(hesap.malzemeIscilikToplami),
    );
    summaryRow(
      'Yüklenici Kârı',
      AppFormat.currency(hesap.yukleniciKarTutari),
    );
    summaryRow(
      'Birim Fiyat (${analiz.olcuBirimi})',
      AppFormat.currency(hesap.birimFiyati),
      emphasize: true,
    );

    if (analiz.yapimSartlari.trim().isNotEmpty) {
      rows.add(const _RowData(height: 10, cells: []));
      _addTextSection(rows, merges, 'Yapım Şartları', analiz.yapimSartlari.trim());
    }
    if ((analiz.notlar ?? '').trim().isNotEmpty) {
      rows.add(const _RowData(height: 10, cells: []));
      _addTextSection(rows, merges, 'Notlar', analiz.notlar!.trim());
    }

    rows.add(const _RowData(height: 12, cells: []));
    rows.add(
      _RowData(
        cells: [
          _Cell.text(
            'ŞantiJET Maliyet bilgi amaçlıdır. Nihai doğrulama için güncel resmi yayınlar esas alınmalıdır.',
            style: _s.footer,
          ),
          for (var i = 0; i < 5; i++) _Cell.empty(style: _s.footer),
        ],
      ),
    );
    merge('A${rows.length}:F${rows.length}');

    return _SheetData(rows: rows, merges: merges);
  }

  void _addTextSection(
    List<_RowData> rows,
    List<String> merges,
    String title,
    String body,
  ) {
    rows.add(
      _RowData(
        cells: [
          _Cell.text(title, style: _s.textTitle),
          for (var i = 0; i < 5; i++) _Cell.empty(style: _s.textTitle),
        ],
      ),
    );
    merges.add('A${rows.length}:F${rows.length}');

    rows.add(
      _RowData(
        height: 48,
        cells: [
          _Cell.text(body, style: _s.textBody),
          for (var i = 0; i < 5; i++) _Cell.empty(style: _s.textBody),
        ],
      ),
    );
    merges.add('A${rows.length}:F${rows.length}');
  }

  String _sheetXml(_SheetData sheet) {
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0" showGridLines="0"/></sheetViews>'
      '<cols>'
      '<col min="1" max="1" width="14" customWidth="1"/>'
      '<col min="2" max="2" width="42" customWidth="1"/>'
      '<col min="3" max="3" width="10" customWidth="1"/>'
      '<col min="4" max="4" width="12" customWidth="1"/>'
      '<col min="5" max="5" width="16" customWidth="1"/>'
      '<col min="6" max="6" width="16" customWidth="1"/>'
      '</cols><sheetData>',
    );

    for (var r = 0; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final rowNum = r + 1;
      final ht = row.height != null ? ' ht="${row.height}" customHeight="1"' : '';
      buffer.write('<row r="$rowNum"$ht>');
      for (var c = 0; c < row.cells.length; c++) {
        buffer.write(row.cells[c].toXml(_cellRef(c, r)));
      }
      buffer.write('</row>');
    }
    buffer.write('</sheetData>');

    if (sheet.merges.isNotEmpty) {
      buffer.write('<mergeCells count="${sheet.merges.length}">');
      for (final m in sheet.merges) {
        buffer.write('<mergeCell ref="$m"/>');
      }
      buffer.write('</mergeCells>');
    }

    buffer.write(
      '<pageMargins left="0.5" right="0.5" top="0.5" bottom="0.5" header="0.3" footer="0.3"/>'
      '<pageSetup orientation="portrait" paperSize="9" fitToPage="1" fitToWidth="1" fitToHeight="0"/>'
      '</worksheet>',
    );
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

class _SheetData {
  const _SheetData({required this.rows, required this.merges});
  final List<_RowData> rows;
  final List<String> merges;
}

class _RowData {
  const _RowData({required this.cells, this.height});
  final List<_Cell> cells;
  final double? height;
}

class _Cell {
  const _Cell._(this.value, {required this.type, required this.style});

  factory _Cell.text(String value, {required int style}) =>
      _Cell._(value, type: 'inlineStr', style: style);

  factory _Cell.empty({required int style}) =>
      _Cell._('', type: 'inlineStr', style: style);

  final Object value;
  final String type;
  final int style;

  String toXml(String ref) {
    if (type == 'inlineStr' && value.toString().isEmpty) {
      return '<c r="$ref" s="$style"/>';
    }
    return '<c r="$ref" s="$style" t="inlineStr">'
        '<is><t>${_esc(value.toString())}</t></is></c>';
  }
}

/// Stil indeksleri — PDF renk/hiyerarşi ile uyumlu.
abstract final class _s {
  static const brand = 1;
  static const title = 2;
  static const subtitle = 3;
  static const headerDate = 4;
  static const headerFill = 5;
  static const infoLabel = 6;
  static const infoValue = 7;
  static const sectionTitle = 8;
  static const sectionTotal = 9;
  static const tableHeader = 10;
  static const cellCenter = 11;
  static const cellWrap = 12;
  static const summaryHeader = 13;
  static const summaryHeaderRight = 14;
  static const summaryLabel = 15;
  static const summaryValue = 16;
  static const summaryFinal = 17;
  static const summaryFinalRight = 18;
  static const textTitle = 19;
  static const textBody = 20;
  static const footer = 21;
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

/// PDF: #16213E banner, #F1F5F9 label, #E2E8F0 tablo başlığı, #F8FAFC metin kutusu.
const _stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<fonts count="8">'
    // 0 body
    '<font><sz val="10"/><name val="Calibri"/><color rgb="FF0F172A"/></font>'
    // 1 brand white small bold
    '<font><b/><sz val="10"/><name val="Calibri"/><color rgb="FFFFFFFF"/></font>'
    // 2 title white large bold
    '<font><b/><sz val="16"/><name val="Calibri"/><color rgb="FFFFFFFF"/></font>'
    // 3 subtitle white
    '<font><sz val="10"/><name val="Calibri"/><color rgb="FFFFFFFF"/></font>'
    // 4 section / bold body
    '<font><b/><sz val="11"/><name val="Calibri"/><color rgb="FF0F172A"/></font>'
    // 5 info label grey bold
    '<font><b/><sz val="9"/><name val="Calibri"/><color rgb="FF475569"/></font>'
    // 6 table header bold
    '<font><b/><sz val="9"/><name val="Calibri"/><color rgb="FF0F172A"/></font>'
    // 7 footer muted
    '<font><sz val="8"/><name val="Calibri"/><color rgb="FF64748B"/></font>'
    '</fonts>'
    '<fills count="7">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    // 2 dark banner #16213E
    '<fill><patternFill patternType="solid"><fgColor rgb="FF16213E"/><bgColor indexed="64"/></patternFill></fill>'
    // 3 label #F1F5F9
    '<fill><patternFill patternType="solid"><fgColor rgb="FFF1F5F9"/><bgColor indexed="64"/></patternFill></fill>'
    // 4 table header #E2E8F0
    '<fill><patternFill patternType="solid"><fgColor rgb="FFE2E8F0"/><bgColor indexed="64"/></patternFill></fill>'
    // 5 text box #F8FAFC
    '<fill><patternFill patternType="solid"><fgColor rgb="FFF8FAFC"/><bgColor indexed="64"/></patternFill></fill>'
    // 6 summary final #F1F5F9 (same as 3, kept distinct for clarity)
    '<fill><patternFill patternType="solid"><fgColor rgb="FFF1F5F9"/><bgColor indexed="64"/></patternFill></fill>'
    '</fills>'
    '<borders count="2">'
    '<border/>'
    '<border>'
    '<left style="thin"><color rgb="FFCBD5E1"/></left>'
    '<right style="thin"><color rgb="FFCBD5E1"/></right>'
    '<top style="thin"><color rgb="FFCBD5E1"/></top>'
    '<bottom style="thin"><color rgb="FFCBD5E1"/></bottom>'
    '</border>'
    '</borders>'
    '<cellXfs count="22">'
    // 0 unused default
    '<xf fontId="0" fillId="0" borderId="0"/>'
    // 1 brand
    '<xf fontId="1" fillId="2" borderId="0" applyFont="1" applyFill="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 2 title
    '<xf fontId="2" fillId="2" borderId="0" applyFont="1" applyFill="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 3 subtitle
    '<xf fontId="3" fillId="2" borderId="0" applyFont="1" applyFill="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left" wrapText="1"/>'
    '</xf>'
    // 4 header date
    '<xf fontId="3" fillId="2" borderId="0" applyFont="1" applyFill="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="right"/>'
    '</xf>'
    // 5 header fill
    '<xf fontId="3" fillId="2" borderId="0" applyFont="1" applyFill="1"/>'
    // 6 info label
    '<xf fontId="5" fillId="3" borderId="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 7 info value
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left" wrapText="1"/>'
    '</xf>'
    // 8 section title
    '<xf fontId="4" fillId="0" borderId="0" applyFont="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 9 section total
    '<xf fontId="4" fillId="0" borderId="0" applyFont="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="right"/>'
    '</xf>'
    // 10 table header
    '<xf fontId="6" fillId="4" borderId="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="center" wrapText="0"/>'
    '</xf>'
    // 11 cell center
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="center" wrapText="0"/>'
    '</xf>'
    // 12 cell wrap (tanım)
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left" wrapText="1"/>'
    '</xf>'
    // 13 summary header
    '<xf fontId="1" fillId="2" borderId="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 14 summary header right
    '<xf fontId="1" fillId="2" borderId="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="right"/>'
    '</xf>'
    // 15 summary label
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 16 summary value
    '<xf fontId="0" fillId="0" borderId="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="right"/>'
    '</xf>'
    // 17 summary final
    '<xf fontId="4" fillId="6" borderId="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 18 summary final right
    '<xf fontId="4" fillId="6" borderId="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="right"/>'
    '</xf>'
    // 19 text title
    '<xf fontId="4" fillId="5" borderId="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left"/>'
    '</xf>'
    // 20 text body
    '<xf fontId="0" fillId="5" borderId="1" applyFill="1" applyBorder="1" applyAlignment="1">'
    '<alignment vertical="top" horizontal="left" wrapText="1"/>'
    '</xf>'
    // 21 footer
    '<xf fontId="7" fillId="0" borderId="0" applyFont="1" applyAlignment="1">'
    '<alignment vertical="center" horizontal="left" wrapText="1"/>'
    '</xf>'
    '</cellXfs>'
    '</styleSheet>';

final analizExcelExportService = AnalizExcelExportService();
