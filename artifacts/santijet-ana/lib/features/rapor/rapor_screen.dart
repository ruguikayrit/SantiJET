import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/core/widgets/sj_primary_button.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/page_key.dart';

typedef _ModKey = String;

class _ModDef {
  const _ModDef(this.key, this.icon);
  final _ModKey key;
  final IconData icon;
}

const _modules = <_ModDef>[
  _ModDef('proje', Icons.work_outline),
  _ModDef('kesif', Icons.assignment_outlined),
  _ModDef('is-programi', Icons.calendar_today_outlined),
  _ModDef('puantaj', Icons.check_box_outlined),
  _ModDef('gunluk-rapor', Icons.wb_sunny_outlined),
  _ModDef('imalat', Icons.build_outlined),
  _ModDef('gorev', Icons.list_alt),
  _ModDef('malzeme', Icons.inventory_2_outlined),
  _ModDef('taseron', Icons.groups_outlined),
  _ModDef('butce', Icons.attach_money),
  _ModDef('hakedis', Icons.credit_card),
  _ModDef('kullanicilar', Icons.person_outline),
];

String _statusLabel(String s) {
  const map = {
    'active': 'Aktif',
    'paused': 'Duraklatıldı',
    'completed': 'Tamamlandı',
    'planned': 'Planlandı',
    'in_progress': 'Devam Ediyor',
    'delayed': 'Gecikmiş',
    'open': 'Açık',
    'done': 'Tamamlandı',
    'low': 'Düşük',
    'medium': 'Orta',
    'high': 'Yüksek',
    'present': 'Mevcut',
    'half': 'Yarım',
    'absent': 'Yok',
    'pending': 'Bekliyor',
    'approved': 'Onaylandı',
    'delivered': 'Teslim Edildi',
    'rejected': 'Reddedildi',
    'income': 'Gelir',
    'expense': 'Gider',
    'draft': 'Taslak',
    'submitted': 'Gönderildi',
    'paid': 'Ödendi',
    'cancelled': 'İptal',
  };
  return map[s] ?? s;
}

class _Section {
  const _Section({
    required this.title,
    required this.headers,
    required this.rows,
  });
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}

/// Rapor — modül seçimi, PDF (printing/pdf) ve Excel (excel/share) dışa aktarma.
class RaporScreen extends ConsumerStatefulWidget {
  const RaporScreen({super.key});

  @override
  ConsumerState<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends ConsumerState<RaporScreen> {
  final List<_ModKey> _order = [];
  var _format = 'pdf'; // pdf | excel
  var _loading = false;

  void _toggle(_ModKey key) {
    setState(() {
      if (_order.contains(key)) {
        _order.remove(key);
      } else {
        _order.add(key);
      }
    });
  }

  String _projectName(AppState app, String id) {
    for (final p in app.projects) {
      if (p.id == id) return p.name;
    }
    return id;
  }

  _Section _buildSection(AppState app, _ModKey key) {
    final title = pageLabels[key] ?? key;
    String pn(String id) => _projectName(app, id);

    switch (key) {
      case 'proje':
        return _Section(
          title: title,
          headers: const [
            'Proje Adı',
            'Konum',
            'Müteahhit',
            'Başlangıç',
            'Bitiş',
            'Bütçe (₺)',
            'Durum',
          ],
          rows: app.projects
              .map((p) => [
                    p.name,
                    p.location,
                    p.contractor,
                    p.startDate,
                    p.endDate,
                    p.budget.toString(),
                    _statusLabel(p.status),
                  ])
              .toList(),
        );
      case 'kesif':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'Başlık',
            'Tarih',
            'Konum',
            'Poz Adedi',
            'Toplam (₺)',
          ],
          rows: app.surveys
              .map((s) => [
                    pn(s.projectId),
                    s.title,
                    s.date,
                    s.location,
                    '${s.items.length}',
                    s.items
                        .fold<double>(0, (a, i) => a + i.quantity * i.unitPrice)
                        .toStringAsFixed(2),
                  ])
              .toList(),
        );
      case 'is-programi':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'Görev',
            'Sorumlu',
            'Başlangıç',
            'Bitiş',
            'İlerleme (%)',
            'Durum',
          ],
          rows: app.scheduleTasks
              .map((t) => [
                    pn(t.projectId),
                    t.name,
                    t.responsible,
                    t.startDate,
                    t.endDate,
                    '${t.progress}',
                    _statusLabel(t.status),
                  ])
              .toList(),
        );
      case 'puantaj':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'İşçi',
            'Tarih',
            'Durum',
            'Saat',
            'Not',
          ],
          rows: app.attendance
              .map((a) => [
                    pn(a.projectId),
                    a.workerName,
                    a.date,
                    _statusLabel(a.status),
                    a.hours.toString(),
                    a.note,
                  ])
              .toList(),
        );
      case 'gunluk-rapor':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'Tarih',
            'Hava',
            'Sıcaklık',
            'İşçi',
            'Faaliyetler',
            'Sorunlar',
            'Oluşturan',
          ],
          rows: app.dailyReports
              .map((r) => [
                    pn(r.projectId),
                    r.date,
                    r.weather,
                    r.temperature,
                    '${r.workerCount}',
                    r.activities,
                    r.issues,
                    r.createdBy,
                  ])
              .toList(),
        );
      case 'imalat':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'İmalat',
            'Birim',
            'Planlanan',
            'Tamamlanan',
            'Birim Fiyat (₺)',
            'Tarih',
          ],
          rows: app.productions
              .map((p) => [
                    pn(p.projectId),
                    p.name,
                    p.unit,
                    p.plannedQty.toString(),
                    p.completedQty.toString(),
                    p.unitPrice.toString(),
                    p.date,
                  ])
              .toList(),
        );
      case 'gorev':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'Görev',
            'Açıklama',
            'Atanan',
            'Son Tarih',
            'Öncelik',
            'Durum',
          ],
          rows: app.tasks
              .map((t) => [
                    pn(t.projectId),
                    t.title,
                    t.description,
                    t.assignee,
                    t.deadline,
                    _statusLabel(t.priority),
                    _statusLabel(t.status),
                  ])
              .toList(),
        );
      case 'malzeme':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'Tür',
            'Malzeme',
            'Birim',
            'Miktar',
            'Kullanılan',
            'Tedarikçi',
            'Tarih',
            'Birim Fiyat (₺)',
            'Durum',
          ],
          rows: [
            ...app.materials.map((m) => [
                  pn(m.projectId),
                  'Stok',
                  m.name,
                  m.unit,
                  m.quantity.toString(),
                  m.usedQty.toString(),
                  m.supplier,
                  m.deliveryDate,
                  m.unitPrice.toString(),
                  '',
                ]),
            ...app.materialRequests.map((m) => [
                  pn(m.projectId),
                  'Talep',
                  m.name,
                  m.unit,
                  m.quantity.toString(),
                  '',
                  m.requestedBy,
                  m.requestDate,
                  '',
                  _statusLabel(m.status),
                ]),
          ],
        );
      case 'taseron':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'Taşeron',
            'İletişim',
            'Telefon',
            'Uzmanlık',
            'Sözleşme (₺)',
            'Başlangıç',
            'Bitiş',
            'Durum',
          ],
          rows: app.subcontractors
              .map((s) => [
                    pn(s.projectId),
                    s.name,
                    s.contactPerson,
                    s.phone,
                    s.specialty,
                    s.contractAmount.toString(),
                    s.startDate,
                    s.endDate,
                    _statusLabel(s.status),
                  ])
              .toList(),
        );
      case 'butce':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'Tür',
            'Kategori',
            'Açıklama',
            'Tutar (₺)',
            'Tarih',
          ],
          rows: app.budget
              .map((b) => [
                    pn(b.projectId),
                    _statusLabel(b.type),
                    b.category,
                    b.description,
                    b.amount.toString(),
                    b.date,
                  ])
              .toList(),
        );
      case 'hakedis':
        return _Section(
          title: title,
          headers: const [
            'Proje',
            'No',
            'Dönem',
            'Müteahhit',
            'Tarih',
            'Kalem',
            'Toplam (₺)',
            'Durum',
          ],
          rows: app.hakedisler
              .map((h) => [
                    pn(h.projectId),
                    h.number,
                    h.period,
                    h.contractor,
                    h.date,
                    '${h.items.length}',
                    h.items
                        .fold<double>(0, (a, i) => a + i.quantity * i.unitPrice)
                        .toFixed(2),
                    _statusLabel(h.status),
                  ])
              .toList(),
        );
      case 'kullanicilar':
        return _Section(
          title: title,
          headers: const [
            'Ad Soyad',
            'Rol',
            'Meslek',
            'Şirket',
            'Telefon',
            'Adres',
          ],
          rows: app.appUsers
              .map((u) => [
                    u.name,
                    app.roles
                            .where((r) => r.id == u.roleId)
                            .map((r) => r.name)
                            .firstOrNull ??
                        u.roleId,
                    u.profession,
                    u.company,
                    u.phone,
                    u.address,
                  ])
              .toList(),
        );
      default:
        return _Section(title: title, headers: const [], rows: const []);
    }
  }

  Future<void> _generate() async {
    if (_order.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir modül seçmelisiniz.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final app = ref.read(appStateProvider);
      final sections = _order.map((k) => _buildSection(app, k)).toList();
      if (_format == 'pdf') {
        await _exportPdf(sections, app.projects.length);
      } else {
        await _exportExcel(sections);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor oluşturulamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf(List<_Section> sections, int projectCount) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text(
            'ŞantiJET – Rapor',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFFE85D04),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DateTime.now().day.toString().padLeft(2, '0')}.'
            '${DateTime.now().month.toString().padLeft(2, '0')}.'
            '${DateTime.now().year} · $projectCount Proje',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          for (final s in sections) ...[
            pw.Text(
              s.title,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            if (s.rows.isEmpty)
              pw.Text(
                'Kayıt bulunamadı.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: s.headers,
                data: s.rows,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF16213E),
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
              ),
            pw.SizedBox(height: 18),
          ],
        ],
      ),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'santiye-rapor-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _exportExcel(List<_Section> sections) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.delete(defaultSheet);
    }
    for (final s in sections) {
      var name = s.title.replaceAll(RegExp(r'[\\/?*\[\]]'), '');
      if (name.length > 31) name = name.substring(0, 31);
      if (name.isEmpty) name = 'Sayfa';
      final sheet = excel[name];
      sheet.appendRow(
        s.headers.map((h) => TextCellValue(h)).toList(),
      );
      for (final row in s.rows) {
        sheet.appendRow(row.map((c) => TextCellValue(c)).toList());
      }
    }
    final encoded = excel.encode();
    if (encoded == null) throw Exception('Excel oluşturulamadı');
    final bytes = Uint8List.fromList(encoded);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'santiye-rapor-$stamp.xlsx';
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: filename,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      fileNameOverrides: [filename],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final selected = _order.toSet();

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Rapor Oluştur',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                Text(
                  'Format',
                  style: TextStyle(
                    color: c.foreground,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _formatChip(c, 'pdf', 'PDF', Icons.picture_as_pdf_outlined),
                      _formatChip(c, 'excel', 'Excel (.xlsx)', Icons.grid_on),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Modüller (${_order.length}/${_modules.length})',
                        style: TextStyle(
                          color: c.foreground,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(
                        () {
                          _order
                            ..clear()
                            ..addAll(_modules.map((m) => m.key));
                        },
                      ),
                      child: Text('Tümü', style: TextStyle(color: c.primary)),
                    ),
                    TextButton(
                      onPressed: () => setState(_order.clear),
                      child: Text(
                        'Temizle',
                        style: TextStyle(color: c.mutedForeground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _modules)
                      _moduleCard(c, m, selected.contains(m.key)),
                  ],
                ),
                if (_order.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rapor Sırası',
                          style: TextStyle(
                            color: c.foreground,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < _order.length; i++)
                          _orderRow(c, i),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SjPrimaryButton(
                  label: _format == 'pdf' ? 'PDF Oluştur' : 'Excel Oluştur',
                  loading: _loading,
                  onPressed: _generate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatChip(ThemeColors c, String value, String label, IconData icon) {
    final on = _format == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _format = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: on ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: on ? Colors.white : c.mutedForeground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: on ? Colors.white : c.mutedForeground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moduleCard(ThemeColors c, _ModDef m, bool checked) {
    return InkWell(
      onTap: () => _toggle(m.key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: checked
              ? c.primary.withValues(alpha: 0.12)
              : c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: checked ? c.primary : c.card),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: checked ? c.primary : c.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                m.icon,
                size: 16,
                color: checked ? Colors.white : c.mutedForeground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pageLabels[m.key] ?? m.key,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: checked ? c.primary : c.foreground,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderRow(ThemeColors c, int i) {
    final key = _order[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: c.primary,
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pageLabels[key] ?? key,
              style: TextStyle(color: c.foreground, fontFamily: 'Inter'),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: i == 0
                ? null
                : () => setState(() {
                      final t = _order[i - 1];
                      _order[i - 1] = _order[i];
                      _order[i] = t;
                    }),
            icon: const Icon(Icons.keyboard_arrow_up, size: 20),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: i == _order.length - 1
                ? null
                : () => setState(() {
                      final t = _order[i + 1];
                      _order[i + 1] = _order[i];
                      _order[i] = t;
                    }),
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _order.removeAt(i)),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }
}

extension on double {
  String toFixed(int n) => toStringAsFixed(n);
}
