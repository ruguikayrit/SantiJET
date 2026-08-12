import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../domain/daily_report/attendance_snapshot_builder.dart';
import '../../domain/entities/company_info.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/project.dart';
import 'daily_report_export_sections.dart';
import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;

/// Günlük rapor PDF — seçilen başlıklara göre form çıktısı.
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
    required DailyReportExportSections sections,
    DailyReportAttendanceSnapshot? liveSnapshot,
  }) async {
    await exportMany(
      reports: [report],
      project: project,
      company: company,
      sections: sections,
      liveSnapshots: liveSnapshot == null ? null : [liveSnapshot],
    );
  }

  /// Bir veya daha fazla günü tek PDF’te birleştirir (günler arası yeni sayfa).
  Future<void> exportMany({
    required List<DailyReport> reports,
    required Project project,
    required CompanyInfo company,
    required DailyReportExportSections sections,
    List<DailyReportAttendanceSnapshot?>? liveSnapshots,
  }) async {
    if (reports.isEmpty) {
      throw ArgumentError('En az bir günlük rapor gerekli');
    }
    final bytes = await buildBytesMany(
      reports: reports,
      project: project,
      company: company,
      sections: sections,
      liveSnapshots: liveSnapshots,
    );
    final sorted = _sorted(reports);
    final stem = sorted.length == 1
        ? _fileStem(project.name, sorted.first.date)
        : _fileStemRange(project.name, sorted.first.date, sorted.last.date);
    final label = sorted.length == 1
        ? sorted.first.date
        : '${sorted.first.date} – ${sorted.last.date}';
    await file_access.downloadBytesFile(
      fileName: '$stem.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: 'Şantiye Raporu ($label) — ${project.name}',
    );
  }

  Future<Uint8List> buildBytes({
    required DailyReport report,
    required Project project,
    required CompanyInfo company,
    required DailyReportExportSections sections,
    DailyReportAttendanceSnapshot? liveSnapshot,
  }) {
    return buildBytesMany(
      reports: [report],
      project: project,
      company: company,
      sections: sections,
      liveSnapshots: liveSnapshot == null ? null : [liveSnapshot],
    );
  }

  Future<Uint8List> buildBytesMany({
    required List<DailyReport> reports,
    required Project project,
    required CompanyInfo company,
    required DailyReportExportSections sections,
    List<DailyReportAttendanceSnapshot?>? liveSnapshots,
  }) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    final sorted = _sorted(reports);
    final contractor = company.name.trim().isNotEmpty
        ? company.name.trim()
        : (project.company.trim().isNotEmpty
            ? project.company.trim()
            : '—');

    final byDateSnap = <String, DailyReportAttendanceSnapshot?>{};
    if (liveSnapshots != null) {
      for (var i = 0; i < reports.length && i < liveSnapshots.length; i++) {
        byDateSnap[reports[i].date] = liveSnapshots[i];
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(22, 22, 22, 28),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 6),
          child: pw.Text(
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          for (var i = 0; i < sorted.length; i++) {
            if (i > 0) widgets.add(pw.NewPage());
            final report = sorted[i];
            final snap =
                byDateSnap[report.date] ?? report.attendanceSnapshot;
            widgets.addAll(
              _body(
                report: report,
                project: project,
                contractor: contractor,
                snap: snap,
                sections: sections,
                multiDay: sorted.length > 1,
                dayIndex: i + 1,
                dayCount: sorted.length,
              ),
            );
          }
          return widgets;
        },
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  List<DailyReport> _sorted(List<DailyReport> reports) {
    final copy = List<DailyReport>.from(reports);
    copy.sort((a, b) {
      final da = PuantajDate.tryParse(a.date);
      final db = PuantajDate.tryParse(b.date);
      if (da == null || db == null) return a.date.compareTo(b.date);
      return da.compareTo(db);
    });
    return copy;
  }

  List<pw.Widget> _body({
    required DailyReport report,
    required Project project,
    required String contractor,
    required DailyReportAttendanceSnapshot? snap,
    required DailyReportExportSections sections,
    bool multiDay = false,
    int dayIndex = 1,
    int dayCount = 1,
  }) {
    final widgets = <pw.Widget>[
      _docHeader(
        project: project,
        contractor: contractor,
        report: report,
        multiDay: multiDay,
        dayIndex: dayIndex,
        dayCount: dayCount,
      ),
    ];

    void gap() => widgets.add(pw.SizedBox(height: 12));

    /// Sayfa sonunda yalnız başlık kalmasını engeller.
    void ensureSectionSpace([double min = 78]) {
      widgets.add(pw.NewPage(freeSpace: min));
    }

    /// Başlık + içerik birlikte kalır; sığmazsa ikisi de sonraki sayfaya geçer.
    void addCompactSection(String title, pw.Widget body, {double minSpace = 78}) {
      gap();
      ensureSectionSpace(minSpace);
      widgets.add(_sectionBlock(title, body));
    }

    if (sections.weather) {
      gap();
      widgets.add(_weatherLine(report.weather));
    }

    if (sections.puantajCounts || sections.puantajNames) {
      gap();
      ensureSectionSpace(100);
      final lead = <pw.Widget>[
        _sectionTitle('PUANTAJ'),
        pw.SizedBox(height: 6),
      ];
      if (sections.puantajCounts) {
        lead.add(_attendanceSummary(snap));
      }
      if (sections.puantajNames &&
          (snap == null || snap.people.isEmpty)) {
        if (sections.puantajCounts) lead.add(pw.SizedBox(height: 6));
        lead.add(
          pw.Text(
            'Personel listesi yok',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        );
      }
      widgets.add(
        _KeepTogether(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: lead,
          ),
        ),
      );
      if (sections.puantajNames &&
          snap != null &&
          snap.people.isNotEmpty) {
        if (sections.puantajCounts) widgets.add(pw.SizedBox(height: 6));
        widgets.add(_personBreakdown(snap));
      }
    }

    if (sections.photos) {
      gap();
      ensureSectionSpace(130);
      if (report.photos.isEmpty) {
        widgets.add(
          _sectionBlock(
            'FOTOĞRAFLAR',
            pw.Text(
              'Kayıt yok',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
        );
      } else {
        final rows = _photoWidgets(
          report.photosByWorkCategory,
          withCaptions: true,
        );
        widgets.add(
          _KeepTogether(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('FOTOĞRAFLAR'),
                pw.SizedBox(height: 6),
                if (rows.isNotEmpty) rows.first,
              ],
            ),
          ),
        );
        if (rows.length > 1) {
          widgets.addAll(rows.skip(1));
        }
      }
    }

    if (sections.workDone) {
      gap();
      ensureSectionSpace(90);
      final blocks = _workCategoryBlocks(report);
      widgets.add(
        _KeepTogether(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('YAPILAN İŞLER'),
              pw.SizedBox(height: 6),
              if (blocks.isNotEmpty) blocks.first,
            ],
          ),
        ),
      );
      if (blocks.length > 1) {
        widgets.addAll(blocks.skip(1));
      }
    }

    if (sections.nextDayPlan) {
      addCompactSection(
        'PLANLI İŞLER LİSTESİ',
        pw.Container(
          width: double.infinity,
          constraints: const pw.BoxConstraints(minHeight: 40),
          padding: const pw.EdgeInsets.all(8),
          alignment: pw.Alignment.centerLeft,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line, width: 0.7),
          ),
          child: pw.Text(
            report.nextDayPlan.trim().isEmpty
                ? '—'
                : _formatBulletedLines(report.nextDayPlan.trim()),
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 10,
              color: report.nextDayPlan.trim().isEmpty ? _muted : _ink,
              lineSpacing: 3,
            ),
          ),
        ),
        minSpace: 90,
      );
    }

    if (sections.incomingMaterials) {
      _addTableSection(
        widgets,
        title: 'GELEN MALZEME',
        table: _materialTable(
          report.incomingMaterials,
          advanced: true,
          kind: _MaterialKind.incoming,
        ),
        isEmpty: report.incomingMaterials.isEmpty,
        gap: gap,
        ensureSpace: ensureSectionSpace,
      );
    }

    if (sections.outgoingMaterials) {
      _addTableSection(
        widgets,
        title: 'GİDEN MALZEME',
        table: _materialTable(
          report.outgoingMaterials,
          advanced: true,
          kind: _MaterialKind.outgoing,
        ),
        isEmpty: report.outgoingMaterials.isEmpty,
        gap: gap,
        ensureSpace: ensureSectionSpace,
      );
    }

    if (sections.orderedMaterials) {
      _addTableSection(
        widgets,
        title: 'SİPARİŞ VERİLEN MALZEME',
        table: _materialTable(
          report.orderedMaterials,
          advanced: true,
          kind: _MaterialKind.ordered,
        ),
        isEmpty: report.orderedMaterials.isEmpty,
        gap: gap,
        ensureSpace: ensureSectionSpace,
      );
    }

    if (sections.machines) {
      _addTableSection(
        widgets,
        title: 'İŞ MAKİNESİ PUANTAJI',
        table: _machineTable(report.machines, advanced: true, vehicle: false),
        isEmpty: report.machines.isEmpty,
        gap: gap,
        ensureSpace: ensureSectionSpace,
      );
    }

    if (sections.vehicles) {
      _addTableSection(
        widgets,
        title: 'VASITA PUANTAJI',
        table: _machineTable(report.vehicles, advanced: true, vehicle: true),
        isEmpty: report.vehicles.isEmpty,
        gap: gap,
        ensureSpace: ensureSectionSpace,
      );
    }

    if (sections.signatures) {
      gap();
      ensureSectionSpace(100);
      widgets.add(_KeepTogether(child: _signatureBlock()));
    }

    return widgets;
  }

  /// Başlık + içerik tek parça; sayfa sığmazsa birlikte kayar.
  pw.Widget _sectionBlock(String title, pw.Widget body) {
    return _KeepTogether(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(title),
          pw.SizedBox(height: 6),
          body,
        ],
      ),
    );
  }

  /// Uzun tablolar sayfalar arası akabilir; başlık yalnız kalmaz (freeSpace).
  void _addTableSection(
    List<pw.Widget> widgets, {
    required String title,
    required pw.Widget table,
    required bool isEmpty,
    required void Function() gap,
    required void Function([double]) ensureSpace,
  }) {
    gap();
    ensureSpace(isEmpty ? 70 : 110);
    if (isEmpty) {
      widgets.add(_sectionBlock(title, table));
      return;
    }
    widgets.add(_sectionTitle(title));
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(table);
  }

  pw.Widget _docHeader({
    required Project project,
    required String contractor,
    required DailyReport report,
    bool multiDay = false,
    int dayIndex = 1,
    int dayCount = 1,
  }) {
    final logo = _projectLogoImage(project);
    final title = multiDay
        ? 'ŞANTİYE RAPORU ($dayIndex/$dayCount)'
        : 'GÜNLÜK ŞANTİYE RAPORU';
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
                title,
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
      if (w.maxHumidityPercent != null)
        'Max nem %${w.maxHumidityPercent!.toStringAsFixed(0)}'
      else if (w.humidityPercent != null)
        'Nem %${w.humidityPercent!.toStringAsFixed(0)}',
      if (w.windGustKmh != null)
        'Ani rüzgar ${w.windGustKmh!.toStringAsFixed(0)} km/s'
      else if (w.windKmh != null)
        'Rüzgar ${w.windKmh!.toStringAsFixed(0)} km/s',
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
    final people = [...snap.people]
      ..sort(AttendanceSnapshotBuilder.compareByRoleRank);
    return _centeredTable(
      headers: const [
        'No',
        'Personel',
        'Meslek',
        'Ekip',
        'Durum',
        'Mesai',
        'Yevmiye',
      ],
      data: [
        for (var i = 0; i < people.length; i++)
          [
            '${i + 1}',
            titleCaseTr(people[i].personName),
            people[i].profession.isNotEmpty
                ? titleCaseTr(people[i].profession)
                : '—',
            people[i].team.isNotEmpty ? titleCaseTr(people[i].team) : '—',
            people[i].status,
            _fmt(people[i].overtimeHours),
            _fmt(people[i].yevmiye),
          ],
      ],
    );
  }

  List<pw.Widget> _workCategoryBlocks(
    DailyReport report, {
    int? truncateEach,
  }) {
    final entries = <(String, String)>[
      ('İNŞAAT İŞLERİ', report.effectiveWorkConstruction),
      ('ELEKTRİK İŞLERİ', report.effectiveWorkElectrical),
      ('MEKANİK İŞLER', report.effectiveWorkMechanical),
    ];
    final nonEmpty = [
      for (final e in entries)
        if (e.$2.trim().isNotEmpty) e,
    ];
    if (nonEmpty.isEmpty) {
      return [
        _KeepTogether(
          child: pw.Text(
            '—',
            textAlign: pw.TextAlign.left,
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
        ),
      ];
    }
    return [
      for (final e in nonEmpty)
        _KeepTogether(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  e.$1,
                  textAlign: pw.TextAlign.left,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _blue,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.only(bottom: 8),
                alignment: pw.Alignment.centerLeft,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _line, width: 0.7),
                ),
                child: pw.Text(
                  truncateEach != null
                      ? _truncate(_formatBulletedLines(e.$2.trim()), truncateEach)
                      : _formatBulletedLines(e.$2.trim()),
                  textAlign: pw.TextAlign.left,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _ink,
                    lineSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            ? const [
                'Malzeme Açıklaması',
                'Miktar',
                'Birim',
                'Tedarikçi / Sipariş',
                'Satın Alma Onayı',
                'Not',
              ]
            : const [
                'Malzeme Açıklaması',
                'Miktar',
                'Birim',
                'Satın Alma Onayı',
                'Not',
              ]);
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
                  m.purchaseApproved ? '✓' : '',
                  m.note,
                ]
              : [
                  m.name,
                  m.quantity,
                  m.unit,
                  m.purchaseApproved ? '✓' : '',
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
    final typeHeader = vehicle ? 'Marka/Model' : 'Tip';
    final opHeader = vehicle ? 'Şoför' : 'Operatör';
    final headers = vehicle
        ? (advanced
            ? [
                nameHeader,
                typeHeader,
                'Plaka',
                'Saat',
                'Yapılan iş',
                opHeader,
              ]
            : [nameHeader, 'Saat', 'Yapılan iş', opHeader])
        : (advanced
            ? [
                nameHeader,
                typeHeader,
                'Firma',
                'Plaka',
                'Saat',
                'Yapılan iş',
                opHeader,
              ]
            : [nameHeader, 'Firma', 'Saat', 'Yapılan iş', opHeader]);
    final data = [
      for (final m in items)
        if (vehicle)
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
                ]
        else
          advanced
              ? [
                  m.name,
                  m.type,
                  m.company,
                  m.plateOrId,
                  _fmt(m.hoursWorked),
                  m.workDescription,
                  m.operatorName,
                ]
              : [
                  m.name,
                  m.company,
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
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Ad Soyad / İmza',
                  textAlign: pw.TextAlign.center,
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
      ],
    );
  }

  List<pw.Widget> _photoWidgets(
    List<DailyReportPhoto> photos, {
    required bool withCaptions,
    double maxHeight = 200,
  }) {
    if (photos.isEmpty) return const [];

    pw.Widget cell(DailyReportPhoto p, {required double cellHeight}) {
      pw.MemoryImage? img;
      try {
        if (p.dataBase64.isNotEmpty) {
          img = pw.MemoryImage(base64Decode(p.dataBase64));
        }
      } catch (_) {
        img = null;
      }
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (img != null)
                pw.SizedBox(
                  height: cellHeight,
                  width: double.infinity,
                  child: pw.Center(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Image(
                        img,
                        height: cellHeight - 1,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                )
              else
                pw.Container(
                  height: cellHeight * 0.4,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Yüklenemedi',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ),
              if (withCaptions) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  p.hasCaption ? p.caption : '(açıklama yok)',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8, color: _ink),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final out = <pw.Widget>[];
    final rowHeight = maxHeight * 0.55;
    for (var i = 0; i < photos.length; i += 3) {
      final chunk = photos.skip(i).take(3).toList();
      out.add(
        _KeepTogether(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final p in chunk) cell(p, cellHeight: rowHeight),
                for (var j = chunk.length; j < 3; j++)
                  pw.Expanded(child: pw.SizedBox()),
              ],
            ),
          ),
        ),
      );
    }
    return out;
  }

  String _safeProject(String projectName) {
    final safe = projectName
        .replaceAll(RegExp(r'[^\w\s\-ğüşıöçĞÜŞİÖÇ]', caseSensitive: false), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return safe.isEmpty ? 'proje' : safe;
  }

  String _fileStem(String projectName, String date) {
    final d = date.replaceAll('.', '');
    return 'gunluk-rapor-$d-${_safeProject(projectName)}';
  }

  String _fileStemRange(String projectName, String from, String to) {
    final a = from.replaceAll('.', '');
    final b = to.replaceAll('.', '');
    return 'santiye-rapor-$a-$b-${_safeProject(projectName)}';
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  /// Her satırın başına madde işareti ekler; aynı cümleyi bir kez yazar.
  String _formatBulletedLines(String text) {
    final out = <String>[];
    final seen = <String>{};
    for (final raw in text.split('\n')) {
      final line =
          raw.trim().replaceFirst(RegExp(r'^[•\-*]+\s*'), '').trim();
      if (line.isEmpty) continue;
      final key = line.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
      if (!seen.add(key)) continue;
      out.add('• $line');
    }
    return out.isEmpty ? text.trim() : out.join('\n');
  }

  String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…';
  }
}

enum _MaterialKind { incoming, outgoing, ordered }

/// MultiPage içinde başlık+içerik gibi blokların bölünmesini engeller.
/// Sığmazsa tamamı sonraki sayfaya kayar.
class _KeepTogether extends pw.SingleChildWidget {
  _KeepTogether({required pw.Widget child}) : super(child: child);

  @override
  bool get canSpan => false;

  @override
  bool get hasMoreWidgets => false;

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context);
  }
}

final dailyReportPdfService = DailyReportPdfService();
