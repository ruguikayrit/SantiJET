import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_info.dart';
import '../../core/utils/puantaj_date.dart';
import '../../domain/entities/company_info.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/project.dart';
import 'daily_report_export_style.dart';
import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;

/// Günlük rapor PDF — Özet / Standart / Gelişmiş.
///
/// Standart düzen, örnek “GÜNLÜK ŞANTİYE RAPORU” formuna yaklaşır:
/// başlık, iş/yüklenici, tarih+hava, puantaj, yapılan işler, malzeme,
/// makine, imza alanları; fotoğraflar ayrı sayfada.
class DailyReportPdfService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _muted = PdfColor.fromInt(0xFF4B5563);
  static const _line = PdfColor.fromInt(0xFF9CA3AF);
  static const _headerBg = PdfColor.fromInt(0xFFF3F4F6);
  static const _band = PdfColor.fromInt(0xFFE8F0FF);
  static const _blue = PdfColor.fromInt(0xFF0055FF);

  Future<pw.ThemeData> _theme() async {
    _regularFont ??= await PdfGoogleFonts.notoSansRegular();
    _boldFont ??= await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(base: _regularFont!, bold: _boldFont!);
  }

  Future<void> export({
    required DailyReport report,
    required Project project,
    required CompanyInfo company,
    required DailyReportExportStyle style,
    DailyReportAttendanceSnapshot? liveSnapshot,
  }) async {
    final bytes = await buildBytes(
      report: report,
      project: project,
      company: company,
      style: style,
      liveSnapshot: liveSnapshot,
    );
    final stem = _fileStem(project.name, report.date, style);
    await file_access.downloadBytesFile(
      fileName: '$stem.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: 'Günlük Şantiye Raporu — ${project.name}',
    );
  }

  Future<Uint8List> buildBytes({
    required DailyReport report,
    required Project project,
    required CompanyInfo company,
    required DailyReportExportStyle style,
    DailyReportAttendanceSnapshot? liveSnapshot,
  }) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    final snap = liveSnapshot ?? report.attendanceSnapshot;
    final contractor = company.name.trim().isNotEmpty
        ? company.name.trim()
        : (project.company.trim().isNotEmpty
            ? project.company.trim()
            : '—');

    switch (style) {
      case DailyReportExportStyle.ozet:
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            build: (ctx) => _ozetBody(
              report: report,
              project: project,
              contractor: contractor,
              snap: snap,
            ),
          ),
        );
      case DailyReportExportStyle.standart:
      case DailyReportExportStyle.gelismis:
        final advanced = style == DailyReportExportStyle.gelismis;
        doc.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(22),
            build: (ctx) => _standartBody(
              report: report,
              project: project,
              contractor: contractor,
              snap: snap,
              advanced: advanced,
            ),
          ),
        );
        if (report.photos.isNotEmpty) {
          doc.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(22),
              build: (ctx) => [
                _docHeader(
                  project: project,
                  contractor: contractor,
                  report: report,
                ),
                pw.SizedBox(height: 12),
                _sectionTitle('FOTOĞRAFLAR'),
                pw.SizedBox(height: 8),
                ..._photoWidgets(report.photos, withCaptions: true),
                pw.SizedBox(height: 20),
                _signatureBlock(),
              ],
            ),
          );
        }
    }

    return Uint8List.fromList(await doc.save());
  }

  List<pw.Widget> _ozetBody({
    required DailyReport report,
    required Project project,
    required String contractor,
    required DailyReportAttendanceSnapshot? snap,
  }) {
    return [
      _docHeader(project: project, contractor: contractor, report: report),
      pw.SizedBox(height: 14),
      _weatherLine(report.weather),
      pw.SizedBox(height: 12),
      _sectionTitle('PUANTAJ ÖZETİ'),
      pw.SizedBox(height: 6),
      _attendanceSummary(snap),
      pw.SizedBox(height: 12),
      _sectionTitle('YAPILAN İŞLER'),
      pw.SizedBox(height: 6),
      ..._workCategoryBlocks(report, truncateEach: 220),
      pw.SizedBox(height: 20),
      _signatureBlock(),
      pw.SizedBox(height: 8),
      pw.Text(
        '${AppInfo.displayName} · Özet çıktı',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    ];
  }

  List<pw.Widget> _standartBody({
    required DailyReport report,
    required Project project,
    required String contractor,
    required DailyReportAttendanceSnapshot? snap,
    required bool advanced,
  }) {
    final widgets = <pw.Widget>[
      _docHeader(project: project, contractor: contractor, report: report),
      pw.SizedBox(height: 10),
      _weatherLine(report.weather),
      pw.SizedBox(height: 12),
      _sectionTitle('PUANTAJ / PERSONEL'),
      pw.SizedBox(height: 6),
      _attendanceSummary(snap),
    ];

    if (advanced && snap != null && snap.people.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_personBreakdown(snap));
    }

    widgets.addAll([
      pw.SizedBox(height: 12),
      _sectionTitle('YAPILAN İŞLER'),
      pw.SizedBox(height: 6),
      ..._workCategoryBlocks(report),
      pw.SizedBox(height: 12),
      _sectionTitle('GELEN MALZEME'),
      pw.SizedBox(height: 6),
      _materialTable(
        report.incomingMaterials,
        advanced: advanced,
        incoming: true,
      ),
      pw.SizedBox(height: 12),
      _sectionTitle('SİPARİŞ VERİLEN MALZEMELER'),
      pw.SizedBox(height: 6),
      _materialTable(report.orderedMaterials, advanced: advanced),
      pw.SizedBox(height: 12),
      _sectionTitle('MAKİNE / EKİPMAN PUANTAJI'),
      pw.SizedBox(height: 6),
      _machineTable(report.machines, advanced: advanced),
      pw.SizedBox(height: 12),
      _sectionTitle('NOT'),
      pw.SizedBox(height: 6),
      pw.Container(
        width: double.infinity,
        constraints: const pw.BoxConstraints(minHeight: 36),
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.7),
        ),
        child: pw.Text(
          advanced && report.weather?.offlineNote.isNotEmpty == true
              ? report.weather!.offlineNote
              : '',
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ),
      pw.SizedBox(height: 18),
      _signatureBlock(),
      pw.SizedBox(height: 8),
      pw.Text(
        '${AppInfo.displayName} · '
        '${advanced ? 'Gelişmiş' : 'Standart'} çıktı',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    ]);

    if (!advanced && report.photos.isEmpty) {
      // foto yoksa imza bu sayfada kalır
    }

    return widgets;
  }

  pw.Widget _docHeader({
    required Project project,
    required String contractor,
    required DailyReport report,
  }) {
    final logo = _projectLogoImage(project);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          color: _headerBg,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: pw.Column(
            children: [
              if (logo != null) ...[
                pw.Container(
                  height: 52,
                  alignment: pw.Alignment.center,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 6),
              ],
              pw.Text(
                'GÜNLÜK ŞANTİYE RAPORU',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                project.name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _blue,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        _kv('İŞİN ADI', project.name),
        _kv('YÜKLENİCİ', contractor),
        if (project.code.trim().isNotEmpty) _kv('İŞ KODU', project.code.trim()),
        pw.SizedBox(height: 4),
        pw.Text(
          PuantajDate.longLabel(report.date),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    );
  }

  pw.MemoryImage? _projectLogoImage(Project project) {
    if (!project.hasLogo) return null;
    try {
      return pw.MemoryImage(base64Decode(project.logoBase64));
    } catch (_) {
      return null;
    }
  }

  pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$k  ',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
              ),
            ),
            pw.TextSpan(
              text: v,
              style: const pw.TextStyle(fontSize: 9, color: _ink),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _weatherLine(DailyReportWeather? w) {
    if (w == null) {
      return pw.Text(
        'Hava Durumu  —',
        style: const pw.TextStyle(fontSize: 10, color: _muted),
      );
    }
    final parts = <String>[
      if (w.description.isNotEmpty) w.description.toUpperCase(),
      if (w.temperatureC != null)
        '${w.temperatureC!.toStringAsFixed(0)}°C',
      if (w.nightTemperatureC != null)
        'Gece ${w.nightTemperatureC!.toStringAsFixed(0)}°C',
      if (w.humidityPercent != null)
        'Nem %${w.humidityPercent!.toStringAsFixed(0)}',
      if (w.windKmh != null) 'Rüzgar ${w.windKmh!.toStringAsFixed(0)} km/s',
      if (w.locationLabel.isNotEmpty) w.locationLabel,
    ];
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _band,
        border: pw.Border.all(color: _line, width: 0.5),
      ),
      child: pw.Text(
        'Hava Durumu  ${parts.join(' · ')}',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: _headerBg,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _attendanceSummary(DailyReportAttendanceSnapshot? snap) {
    if (snap == null) {
      return pw.Text(
        'Puantaj kaydı yok',
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _statBox('Mevcut', '${snap.present}'),
            _statBox('Yarım', '${snap.half}'),
            _statBox('İzin', '${snap.leave}'),
            _statBox('Yok', '${snap.absent}'),
            _statBox(
              'Toplam P.',
              '${snap.present + snap.half + snap.leave}',
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Adam-saat: ${_fmt(snap.totalAdamSaat)} · '
          'Yevmiye: ${_fmt(snap.totalYevmiye)}',
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ],
    );
  }

  pw.Widget _statBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
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
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _personBreakdown(DailyReportAttendanceSnapshot snap) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Personel', 'Durum', 'Saat', 'Mesai', 'Yevmiye'],
      data: [
        for (final p in snap.people)
          [
            p.personName,
            p.status,
            '${p.hours}',
            _fmt(p.overtimeHours),
            _fmt(p.yevmiye),
          ],
      ],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: _ink,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      border: pw.TableBorder.all(color: _line, width: 0.4),
    );
  }

  List<pw.Widget> _workCategoryBlocks(
    DailyReport report, {
    int? truncateEach,
  }) {
    final entries = <(String, String)>[
      ('İNŞAAT İŞLERİ', report.workConstruction),
      ('ELEKTRİK İŞLERİ', report.workElectrical),
      ('MEKANİK İŞLER', report.workMechanical),
    ];
    final nonEmpty = [
      for (final e in entries)
        if (e.$2.trim().isNotEmpty) e,
    ];
    if (nonEmpty.isEmpty) {
      return [
        pw.Text(
          '—',
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
      ];
    }
    return [
      for (final e in nonEmpty) ...[
        pw.Text(
          e.$1,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _blue,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line, width: 0.7),
          ),
          child: pw.Text(
            truncateEach != null
                ? _truncate(e.$2.trim(), truncateEach)
                : e.$2.trim(),
            style: const pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 3),
          ),
        ),
      ],
    ];
  }

  pw.Widget _materialTable(
    List<DailyReportMaterial> items, {
    required bool advanced,
    bool incoming = false,
  }) {
    if (items.isEmpty) {
      return pw.Text(
        'Kayıt yok',
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      );
    }
    final headers = incoming
        ? (advanced
            ? const [
                'Tarih',
                'Firma',
                'Ürün',
                'Miktar',
                'Birim',
                'Fiyat',
                'Not',
              ]
            : const [
                'Tarih',
                'Firma',
                'Ürün',
                'Miktar',
                'Birim',
                'Fiyat',
              ])
        : (advanced
            ? const ['Malzeme', 'Miktar', 'Birim', 'Tedarikçi / Sipariş', 'Not']
            : const ['Malzeme', 'Miktar', 'Birim', 'Not']);
    final data = [
      for (final m in items)
        if (incoming)
          advanced
              ? [
                  m.supplyDate,
                  m.supplierOrOrder,
                  m.name,
                  m.quantity,
                  m.unit,
                  m.price,
                  m.note,
                ]
              : [
                  m.supplyDate,
                  m.supplierOrOrder,
                  m.name,
                  m.quantity,
                  m.unit,
                  m.price,
                ]
        else
          advanced
              ? [
                  m.name,
                  m.quantity,
                  m.unit,
                  m.supplierOrOrder,
                  m.note,
                ]
              : [
                  m.name,
                  m.quantity,
                  m.unit,
                  m.note.isNotEmpty ? m.note : m.supplierOrOrder,
                ],
    ];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: _ink,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      border: pw.TableBorder.all(color: _line, width: 0.4),
    );
  }

  pw.Widget _machineTable(
    List<DailyReportMachine> items, {
    required bool advanced,
  }) {
    if (items.isEmpty) {
      return pw.Text(
        'Kayıt yok',
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      );
    }
    final headers = advanced
        ? const [
            'Makine',
            'Tip',
            'Plaka',
            'Saat',
            'Yapılan iş',
            'Operatör',
          ]
        : const ['Makine', 'Saat', 'Yapılan iş', 'Operatör'];
    final data = [
      for (final m in items)
        advanced
            ? [
                m.name,
                m.type,
                m.plateOrId,
                _fmt(m.hoursWorked),
                m.workDescription,
                m.operatorName,
              ]
            : [
                m.name,
                _fmt(m.hoursWorked),
                m.workDescription,
                m.operatorName,
              ],
    ];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: _ink,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      border: pw.TableBorder.all(color: _line, width: 0.4),
    );
  }

  pw.Widget _signatureBlock() {
    pw.Widget col(String title) => pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 3),
            padding: const pw.EdgeInsets.fromLTRB(6, 6, 6, 28),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line, width: 0.7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Ad Soyad / İmza',
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ],
            ),
          ),
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(children: [col('FORMU DOLDURAN'), col('İNCELEYEN'), col('ONAY')]),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Yer: ________________',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                'Tarih: ________________',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _photoWidgets(
    List<DailyReportPhoto> photos, {
    required bool withCaptions,
  }) {
    final out = <pw.Widget>[];
    for (var i = 0; i < photos.length; i++) {
      final p = photos[i];
      pw.MemoryImage? img;
      try {
        if (p.dataBase64.isNotEmpty) {
          img = pw.MemoryImage(base64Decode(p.dataBase64));
        }
      } catch (_) {
        img = null;
      }
      out.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (img != null)
                pw.Container(
                  height: 220,
                  width: double.infinity,
                  alignment: pw.Alignment.center,
                  child: pw.Image(img, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  height: 40,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Fotoğraf yüklenemedi',
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  ),
                ),
              if (withCaptions) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  p.hasCaption
                      ? '${i + 1}. ${p.caption}'
                      : '${i + 1}. (açıklama yok)',
                  style: const pw.TextStyle(fontSize: 9, color: _ink),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return out;
  }

  String _fileStem(String projectName, String date, DailyReportExportStyle style) {
    final safe = projectName
        .replaceAll(RegExp(r'[^\w\s\-ğüşıöçĞÜŞİÖÇ]', caseSensitive: false), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final d = date.replaceAll('.', '');
    return 'gunluk-rapor-${style.name}-$d-${safe.isEmpty ? 'proje' : safe}';
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…';
  }
}

final dailyReportPdfService = DailyReportPdfService();
