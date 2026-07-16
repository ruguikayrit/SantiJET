import 'package:intl/intl.dart';
import 'package:santijet_demir/data/services/element_header_parser.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/data/services/metraj_cetvel_summary.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

class RebarMetrajReportService {
  const RebarMetrajReportService();

  Future<List<int>> buildPdfBytes({
    required String projectName,
    required RebarMetrajResult result,
  }) async {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
    final lengthFormat = NumberFormat('#,##0.##', 'tr_TR');
    final intFormat = NumberFormat('#,##0', 'tr_TR');
    final unitWeightFormat = NumberFormat('#,##0.###', 'tr_TR');

    final sections = <PdfReportSection>[
      _buildFileInfoSection(
        projectName: projectName,
        result: result,
        dateFormat: dateFormat,
        numberFormat: numberFormat,
        lengthFormat: lengthFormat,
        intFormat: intFormat,
      ),
      if (result.lines.isNotEmpty)
        _buildIcmaliSection(
          result: result,
          numberFormat: numberFormat,
          lengthFormat: lengthFormat,
          intFormat: intFormat,
          unitWeightFormat: unitWeightFormat,
        ),
      if (result.lines.isNotEmpty)
        _buildDiameterLinesSection(
          result: result,
          numberFormat: numberFormat,
          lengthFormat: lengthFormat,
          intFormat: intFormat,
        ),
      if (result.cetvel.isNotEmpty)
        ..._buildCetvelSections(
          result: result,
          numberFormat: numberFormat,
          lengthFormat: lengthFormat,
          intFormat: intFormat,
        ),
      if (result.textDetails.isNotEmpty)
        _buildLabelDetailsSection(
          result: result,
          numberFormat: numberFormat,
          lengthFormat: lengthFormat,
          intFormat: intFormat,
        ),
      if (result.warnings.isNotEmpty)
        _buildWarningsSection(result.warnings),
      if (result.skippedEntityCount > 0)
        PdfReportSection(
          title: 'Atlanan CAD Metinleri',
          subtitle:
              '${result.skippedEntityCount} metin demir etiketi olarak tanınmadı.',
        ),
    ];

    final safeFileName = result.fileName
        .replaceAll(RegExp(r'\.(dwg|dxf)$', caseSensitive: false), '');

    return exportService.buildMultiSectionPdfBytes(
      title: 'Otomatik Metraj Raporu',
      subtitle: '$projectName · $safeFileName',
      sections: sections,
    );
  }

  Future<void> previewReport({
    required String projectName,
    required RebarMetrajResult result,
  }) async {
    final bytes = await buildPdfBytes(
      projectName: projectName,
      result: result,
    );
    await exportService.previewPdfBytes(bytes);
  }

  PdfReportSection _buildFileInfoSection({
    required String projectName,
    required RebarMetrajResult result,
    required DateFormat dateFormat,
    required NumberFormat numberFormat,
    required NumberFormat lengthFormat,
    required NumberFormat intFormat,
  }) {
    return PdfReportSection(
      title: 'Dosya Bilgisi',
      keyValues: [
        ('Proje', projectName.isEmpty ? '—' : projectName),
        ('Dosya', result.fileName),
        ('Format', result.sourceFormat),
        ('Analiz tarihi', dateFormat.format(result.parsedAt)),
        ('Toplam tonaj', '${numberFormat.format(result.totalTonnage)} t'),
        ('Toplam uzunluk', '${lengthFormat.format(result.totalLengthM)} m'),
        ('Toplam çubuk', intFormat.format(result.totalBarCount)),
        ('Okunan etiket', intFormat.format(result.textDetails.length)),
        ('Dahil edilen etiket', intFormat.format(result.includedTextCount)),
        if (result.cetvel.isNotEmpty)
          ('Metraj cetveli', '${result.cetvel.length} eleman'),
      ],
    );
  }

  PdfReportSection _buildIcmaliSection({
    required RebarMetrajResult result,
    required NumberFormat numberFormat,
    required NumberFormat lengthFormat,
    required NumberFormat intFormat,
    required NumberFormat unitWeightFormat,
  }) {
    final summary = summarizeLines(result.lines);
    final typeRows = result.cetvel.isNotEmpty
        ? summarizeCetvelByType(result.cetvel)
        : const <MetrajIcmaliTypeRow>[];

    final rows = <List<String>>[
      for (final line in summary.lines)
        [
          'Ø${line.diameter}',
          unitWeightFormat.format(RebarWeightCalculator.kgPerMeter(line.diameter)),
          intFormat.format(line.barCount),
          '${lengthFormat.format(line.totalLengthM)} m',
          '${numberFormat.format(line.tonnage)} t',
        ],
      [
        'TOPLAM',
        '',
        intFormat.format(summary.totalBarCount),
        '${lengthFormat.format(summary.totalLengthM)} m',
        '${numberFormat.format(summary.totalTonnage)} t',
      ],
    ];

    final section = PdfReportSection(
      title: 'Metraj İcmali',
      subtitle:
          'Toplam ${numberFormat.format(summary.totalTonnage)} t · '
          'İnce (Ø8–12) ${numberFormat.format(summary.thinTonnage)} t · '
          'Kalın (Ø≥14) ${numberFormat.format(summary.thickTonnage)} t',
      headers: const ['Çap', 'Birim ağ.', 'Adet', 'Uzunluk', 'Tonaj'],
      rows: rows,
    );

    if (typeRows.isEmpty) return section;

    return PdfReportSection(
      title: section.title,
      subtitle: section.subtitle,
      headers: section.headers,
      rows: [
        ...section.rows,
        ['', '', '', '', ''],
        ['Eleman tipi özeti (cetvel)', '', '', '', ''],
        for (final row in typeRows)
          [
            row.typeLabel,
            intFormat.format(row.elementCount),
            intFormat.format(row.barCount),
            '',
            '${numberFormat.format(row.tonnage)} t',
          ],
      ],
    );
  }

  PdfReportSection _buildDiameterLinesSection({
    required RebarMetrajResult result,
    required NumberFormat numberFormat,
    required NumberFormat lengthFormat,
    required NumberFormat intFormat,
  }) {
    return PdfReportSection(
      title: 'Çap Bazlı Metraj',
      headers: const ['Çap', 'Çubuk', 'Uzunluk', 'Tonaj', 'Katman'],
      rows: result.lines
          .map(
            (line) => [
              'Ø${line.diameter}',
              intFormat.format(line.barCount),
              '${lengthFormat.format(line.totalLengthM)} m',
              '${numberFormat.format(line.tonnage)} t',
              line.layerName.isEmpty ? '—' : line.layerName,
            ],
          )
          .toList(),
    );
  }

  List<PdfReportSection> _buildCetvelSections({
    required RebarMetrajResult result,
    required NumberFormat numberFormat,
    required NumberFormat lengthFormat,
    required NumberFormat intFormat,
  }) {
    final cetvelSummary = summarizeCetvel(result.cetvel);
    final grouped = <StructuralElementType, List<MetrajCetvelEntry>>{};
    for (final entry in result.cetvel) {
      final type = StructuralElementType.fromLetter(entry.elementTypeCode);
      grouped.putIfAbsent(type, () => []).add(entry);
    }

    final sections = <PdfReportSection>[
      PdfReportSection(
        title: 'Metraj Cetveli Özeti',
        keyValues: [
          ('Eleman sayısı', intFormat.format(cetvelSummary.elementCount)),
          ('Satır sayısı', intFormat.format(cetvelSummary.rowCount)),
          ('Toplam tonaj', '${numberFormat.format(cetvelSummary.totalTonnage)} t'),
          ('Toplam uzunluk', '${lengthFormat.format(cetvelSummary.totalLengthM)} m'),
          (
            'İnce / Kalın',
            '${numberFormat.format(cetvelSummary.thinTonnage)} t / '
                '${numberFormat.format(cetvelSummary.thickTonnage)} t',
          ),
        ],
      ),
    ];

    for (final group in grouped.entries) {
      final rows = <List<String>>[];
      for (final entry in group.value) {
        rows.add([
          entry.title,
          '×${entry.benzerCount}',
          '—',
          '—',
          '—',
          '—',
          '${numberFormat.format(entry.totalTonnage)} t',
        ]);
        for (var i = 0; i < entry.rows.length; i++) {
          final row = entry.rows[i];
          rows.add([
            '',
            '',
            '${i + 1}',
            row.role.label,
            '${row.diameter}',
            intFormat.format(row.unitQuantity),
            lengthFormat.format(row.lengthM),
            numberFormat.format(row.totalTonnage),
          ]);
        }
        rows.add([
          'Eleman toplamı',
          '',
          '',
          '',
          '',
          intFormat.format(entry.totalBarCount),
          '${lengthFormat.format(entry.totalLengthM)} m',
          '${numberFormat.format(entry.totalTonnage)} t',
        ]);
        rows.add(['', '', '', '', '', '', '', '']);
      }

      final typeTonnage =
          group.value.fold(0.0, (sum, entry) => sum + entry.totalTonnage);

      sections.add(
        PdfReportSection(
          title: 'Metraj Cetveli — ${group.key.label}',
          subtitle:
              '${group.value.length} eleman · ${numberFormat.format(typeTonnage)} t',
          headers: const [
            'Eleman',
            'Benzer',
            '#',
            'Demir',
            'Ø',
            'Adet',
            'Uzunluk (m)',
            'Tonaj (t)',
          ],
          rows: rows,
        ),
      );
    }

    return sections;
  }

  PdfReportSection _buildLabelDetailsSection({
    required RebarMetrajResult result,
    required NumberFormat numberFormat,
    required NumberFormat lengthFormat,
    required NumberFormat intFormat,
  }) {
    return PdfReportSection(
      title: 'Analiz Edilen Demir Etiketleri',
      subtitle: '${result.textDetails.length} etiket (adet + çap + uzunluk)',
      headers: const [
        'Durum',
        'Tip',
        'Etiket',
        'Eleman',
        'Ø',
        'Adet',
        'Uzunluk (m)',
        'Ağırlık',
      ],
      rows: result.textDetails
          .map(
            (detail) => [
              detail.included ? 'Dahil' : 'Hariç',
              detail.entityType,
              _truncate(detail.sourceText, 48),
              detail.elementCode ?? '—',
              detail.diameter?.toString() ?? '—',
              detail.included ? intFormat.format(detail.quantity) : '—',
              detail.lengthM != null
                  ? lengthFormat.format(detail.lengthM)
                  : '—',
              detail.included
                  ? '${numberFormat.format(detail.weightKg)} kg'
                  : (detail.skipReason ?? '—'),
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildWarningsSection(List<String> warnings) {
    return PdfReportSection(
      title: 'Uyarılar',
      rows: warnings.map((warning) => [warning]).toList(),
      headers: const ['Mesaj'],
    );
  }

  String _truncate(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength - 1)}…';
  }
}

const rebarMetrajReportService = RebarMetrajReportService();
