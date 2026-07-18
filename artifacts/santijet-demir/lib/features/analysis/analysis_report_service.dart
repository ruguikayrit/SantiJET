import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';

class AnalysisReportService {
  const AnalysisReportService();

  Future<List<int>> buildPdfBytes({
    required String projectName,
    required CuttingBendingBatch batch,
    required List<CuttingBendingBatch> sourceBatches,
  }) {
    final fireSummary = computeAnalysisFireSummary(batch);
    final rawFireByDiameter = computeRawFireBreakdown(batch);
    final materialSummary = computeMaterialSummaryByDiameter(batch.pieceLines);
    final strategyComparisons = computeStrategyFireComparisons(batch);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

    final sections = <PdfReportSection>[
      _buildMetadataSection(
        projectName: projectName,
        batch: batch,
        sourceBatches: sourceBatches,
        dateFormat: dateFormat,
      ),
      _buildFireSummarySection(fireSummary, batch),
    ];

    if (batch.isOptimized) {
      final comparison = computeAnalysisComparison(batch);
      sections.add(_buildComparisonSection(comparison));
    }

    final availableStrategies =
        strategyComparisons.where((item) => item.isAvailable).toList();
    if (availableStrategies.isNotEmpty) {
      sections.add(_buildStrategySection(availableStrategies));
    }

    sections.add(_buildFireBreakdownSection(
      title: 'Ham Fire — Çap Bazında',
      subtitle: 'Kaynak parça listesinden ${CuttingBendingBatch.defaultStockBarLengthM.toStringAsFixed(0)} m stok kesim simülasyonu',
      breakdown: rawFireByDiameter,
    ));

    if (batch.isOptimized) {
      sections.add(_buildFireBreakdownSection(
        title: 'Plan Fire — Çap Bazında',
        subtitle: 'Revize parça listesi ve planlı kesim sonuçları',
        breakdown: computePlannedFireBreakdown(batch),
      ));
    }

    sections.add(_buildMaterialSummarySection(materialSummary));
    sections.add(_buildPieceListSection(
      title: 'Ham Parça Listesi',
      pieces: batch.pieceLines,
    ));

    if (batch.labelDetails.isNotEmpty) {
      sections.add(_buildLabelDetailsSection(batch));
    }

    if (batch.isOptimized) {
      final lengthChanges = computeLengthMatchChanges(batch.lengthMatches);
      if (lengthChanges.isNotEmpty) {
        sections.add(_buildLengthMatchSection(lengthChanges));
      }

      final approvedTahvil =
          batch.tahvilGroups.where((group) => group.approved).toList();
      if (approvedTahvil.isNotEmpty) {
        sections.add(_buildTahvilSection(approvedTahvil));
      }

      sections.add(_buildPieceListSection(
        title: 'Revize Parça Listesi',
        pieces: batch.revisedPieceLines,
      ));

      final comparisonRows = computePieceListComparisonRows(batch);
      sections.add(_buildPieceComparisonSection(comparisonRows));

      if (batch.stockCutPlans.isNotEmpty) {
        sections.add(_buildStockCutSummarySection(batch.stockCutPlans));
        for (final plan in batch.stockCutPlans) {
          sections.add(_buildStockCutDetailSection(plan));
        }
      }
    } else {
      sections.add(
        const PdfReportSection(
          title: 'Fire Azaltma ve Planlı Kesim',
          subtitle:
              'Fire analizi henüz çalıştırılmadı. Ham veri ve ham fire sonuçları raporlanmıştır.',
          keyValues: [
            ('Durum', 'Analiz bekleniyor'),
          ],
        ),
      );
    }

    final batchLabel = sourceBatches.length > 1
        ? '${sourceBatches.length} dosya birleşik analiz'
        : batch.title;

    return exportService.buildMultiSectionPdfBytes(
      title: 'Hesap ve Analiz Raporu',
      subtitle: '$projectName · $batchLabel',
      sections: sections,
    );
  }

  Future<void> previewReport({
    required String projectName,
    required CuttingBendingBatch batch,
    required List<CuttingBendingBatch> sourceBatches,
  }) async {
    final bytes = await buildPdfBytes(
      projectName: projectName,
      batch: batch,
      sourceBatches: sourceBatches,
    );
    await exportService.previewPdfBytes(bytes);
  }

  Future<void> shareReport({
    required String projectName,
    required CuttingBendingBatch batch,
    required List<CuttingBendingBatch> sourceBatches,
  }) async {
    final bytes = await buildPdfBytes(
      projectName: projectName,
      batch: batch,
      sourceBatches: sourceBatches,
    );
    final safeName = batch.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    await exportService.sharePdfBytes(
      bytes: bytes,
      fileName: 'santijet_analiz_$safeName.pdf',
    );
  }

  PdfReportSection _buildMetadataSection({
    required String projectName,
    required CuttingBendingBatch batch,
    required List<CuttingBendingBatch> sourceBatches,
    required DateFormat dateFormat,
  }) {
    final totalPieces =
        batch.pieceLines.fold(0, (sum, piece) => sum + piece.quantity);
    final sourceTitles = sourceBatches.map((item) => item.title).join(', ');

    return PdfReportSection(
      title: 'Rapor Bilgileri',
      keyValues: [
        ('Proje', projectName.isEmpty ? '—' : projectName),
        ('Analiz başlığı', batch.title),
        if (sourceBatches.length > 1) ('Kaynak dosyalar', sourceTitles),
        ('Oluşturulma', dateFormat.format(batch.createdAt)),
        if (batch.optimizationAppliedAt != null)
          ('Analiz tamamlanma', dateFormat.format(batch.optimizationAppliedAt!)),
        ('Satır sayısı', AppFormat.integer(batch.pieceLines.length)),
        ('Toplam adet', AppFormat.integer(totalPieces)),
        ('Stok uzunluğu', '${CuttingBendingBatch.defaultStockBarLengthM.toStringAsFixed(0)} m'),
        (
          'Analiz durumu',
          batch.isOptimized ? 'Tamamlandı' : 'Ham veri — analiz bekleniyor',
        ),
        if (batch.optimizationStrategy != null)
          ('Aktif strateji', batch.optimizationStrategy!.label),
      ],
    );
  }

  PdfReportSection _buildFireSummarySection(
    AnalysisFireSummary summary,
    CuttingBendingBatch batch,
  ) {
    final values = <(String, String)>[
      ('Ham tonaj', _tonnage(summary.rawMaterialTonnage)),
      ('Ham stok tonajı', _tonnage(summary.rawStockTonnage)),
      ('Ham fire', '${_tonnage(summary.rawWasteTonnage)} (${_percent(summary.rawWastePercent)})'),
    ];

    if (summary.isPlannedReady) {
      values.addAll([
        ('Plan stok tonajı', _tonnage(summary.plannedStockTonnage!)),
        ('Plan fire', '${_tonnage(summary.plannedWasteTonnage!)} (${_percent(summary.plannedWastePercent!)})'),
        ('Kazanç', '${_tonnage(summary.savedWasteTonnage)} (${_percent(summary.savedWastePercent)})'),
      ]);
    }

    if (batch.isOptimized) {
      values.addAll([
        (
          'Uzunluk eşleştirme grupları',
          AppFormat.integer(
            batch.lengthMatches.where((group) => group.approved).length,
          ),
        ),
        (
          'Onaylı tahvil grupları',
          AppFormat.integer(
            batch.tahvilGroups.where((group) => group.approved).length,
          ),
        ),
        (
          'Kesim planı çap sayısı',
          AppFormat.integer(batch.stockCutPlans.length),
        ),
      ]);
    }

    return PdfReportSection(
      title: 'Fire Özeti',
      keyValues: values,
    );
  }

  PdfReportSection _buildComparisonSection(AnalysisComparison comparison) {
    return PdfReportSection(
      title: 'Mukayese Özeti',
      keyValues: [
        ('Ham satır / adet', '${AppFormat.integer(comparison.rawLineCount)} / ${AppFormat.integer(comparison.rawPieceCount)}'),
        ('Revize satır / adet', '${AppFormat.integer(comparison.revisedLineCount)} / ${AppFormat.integer(comparison.revisedPieceCount)}'),
        ('Ham tonaj', _tonnage(comparison.rawMaterialTonnage)),
        ('Revize tonaj', _tonnage(comparison.revisedMaterialTonnage)),
        ('Ham fire', '${_tonnage(comparison.rawFireTonnage)} (${_percent(comparison.rawFirePercent)})'),
        ('Plan fire', '${_tonnage(comparison.plannedFireTonnage)} (${_percent(comparison.plannedFirePercent)})'),
        ('Fire kazancı', '${_tonnage(comparison.savedFireTonnage)} (${_percent(comparison.savedFirePercent)})'),
        ('Uygulanan uzunluk eşleştirme', AppFormat.integer(comparison.lengthMatchGroupsApplied)),
        ('Uygulanan tahvil', AppFormat.integer(comparison.tahvilGroupsApplied)),
      ],
    );
  }

  PdfReportSection _buildStrategySection(
    List<StrategyFireComparison> strategies,
  ) {
    return PdfReportSection(
      title: 'Strateji Karşılaştırması',
      headers: const [
        'Strateji',
        'Plan fire (t)',
        'Plan fire (%)',
        'Kazanç (t)',
        'Kazanç (%)',
        'Durum',
      ],
      rows: strategies
          .map(
            (item) => [
              item.strategy.label,
              _tonnage(item.plannedFireTonnage ?? 0, includeUnit: false),
              _percent(item.plannedFirePercent ?? 0),
              _tonnage(item.savedFireTonnage ?? 0, includeUnit: false),
              _percent(item.savedFirePercent ?? 0),
              item.isActive
                  ? 'Aktif'
                  : item.isSaved
                      ? 'Kayıtlı'
                      : '—',
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildFireBreakdownSection({
    required String title,
    required String subtitle,
    required List<FireDiameterBreakdown> breakdown,
  }) {
    return PdfReportSection(
      title: title,
      subtitle: subtitle,
      headers: const ['ÇAP', 'Stok (t)', 'Kullanım (t)', 'Fire (t)', 'Fire (%)', 'Çubuk'],
      rows: breakdown
          .map(
            (row) => [
              'Ø${row.diameter}',
              _tonnage(row.stockTonnage, includeUnit: false),
              _tonnage(row.usedTonnage, includeUnit: false),
              _tonnage(row.wasteTonnage, includeUnit: false),
              _percent(row.wastePercent),
              AppFormat.integer(row.totalBars),
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildMaterialSummarySection(
    List<MaterialDiameterSummary> summary,
  ) {
    return PdfReportSection(
      title: 'Malzeme Özeti — Çap Bazında',
      subtitle: 'Ham parça listesi toplamları',
      headers: const ['ÇAP', 'Ağırlık/ton', 'Adet', 'Satır'],
      rows: summary
          .map(
            (row) => [
              'Ø${row.diameter}',
              _tonnage(row.tonnage, includeUnit: false),
              AppFormat.integer(row.pieceCount),
              AppFormat.integer(row.lineCount),
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildPieceListSection({
    required String title,
    required List<RebarPieceLine> pieces,
  }) {
    return PdfReportSection(
      title: title,
      headers: const ['ÇAP', 'Uzunluk (m)', 'Adet'],
      rows: pieces
          .map(
            (piece) => [
              'Ø${piece.diameter}',
              piece.lengthM.toStringAsFixed(2),
              AppFormat.integer(piece.quantity),
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildLabelDetailsSection(CuttingBendingBatch batch) {
    final included = batch.labelDetails.where((detail) => detail.included);
    return PdfReportSection(
      title: 'Metraj Etiketleri',
      subtitle: 'Analize dahil edilen etiket metinleri',
      headers: const ['Tür', 'Metin', 'Çap', 'Uzunluk (m)', 'Adet'],
      rows: included
          .map(
            (detail) => [
              detail.entityType,
              detail.sourceText,
              detail.diameter != null ? 'Ø${detail.diameter}' : '—',
              detail.lengthM?.toStringAsFixed(2) ?? '—',
              detail.quantity > 0 ? AppFormat.integer(detail.quantity) : '—',
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildLengthMatchSection(List<LengthMatchChange> changes) {
    return PdfReportSection(
      title: 'Uzunluk Eşleştirme Değişiklikleri',
      headers: const ['ÇAP', 'Önce (m)', 'Sonra (m)', 'Δ (cm)', 'Adet'],
      rows: changes
          .map(
            (change) => [
              'Ø${change.diameter}',
              change.beforeLengthM.toStringAsFixed(2),
              change.afterLengthM.toStringAsFixed(2),
              (change.deltaM * 100).toStringAsFixed(1),
              AppFormat.integer(change.quantity),
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildTahvilSection(List<TahvilSuggestion> groups) {
    return PdfReportSection(
      title: 'Onaylı Tahvil Grupları',
      headers: const ['Grup', 'Uzunluk (m)', 'Üyeler', 'Dönüşüm', 'Adet'],
      rows: groups.map((group) {
        final equivalent = pickBestTahvilEquivalentForGroup(group);
        final memberSummary = group.members
            .map((member) => 'Ø${member.diameter}×${member.quantity}')
            .join(', ');
        return [
          group.id,
          group.representativeLengthM.toStringAsFixed(2),
          memberSummary,
          equivalent == null
              ? '—'
              : 'Ø${equivalent.fromDiameter}→Ø${equivalent.toDiameter}',
          equivalent == null
              ? '—'
              : AppFormat.integer(equivalent.equivalentQuantity),
        ];
      }).toList(),
    );
  }

  PdfReportSection _buildPieceComparisonSection(
    List<PieceListComparisonRow> rows,
  ) {
    return PdfReportSection(
      title: 'Ham ↔ Revize Parça Karşılaştırması',
      headers: const [
        'Önce ÇAP',
        'Sonra ÇAP',
        'Önce (m)',
        'Sonra (m)',
        'Δ (cm)',
        'Adet',
      ],
      rows: rows
          .map(
            (row) => [
              'Ø${row.beforeDiameter}',
              'Ø${row.afterDiameter}',
              row.beforeLengthM.toStringAsFixed(2),
              row.afterLengthM.toStringAsFixed(2),
              row.isChanged ? row.deltaCm.toStringAsFixed(1) : '—',
              AppFormat.integer(row.quantity),
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildStockCutSummarySection(List<StockCutPlan> plans) {
    return PdfReportSection(
      title: 'Planlı Kesim Özeti',
      subtitle:
          '${CuttingBendingBatch.defaultStockBarLengthM.toStringAsFixed(0)} m stok çubuk — çap bazında toplamlar',
      headers: const [
        'ÇAP',
        'Çubuk',
        'Stok (m)',
        'Kullanım (m)',
        'Fire (m)',
        'Fire (%)',
        'Fire (t)',
      ],
      rows: plans
          .map(
            (plan) => [
              'Ø${plan.diameter}',
              AppFormat.integer(plan.totalBars),
              plan.totalStockM.toStringAsFixed(2),
              plan.totalUsedM.toStringAsFixed(2),
              plan.totalWasteM.toStringAsFixed(2),
              _percent(plan.wastePercent),
              _tonnage(plan.totalWasteTonnage, includeUnit: false),
            ],
          )
          .toList(),
    );
  }

  PdfReportSection _buildStockCutDetailSection(StockCutPlan plan) {
    return PdfReportSection(
      title: 'Planlı Kesim Detayı — Ø${plan.diameter}',
      subtitle:
          '${AppFormat.integer(plan.totalBars)} çubuk · fire ${_percent(plan.wastePercent)}',
      headers: const ['Çubuk', 'Parçalar', 'Kullanılan (m)', 'Fire (m)'],
      rows: plan.bars
          .map(
            (bar) => [
              '#${bar.barIndex}',
                  bar.members
                      .map(
                        (member) {
                          final label = member.elementDisplayLabel;
                          final piece =
                              '${member.lengthM.toStringAsFixed(2)} m×${member.count}';
                          return label.isEmpty ? piece : '$label $piece';
                        },
                      )
                      .join(' + '),
              bar.usedLengthM.toStringAsFixed(2),
              bar.wasteLengthM.toStringAsFixed(2),
            ],
          )
          .toList(),
    );
  }

  String _tonnage(double value, {bool includeUnit = true}) {
    final formatted = AppFormat.tonnage(value);
    return includeUnit ? '$formatted t' : formatted;
  }

  String _percent(double value) => '${value.toStringAsFixed(2)} %';
}

const analysisReportService = AnalysisReportService();
