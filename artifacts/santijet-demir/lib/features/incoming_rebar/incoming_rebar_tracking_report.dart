import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/entities/survey.dart';

const _ledgerDiameters = [8, 10, 12, 14, 16, 20, 22, 25, 28];

const _monthNames = [
  'OCAK',
  'ŞUBAT',
  'MART',
  'NİSAN',
  'MAYIS',
  'HAZİRAN',
  'TEMMUZ',
  'AĞUSTOS',
  'EYLÜL',
  'EKİM',
  'KASIM',
  'ARALIK',
];

class IncomingTrackingReport {
  const IncomingTrackingReport({
    required this.sections,
    required this.sheets,
  });

  final List<PdfReportSection> sections;
  final List<ExcelReportSheet> sheets;

  bool get isEmpty => sections.every((section) => section.rows.isEmpty);
}

IncomingTrackingReport buildIncomingTrackingReport(
  List<DeliveryItem> source, {
  List<SurveyImalat> imalats = const [],
}) {
  final deliveries = [...source]..sort((a, b) => a.date.compareTo(b.date));
  final diameters = _reportDiameters(deliveries);
  final years = deliveries.map((item) => item.date.year).toSet();
  final showYear = years.length > 1;

  final capTotals = {for (final diameter in diameters) diameter: 0.0};
  final monthTotals = <int, Map<int, double>>{};
  final monthFactory = <int, double>{};
  final monthKantar = <int, double>{};
  final detailRows = <List<String>>[];
  final detailTones = <List<int>>[];
  final diameterTotals = List<double>.filled(diameters.length, 0);
  var factoryTotal = 0.0;
  var kantarTotal = 0.0;

  for (final delivery in deliveries) {
    final byDiameter = {for (final diameter in diameters) diameter: 0.0};
    for (final line in delivery.diameterLines) {
      if (line.delivered <= 0 || !byDiameter.containsKey(line.diameter)) {
        continue;
      }
      byDiameter[line.diameter] = byDiameter[line.diameter]! + line.delivered;
    }
    final factory = byDiameter.values.fold(0.0, (sum, value) => sum + value);
    final kantar = delivery.tonnage > 0 ? delivery.tonnage : 0.0;
    final monthKey = delivery.date.year * 100 + delivery.date.month;

    monthTotals.putIfAbsent(
      monthKey,
      () => {for (final diameter in diameters) diameter: 0.0},
    );
    for (var index = 0; index < diameters.length; index++) {
      final diameter = diameters[index];
      final amount = byDiameter[diameter] ?? 0;
      capTotals[diameter] = capTotals[diameter]! + amount;
      monthTotals[monthKey]![diameter] =
          monthTotals[monthKey]![diameter]! + amount;
      diameterTotals[index] += amount;
    }
    monthFactory[monthKey] = (monthFactory[monthKey] ?? 0) + factory;
    monthKantar[monthKey] = (monthKantar[monthKey] ?? 0) + kantar;
    factoryTotal += factory;
    kantarTotal += kantar;

    final purchase = delivery.orderNo.trim().isNotEmpty
        ? delivery.orderNo.trim()
        : delivery.supplier.trim();
    final fark = _farkLabel(factory - kantar);
    final row = [
      purchase,
      delivery.irsaliyeNo.trim(),
      _monthLabel(delivery.date, showYear: showYear),
      '${delivery.date.day}.${delivery.date.month}.${delivery.date.year}',
      ...diameters.map((diameter) => _ton(byDiameter[diameter] ?? 0)),
      _ton(factory),
      _ton(kantar),
      fark.value,
      fark.text,
    ];
    detailRows.add(row);
    detailTones.add(_farkTone(row.length, fark.tone));
  }

  if (detailRows.isNotEmpty) {
    final totalFark = _farkLabel(factoryTotal - kantarTotal);
    final totalRow = [
      'TOPLAM',
      '',
      '',
      '',
      ...diameterTotals.map(_ton),
      _ton(factoryTotal),
      _ton(kantarTotal),
      totalFark.value,
      totalFark.text,
    ];
    detailRows.add(totalRow);
    detailTones.add(_farkTone(totalRow.length, totalFark.tone));
  }

  final detailHeaders = [
    'SATIN ALMA',
    'İRSALİYE NO',
    'AY',
    'SEVK TARİHİ',
    ...diameters.map((diameter) => 'Q$diameter'),
    'FABRİKA',
    'KANTAR',
    'KANTAR FARKI',
    'FARK AÇIKLAMASI',
  ];

  final capHeaders = [
    'ÇAP',
    ...diameters.map((diameter) => 'Q$diameter'),
    'TOPLAM',
  ];
  final capRows = [
    [
      '',
      ...diameters.map((diameter) => _ton(capTotals[diameter] ?? 0)),
      _ton(factoryTotal),
    ],
  ];
  final imalatTables = _imalatDetailTables(imalats);

  final monthHeaders = [
    'AY',
    ...diameters.map((diameter) => 'Q$diameter'),
    'FABRİKA',
    'KANTAR',
  ];
  final surveyByDiameter = <int, double>{};
  for (final imalat in imalats) {
    for (final line in imalat.diameterLines) {
      if (line.planned <= 0) continue;
      surveyByDiameter[line.diameter] =
          (surveyByDiameter[line.diameter] ?? 0) + line.planned;
    }
  }
  final compareDiameters = {
    ...surveyByDiameter.keys,
    ...capTotals.keys.where((diameter) => (capTotals[diameter] ?? 0) > 0),
  }.toList()
    ..sort();
  final compareHeaders = ['ÇAP', 'KEŞİF', 'TESLİM EDİLEN', 'KALAN'];
  var kesifTotal = 0.0;
  var teslimTotal = 0.0;
  final compareRows = <List<String>>[
    for (final diameter in compareDiameters)
      () {
        final kesif = surveyByDiameter[diameter] ?? 0;
        final teslim = capTotals[diameter] ?? 0;
        kesifTotal += kesif;
        teslimTotal += teslim;
        return [
          'Q$diameter',
          _amount(kesif),
          _amount(teslim),
          _amount(kesif - teslim),
        ];
      }(),
    if (compareDiameters.isNotEmpty)
      [
        'TOPLAM',
        _amount(kesifTotal),
        _amount(teslimTotal),
        _amount(kesifTotal - teslimTotal),
      ],
  ];

  final monthKeys = monthTotals.keys.toList()..sort();
  final monthRows = [
    for (final key in monthKeys)
      [
        _monthKeyLabel(key, showYear: showYear),
        ...diameters.map((diameter) => _ton(monthTotals[key]![diameter] ?? 0)),
        _ton(monthFactory[key] ?? 0),
        _ton(monthKantar[key] ?? 0),
      ],
    if (monthKeys.isNotEmpty)
      [
        'TOPLAM',
        ...diameterTotals.map(_ton),
        _ton(factoryTotal),
        _ton(kantarTotal),
      ],
  ];

  return IncomingTrackingReport(
    sections: [
      PdfReportSection(
        title: 'Mukayese Çap Tablosu',
        headers: compareHeaders,
        rows: compareRows,
        compact: true,
        emphasizeTotals: true,
      ),
      for (final table in imalatTables)
        PdfReportSection(
          title: table.title,
          subtitle: 'Çap Detay Tablosu',
          headers: _imalatHeaders,
          rows: table.rows,
          compact: true,
          emphasizeTotals: true,
        ),
      PdfReportSection(
        title: 'İcmal — Çap Bazlı',
        headers: capHeaders,
        rows: deliveries.isEmpty ? const [] : capRows,
        compact: true,
        emphasizeTotals: true,
      ),
      PdfReportSection(
        title: 'İcmal — Ay Bazlı',
        headers: monthHeaders,
        rows: monthRows,
        compact: true,
        emphasizeTotals: true,
      ),
      PdfReportSection(
        title: 'Sevkiyat Listesi',
        headers: detailHeaders,
        rows: detailRows,
        cellTones: detailTones,
        compact: true,
        emphasizeTotals: true,
      ),
    ],
    sheets: [
      ExcelReportSheet(
        name: 'Takip',
        title: 'Mukayese Çap Tablosu',
        headers: compareHeaders,
        rows: compareRows,
        emphasizeTotals: true,
      ),
      for (final table in imalatTables)
        ExcelReportSheet(
          name: 'Takip',
          title: '${table.title} — Çap Detay Tablosu',
          headers: _imalatHeaders,
          rows: table.rows,
          emphasizeTotals: true,
        ),
      ExcelReportSheet(
        name: 'Takip',
        title: 'İcmal — Çap Bazlı',
        headers: capHeaders,
        rows: deliveries.isEmpty ? const [] : capRows,
        emphasizeTotals: true,
      ),
      ExcelReportSheet(
        name: 'Takip',
        title: 'İcmal — Ay Bazlı',
        headers: monthHeaders,
        rows: monthRows,
        emphasizeTotals: true,
      ),
      ExcelReportSheet(
        name: 'Takip',
        title: 'Sevkiyat Listesi',
        headers: detailHeaders,
        rows: detailRows,
        cellTones: detailTones,
        emphasizeTotals: true,
      ),
    ],
  );
}

const _imalatHeaders = ['ÇAP', 'PLAN.', 'SİP.', 'TESLİM', 'BEKL.'];

({String title, List<List<String>> rows})? _imalatDetailTable(SurveyImalat imalat) {
  final grouped = <int, List<double>>{};
  for (final line in imalat.diameterLines) {
    final slot = grouped.putIfAbsent(line.diameter, () => [0, 0, 0, 0]);
    slot[0] += line.planned;
    slot[1] += line.ordered;
    slot[2] += line.delivered;
    slot[3] += line.pending;
  }
  final diameters = grouped.keys.toList()..sort();
  if (diameters.isEmpty &&
      imalat.planned <= 0 &&
      imalat.ordered <= 0 &&
      imalat.delivered <= 0 &&
      imalat.pending <= 0) {
    return null;
  }

  var plan = 0.0;
  var ordered = 0.0;
  var delivered = 0.0;
  var pending = 0.0;
  final rows = <List<String>>[];
  if (diameters.isEmpty) {
    plan = imalat.planned;
    ordered = imalat.ordered;
    delivered = imalat.delivered;
    pending = imalat.pending;
  } else {
    for (final diameter in diameters) {
      final slot = grouped[diameter]!;
      plan += slot[0];
      ordered += slot[1];
      delivered += slot[2];
      pending += slot[3];
      rows.add([
        'Q$diameter',
        _amount(slot[0]),
        _amount(slot[1]),
        _amount(slot[2]),
        _amount(slot[3]),
      ]);
    }
  }
  rows.add([
    'TOPLAM',
    _amount(plan),
    _amount(ordered),
    _amount(delivered),
    _amount(pending),
  ]);
  final name = imalat.name.trim().isEmpty ? 'İmalat' : imalat.name.trim();
  return (title: name, rows: rows);
}

List<({String title, List<List<String>> rows})> _imalatDetailTables(
  List<SurveyImalat> imalats,
) {
  return [
    for (final imalat in imalats)
      if (_imalatDetailTable(imalat) case final table?) table,
  ];
}

List<int> _reportDiameters(List<DeliveryItem> deliveries) {
  final diameters = {..._ledgerDiameters};
  for (final delivery in deliveries) {
    for (final line in delivery.diameterLines) {
      if (line.delivered <= 0) continue;
      diameters.add(line.diameter);
    }
  }
  final ordered = diameters.toList()..sort();
  return ordered;
}

String _monthLabel(DateTime date, {required bool showYear}) {
  final name = _monthNames[date.month - 1];
  return showYear ? '$name ${date.year}' : name;
}

String _monthKeyLabel(int key, {required bool showYear}) {
  final year = key ~/ 100;
  final month = key % 100;
  final name = _monthNames[month - 1];
  return showYear ? '$name $year' : name;
}

String _ton(double value) {
  if (value <= 0) return '';
  return AppFormat.tonnage(value);
}

String _amount(double value) => AppFormat.tonnage(value);

({String value, String text, int tone}) _farkLabel(double fark) {
  if (fark > 0.004) {
    return (value: _amount(fark), text: 'FAZLA TONAJ', tone: 1);
  }
  if (fark < -0.004) {
    return (value: _amount(fark), text: 'EKSİK TONAJ', tone: -1);
  }
  return (value: _amount(0), text: '', tone: 0);
}

List<int> _farkTone(int length, int tone) {
  final tones = List<int>.filled(length, 0);
  if (length >= 2 && tone != 0) {
    tones[length - 2] = tone;
    tones[length - 1] = tone;
  }
  return tones;
}
