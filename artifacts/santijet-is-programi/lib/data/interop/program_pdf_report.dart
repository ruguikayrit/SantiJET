import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/program_item.dart';
import 'program_interop.dart';

const _ink = PdfColor.fromInt(0xFF05070A);
const _electricBlue = PdfColor.fromInt(0xFF0055FF);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _hairline = PdfColor.fromInt(0xFFE3E6EB);
const _shell = PdfColor.fromInt(0xFFF4F6F9);
const _success = PdfColor.fromInt(0xFF16A34A);
const _critical = PdfColor.fromInt(0xFFDC2626);

/// Program tablosunu ve sade bir Gantt şeridini taşıyan yatay A4 raporu üretir.
/// PDF paylaşım içindir; MS Project'e geri okunmaz.
class ProgramPdfReport {
  const ProgramPdfReport({this.regular, this.bold});

  /// Türkçe karakterler için gömülecek yazı tipleri. Verilmezse PDF standart
  /// yazı tipine düşülür.
  final pw.Font? regular;
  final pw.Font? bold;

  Future<Uint8List> build(
    List<ProgramItem> items, {
    required String projectName,
    DateTime? today,
  }) async {
    final day = dateOnly(today ?? DateTime.now());
    final sorted = [...items]
      ..sort((a, b) {
        final bySite = a.santiyeId.compareTo(b.santiyeId);
        return bySite != 0 ? bySite : a.startDate.compareTo(b.startDate);
      });

    final span = _span(sorted, day);
    final document = pw.Document(
      title: '$projectName – İş Programı',
      author: 'ŞantiJET İş Programı',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginLeft: 24,
          marginRight: 24,
          marginTop: 24,
          marginBottom: 24,
        ),
        theme: pw.ThemeData.withFont(base: regular, bold: bold ?? regular),
        header: (context) => context.pageNumber == 1
            ? _header(projectName, sorted, day)
            : pw.SizedBox(height: 8),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ŞantiJET İş Programı · ${trDate(day)}',
                style: pw.TextStyle(fontSize: 7, color: _muted),
              ),
              pw.Text(
                'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: _muted),
              ),
            ],
          ),
        ),
        build: (context) => [_table(sorted, span, day)],
      ),
    );

    return document.save();
  }

  pw.Widget _header(String projectName, List<ProgramItem> items, DateTime day) {
    final delayed = items
        .where((item) => item.effectiveStatus(today: day) == ProgramStatus.delayed)
        .length;
    final done = items
        .where(
          (item) => item.effectiveStatus(today: day) == ProgramStatus.completed,
        )
        .length;
    final average = items.isEmpty
        ? 0
        : items.fold<int>(0, (sum, item) => sum + item.progress) ~/ items.length;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const pw.BoxDecoration(
        color: _ink,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ŞANTİJET',
                  style: pw.TextStyle(
                    fontSize: 15,
                    letterSpacing: 3,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'İŞ PROGRAMI',
                  style: pw.TextStyle(
                    fontSize: 8,
                    letterSpacing: 3,
                    color: _electricBlue,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  projectName,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
          ),
          _stat('FAALİYET', '${items.length}'),
          _stat('TAMAMLANAN', '$done'),
          _stat('GECİKEN', '$delayed', color: _critical),
          _stat('ORT. İLERLEME', '%$average'),
        ],
      ),
    );
  }

  pw.Widget _stat(String label, String value, {PdfColor? color}) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(left: 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 6, letterSpacing: 1.4, color: _muted),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color ?? PdfColors.white,
              ),
            ),
          ],
        ),
      );

  pw.Widget _table(List<ProgramItem> items, _Span span, DateTime day) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _shell),
        children: [
          _head('WBS'),
          _head('FAALİYET'),
          _head('BAŞLANGIÇ'),
          _head('BİTİŞ'),
          _head('GÜN'),
          _head('%'),
          _head('DURUM'),
          _head('SORUMLU'),
          _head('${trDate(span.start)} — ${trDate(span.end)}'),
        ],
      ),
    ];

    String? currentSite;
    var siteIndex = 0;
    var itemIndex = 0;
    for (final item in items) {
      if (item.santiyeId != currentSite) {
        currentSite = item.santiyeId;
        siteIndex++;
        itemIndex = 0;
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDF1F7)),
            children: [
              _cell('$siteIndex', bold: true),
              _cell(currentSite, bold: true),
              for (var index = 0; index < 7; index++) _cell(''),
            ],
          ),
        );
      }

      itemIndex++;
      final status = item.effectiveStatus(today: day);
      rows.add(
        pw.TableRow(
          children: [
            _cell(item.wbs ?? '$siteIndex.$itemIndex'),
            _cell(item.name),
            _cell(trDate(item.startDate)),
            _cell(trDate(item.endDate)),
            _cell('${item.calculatedDays}', align: pw.TextAlign.right),
            _cell('${item.progress}', align: pw.TextAlign.right),
            _cell(status.label, color: _statusColor(status)),
            _cell(item.responsible),
            _bar(item, span, status),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: _hairline, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(34),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FixedColumnWidth(52),
        3: pw.FixedColumnWidth(52),
        4: pw.FixedColumnWidth(26),
        5: pw.FixedColumnWidth(24),
        6: pw.FixedColumnWidth(64),
        7: pw.FlexColumnWidth(1.5),
        8: pw.FlexColumnWidth(3.4),
      },
      children: rows,
    );
  }

  pw.Widget _head(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 6,
        letterSpacing: 0.8,
        color: _muted,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );

  pw.Widget _cell(
    String text, {
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 7.5,
        color: color ?? _ink,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  /// Faaliyeti proje süresine oranlayan sade Gantt çubuğu.
  pw.Widget _bar(ProgramItem item, _Span span, ProgramStatus status) {
    final offset = dateOnly(item.startDate).difference(span.start).inDays;
    final total = span.days;
    final length = item.calculatedDays.clamp(1, total);
    final leading = offset.clamp(0, total);
    final trailing = (total - leading - length).clamp(0, total);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Container(
        height: 7,
        decoration: const pw.BoxDecoration(
          color: _shell,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3.5)),
        ),
        child: pw.Row(
          children: [
            if (leading > 0) pw.Expanded(flex: leading, child: pw.SizedBox()),
            pw.Expanded(
              flex: length,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: _statusColor(status),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3.5)),
                ),
              ),
            ),
            if (trailing > 0) pw.Expanded(flex: trailing, child: pw.SizedBox()),
          ],
        ),
      ),
    );
  }

  PdfColor _statusColor(ProgramStatus status) => switch (status) {
    ProgramStatus.completed => _success,
    ProgramStatus.delayed => _critical,
    ProgramStatus.inProgress => _electricBlue,
    ProgramStatus.planned => _muted,
  };

  _Span _span(List<ProgramItem> items, DateTime day) {
    if (items.isEmpty) return _Span(day, day.add(const Duration(days: 30)));
    var start = dateOnly(items.first.startDate);
    var end = dateOnly(items.first.endDate);
    for (final item in items) {
      final itemStart = dateOnly(item.startDate);
      final itemEnd = dateOnly(item.endDate);
      if (itemStart.isBefore(start)) start = itemStart;
      if (itemEnd.isAfter(end)) end = itemEnd;
    }
    return _Span(start, end);
  }
}

class _Span {
  _Span(this.start, this.end);
  final DateTime start;
  final DateTime end;

  int get days {
    final total = end.difference(start).inDays + 1;
    return total < 1 ? 1 : total;
  }
}
