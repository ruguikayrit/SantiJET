import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/widget_snapshot_capture.dart';
import '../../domain/entities/production.dart';
import '../../domain/models/production_group_summary.dart';
import '../../features/daily_report/widgets/period_production_chart_panel.dart';
import '../../features/daily_report/widgets/period_site_report_visual_widgets.dart';
import '../../features/imalat/widgets/production_group_summary_strip.dart';
import 'period_site_report_builder.dart';
import 'period_site_report_export_sections.dart';
import 'production_performance_chart_options.dart';
import 'puantaj_report_builder.dart';

/// Uygulama önizlemesiyle aynı grafikler — PDF gömme için PNG.
class PeriodSiteReportPdfChartImage {
  const PeriodSiteReportPdfChartImage({
    required this.bytes,
    required this.logicalWidth,
    required this.logicalHeight,
  });

  final Uint8List bytes;
  final double logicalWidth;
  final double logicalHeight;
}

class PeriodSiteReportPdfChartBundle {
  const PeriodSiteReportPdfChartBundle({
    this.imalatBlocks = const [],
    this.verimBlocks = const [],
  });

  final List<PeriodSiteReportPdfChartImage> imalatBlocks;
  final List<PeriodSiteReportPdfChartImage> verimBlocks;
}

abstract final class PeriodSiteReportPdfChartCapture {
  static const _contentWidth = 720.0;

  static Widget _captureShell(BuildContext context, Widget child) {
    return UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: Theme(
        data: Theme.of(context),
        child: Material(
          color: AppColors.cardSurface,
          child: child,
        ),
      ),
    );
  }

  static Future<PeriodSiteReportPdfChartImage?> _capture(
    BuildContext context,
    Widget child, {
    required double height,
  }) async {
    if (!context.mounted) return null;
    try {
      final bytes = await captureWidgetToPng(
        context,
        _captureShell(context, child),
        logicalSize: Size(_contentWidth, height),
        pixelRatio: 2,
      );
      if (bytes == null || bytes.isEmpty) return null;
      return PeriodSiteReportPdfChartImage(
        bytes: bytes,
        logicalWidth: _contentWidth,
        logicalHeight: height,
      );
    } catch (e, st) {
      debugPrint('PeriodSiteReportPdfChartCapture._capture: $e\n$st');
      return null;
    }
  }

  static double _groupWrapHeight(int count, bool verimOnly) {
    final cardH = verimOnly ? 108.0 : 148.0;
    final perRow = ((count + 2) / 3).ceil().clamp(1, 99);
    return 32 + perRow * (cardH + 8);
  }

  static Widget _groupStripSection({
    required BuildContext context,
    required List<ProductionGroupSummary> summaries,
    required bool verimTitleOnly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Grup özeti (dönem)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ProductionGroupSummaryStrip(
          summaries: summaries,
          selectedTeamKey: null,
          onTeamTap: (_) {},
          verimTitleOnly: verimTitleOnly,
          wrapForExport: true,
        ),
      ],
    );
  }

  static Future<void> _captureImalatBlocks({
    required BuildContext context,
    required PeriodSiteReportData report,
    required Map<String, Production> productionsById,
    required List<PeriodSiteReportPdfChartImage> out,
  }) async {
    final daySet = report.days.toSet();
    final perfPeriod = report.period == PuantajReportPeriod.weekly
        ? ProductionPerformancePeriod.daily
        : ProductionPerformancePeriod.weekly;

    final chart = await _capture(
      context,
      PeriodProductionChartPanel.imalat(report: report),
      height: 300,
    );
    if (chart != null) out.add(chart);

    if (report.imalatGroupSummaries.isNotEmpty && context.mounted) {
      final strip = await _capture(
        context,
        _groupStripSection(
          context: context,
          summaries: report.imalatGroupSummaries,
          verimTitleOnly: false,
        ),
        height: _groupWrapHeight(report.imalatGroupSummaries.length, false),
      );
      if (strip != null) out.add(strip);
    }

    for (final row in report.imalatRows) {
      if (!context.mounted) break;
      final production = productionsById[row.productionId];
      final img = await _capture(
        context,
        PeriodImalatReportCard(
          row: row,
          production: production,
          perfPeriod: perfPeriod,
          daySet: daySet,
          expandCharts: production != null,
        ),
        height: production != null ? 980 : 220,
      );
      if (img != null) out.add(img);
    }
  }

  static Future<void> _captureVerimBlocks({
    required BuildContext context,
    required PeriodSiteReportData report,
    required Map<String, Production> productionsById,
    required List<PeriodSiteReportPdfChartImage> out,
  }) async {
    final daySet = report.days.toSet();
    final teams = PeriodVerimTeamBlock.fromReport(report, productionsById);

    final chart = await _capture(
      context,
      PeriodProductionChartPanel.verim(report: report),
      height: 300,
    );
    if (chart != null) out.add(chart);

    if (report.imalatGroupSummaries.isNotEmpty && context.mounted) {
      final strip = await _capture(
        context,
        _groupStripSection(
          context: context,
          summaries: report.imalatGroupSummaries,
          verimTitleOnly: true,
        ),
        height: _groupWrapHeight(report.imalatGroupSummaries.length, true),
      );
      if (strip != null) out.add(strip);
    }

    for (final block in teams) {
      if (!context.mounted) break;
      final teamImg = await _capture(
        context,
        PeriodVerimTeamHeaderCard(block: block),
        height: 120,
      );
      if (teamImg != null) out.add(teamImg);

      for (var i = 0; i < block.rows.length; i++) {
        if (!context.mounted) break;
        final row = block.rows[i];
        final production = productionsById[row.productionId];
        final hasCharts =
            production != null && production.dailyEntries.isNotEmpty;
        final img = await _capture(
          context,
          PeriodVerimReportCard(
            row: row,
            production: production,
            daySet: daySet,
            colorIndex: i,
            expandCharts: hasCharts,
          ),
          height: hasCharts ? 820 : 100,
        );
        if (img != null) out.add(img);
      }
    }
  }

  static Future<PeriodSiteReportPdfChartBundle> capture({
    required BuildContext context,
    required PeriodSiteReportData report,
    required Map<String, Production> productionsById,
    required PeriodSiteReportExportSections sections,
  }) async {
    final imalatBlocks = <PeriodSiteReportPdfChartImage>[];
    final verimBlocks = <PeriodSiteReportPdfChartImage>[];

    if (sections.imalat && report.imalatRows.isNotEmpty) {
      await _captureImalatBlocks(
        context: context,
        report: report,
        productionsById: productionsById,
        out: imalatBlocks,
      );
    }

    if (sections.verim && report.verimRows.isNotEmpty) {
      await _captureVerimBlocks(
        context: context,
        report: report,
        productionsById: productionsById,
        out: verimBlocks,
      );
    }

    return PeriodSiteReportPdfChartBundle(
      imalatBlocks: imalatBlocks,
      verimBlocks: verimBlocks,
    );
  }
}
