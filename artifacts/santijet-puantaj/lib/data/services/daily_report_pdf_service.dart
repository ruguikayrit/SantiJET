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
      _sectionTitle('FOTOĞRAFLAR'),
      pw.SizedBox(height: 6),
      if (report.photos.isEmpty)
        pw.Text('—', style: const pw.TextStyle(fontSize: 10, color: _muted))
      else
        ..._photoWidgets(report.photos, withCaptions: true, maxHeight: 120),
      pw.SizedBox(height: 12),
      _sectionTitle('YAPILAN İŞLER'),
      pw.SizedBox(height: 6),
      ..._workCategoryBlocks(report, truncateEach: 220),
      pw.SizedBox(height: 20),
      _signatureBlock(),
      pw.SizedBox(height: 8),
      pw.Text(
        '${AppInfo.displayName} · Özet çıktı',
        textAlign: pw.TextAlign.center,
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
      _sectionTitle('PUANTAJ ÖZETİ'),
      pw.SizedBox(height: 6),
      _attendanceSummary(snap),
    ];

    if (advanced && snap != null && snap.people.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_personBreakdown(snap));
    }

    widgets.addAll([
      pw.SizedBox(height: 12),
      _sectionTitle('FOTOĞRAFLAR'),
      pw.SizedBox(height: 6),
      if (report.photos.isEmpty)
        pw.Text(
          'Kayıt yok',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        )
      else
        ..._photoWidgets(report.photos, withCaptions: true),
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
        kind: _MaterialKind.incoming,
      ),
      pw.SizedBox(height: 12),
      _sectionTitle('GİDEN MALZEME'),
      pw.SizedBox(height: 6),
      _materialTable(
        report.outgoingMaterials,
        advanced: advanced,
        kind: _MaterialKind.outgoing,
      ),
      pw.SizedBox(height: 12),
      _sectionTitle('SİPARİŞ VERİLEN MALZEME'),
      pw.SizedBox(height: 6),
      _materialTable(
        report.orderedMaterials,
        advanced: advanced,
        kind: _MaterialKind.ordered,
      ),
      pw.SizedBox(height: 12),
      _sectionTitle('İŞ MAKİNESİ PUANTAJI'),
      pw.SizedBox(height: 6),
      _machineTable(report.machines, advanced: advanced, vehicle: false),
      pw.SizedBox(height: 12),
      _sectionTitle('VASITA PUANTAJI'),
      pw.SizedBox(height: 6),
      _machineTable(report.vehicles, advanced: advanced, vehicle: true),
      pw.SizedBox(height: 12),
      _sectionTitle('ERTESİ GÜN PLANI'),
      pw.SizedBox(height: 6),
      pw.Container(
        width: double.infinity,
        constraints: const pw.BoxConstraints(minHeight: 40),
        padding: const pw.EdgeInsets.all(8),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.7),
        ),
        child: pw.Text(
          report.nextDayPlan.trim().isEmpty ? '—' : report.nextDayPlan.trim(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 10,
            color: report.nextDayPlan.trim().isEmpty ? _muted : _ink,
            lineSpacing: 3,
          ),
        ),
      ),
      pw.SizedBox(height: 12),
      _sectionTitle('NOT'),
      pw.SizedBox(height: 6),
      pw.Container(
        width: double.infinity,
        constraints: const pw.BoxConstraints(minHeight: 36),
        padding: const pw.EdgeInsets.all(6),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.7),
        ),
        child: pw.Text(
          advanced && report.weather?.offlineNote.isNotEmpty == true
              ? report.weather!.offlineNote
              : '',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ),
      pw.SizedBox(height: 18),
      _signatureBlock(),
      pw.SizedBox(height: 8),
      pw.Text(
        '${AppInfo.displayName} · '
        '${advanced ? 'Gelişmiş' : 'Standart'} çıktı',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    ]);

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
        textAlign: pw.TextAlign.center,
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
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: _headerBg,
      child: pw.Text(
        title,
        textAlign: pw.TextAlign.center,
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
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
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
          textAlign: pw.TextAlign.center,
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
    return _centeredTable(
      headers: const [
        'Personel',
        'Ekip',
        'Durum',
        'Saat',
        'Mesai',
        'Yevmiye',
      ],
      data: [
        for (final p in snap.people)
          [
            p.personName,
            p.team.isEmpty ? '—' : p.team,
            p.status,
            '${p.hours}',
            _fmt(p.overtimeHours),
            _fmt(p.yevmiye),
          ],
      ],
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
    final caps = report.photoCaptions;
    final nonEmpty = [
      for (final e in entries)
        if (e.$2.trim().isNotEmpty) e,
    ];
    if (nonEmpty.isEmpty && caps.isEmpty) {
      return [
        pw.Text(
          '—',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
      ];
    }
    return [
      for (final e in nonEmpty) ...[
        pw.Text(
          e.$1,
          textAlign: pw.TextAlign.center,
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
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line, width: 0.7),
          ),
          child: pw.Text(
            truncateEach != null
                ? _truncate(e.$2.trim(), truncateEach)
                : e.$2.trim(),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 3),
          ),
        ),
      ],
      if (caps.isNotEmpty) ...[
        pw.Text(
          'FOTOĞRAF AÇIKLAMALARI',
          textAlign: pw.TextAlign.center,
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
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line, width: 0.7),
          ),
          child: pw.Text(
            caps.map((c) => '• $c').join('\n'),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 3),
          ),
        ),
      ],
    ];
  }

  pw.Widget _materialTable(
    List<DailyReportMaterial> items, {
    required bool advanced,
    required _MaterialKind kind,
  }) {
    if (items.isEmpty) {
      return pw.Text(
        'Kayıt yok',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      );
    }
    final stockLike =
        kind == _MaterialKind.incoming || kind == _MaterialKind.outgoing;
    final partyHeader =
        kind == _MaterialKind.outgoing ? 'Alıcı / Yer' : 'Firma';
    final headers = stockLike
        ? (advanced
            ? [
                'Tarih',
                partyHeader,
                'Ürün',
                'Miktar',
                'Birim',
                'Fiyat',
                'Not',
              ]
            : [
                'Tarih',
                partyHeader,
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
        if (stockLike)
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
    return _centeredTable(headers: headers, data: data);
  }

  pw.Widget _machineTable(
    List<DailyReportMachine> items, {
    required bool advanced,
    required bool vehicle,
  }) {
    if (items.isEmpty) {
      return pw.Text(
        'Kayıt yok',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      );
    }
    final nameHeader = vehicle ? 'Vasıta' : 'Makine';
    final headers = advanced
        ? [
            nameHeader,
            'Tip',
            'Plaka',
            'Saat',
            'Yapılan iş',
            'Operatör',
          ]
        : [nameHeader, 'Saat', 'Yapılan iş', 'Operatör'];
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
    return _centeredTable(headers: headers, data: data);
  }

  pw.Widget _centeredTable({
    required List<String> headers,
    required List<List<String>> data,
  }) {
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
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      border: pw.TableBorder.all(color: _line, width: 0.4),
      cellAlignment: pw.Alignment.center,
      headerAlignment: pw.Alignment.center,
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
    double maxHeight = 200,
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
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (img != null)
                pw.Container(
                  height: maxHeight,
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
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  ),
                ),
              if (withCaptions) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  p.hasCaption
                      ? '${i + 1}. ${p.caption}'
                      : '${i + 1}. (açıklama yok)',
                  textAlign: pw.TextAlign.center,
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

enum _MaterialKind { incoming, outgoing, ordered }

final dailyReportPdfService = DailyReportPdfService();
