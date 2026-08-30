import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../domain/entities/production.dart';

enum ProductionExportKind { imalat, verim }

class ProductionReportData {
  const ProductionReportData({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
    required this.fileStem,
    required this.rowCount,
  });

  final ProductionExportKind kind;
  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final String fileStem;
  final int rowCount;
}

abstract final class ProductionReportBuilder {
  static ProductionReportData build({
    required String projectName,
    required List<Production> productions,
    required ProductionExportKind kind,
  }) {
    final list = [...productions]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final today = PuantajDate.today();
    final stemDate = today.replaceAll('.', '');

    if (kind == ProductionExportKind.imalat) {
      return ProductionReportData(
        kind: kind,
        title: 'İmalat — $projectName',
        subtitle: projectName,
        headers: const [
          '#',
          'İmalat',
          'Konum',
          'Ekip',
          'Birim',
          'Plan metraj',
          'Gerçek metraj',
          'Metraj %',
          'Plan gün',
          'Çalışılan gün',
          'Süre %',
          'Plan AG',
          'Gerçek AG',
          'AG %',
        ],
        rows: [
          for (var i = 0; i < list.length; i++)
            _imalatRow(i + 1, list[i]),
        ],
        fileStem: 'imalat-$stemDate',
        rowCount: list.length,
      );
    }

    return ProductionReportData(
      kind: kind,
      title: 'Verim — $projectName',
      subtitle: projectName,
      headers: const [
        '#',
        'İmalat',
        'Konum',
        'Ekip',
        'Plan metraj',
        'Gerçek metraj',
        'Plan AG',
        'Gerçek AG',
        'Birim verim %',
      ],
      rows: [
        for (var i = 0; i < list.length; i++) _verimRow(i + 1, list[i]),
      ],
      fileStem: 'verim-$stemDate',
      rowCount: list.length,
    );
  }

  static List<String> _imalatRow(int index, Production p) {
    final m = p.metrics;
    return [
      '$index',
      sentenceCaseTr(p.name),
      p.locationLabel.isEmpty ? '—' : p.locationLabel,
      p.teamName.trim().isEmpty ? '—' : titleCaseTr(p.teamName),
      p.unit.trim().isEmpty ? '—' : p.unit,
      _fmt(m.metraj.planned),
      _fmt(m.metraj.actual),
      m.metraj.hasPlan ? '%${m.metraj.progressPct.toStringAsFixed(0)}' : '—',
      _fmt(m.sure.planned),
      _fmt(m.sure.actual),
      m.sure.hasPlan ? '%${m.sure.progressPct.toStringAsFixed(0)}' : '—',
      _fmt(m.labor.planned),
      _fmt(m.labor.actual),
      m.labor.hasPlan ? '%${m.labor.progressPct.toStringAsFixed(0)}' : '—',
    ];
  }

  static List<String> _verimRow(int index, Production p) {
    final m = p.metrics;
    final eff = m.unitEfficiency;
    return [
      '$index',
      sentenceCaseTr(p.name),
      p.locationLabel.isEmpty ? '—' : p.locationLabel,
      p.teamName.trim().isEmpty ? '—' : titleCaseTr(p.teamName),
      _fmt(m.metraj.planned),
      _fmt(m.metraj.actual),
      _fmt(m.labor.planned),
      _fmt(m.labor.actual),
      eff == null ? '—' : '%${(eff * 100).toStringAsFixed(0)}',
    ];
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
