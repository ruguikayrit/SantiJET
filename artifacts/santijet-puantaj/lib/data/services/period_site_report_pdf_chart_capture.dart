import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/widget_snapshot_capture.dart';
import '../../domain/entities/production.dart';
import '../../features/daily_report/widgets/period_production_chart_panel.dart';
import '../../features/imalat/widgets/production_performance_bar_chart.dart';
import '../../features/verim/widgets/verim_production_detail_sheet.dart';
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
    this.imalatSummary,
    this.verimSummary,
    this.imalatDetailByProductionId = const {},
    this.verimDetailByProductionId = const {},
  });

  final PeriodSiteReportPdfChartImage? imalatSummary;
  final PeriodSiteReportPdfChartImage? verimSummary;

  /// Performans çubuğu + çizgisel/örümcek (imalat kartı).
  final Map<String, PeriodSiteReportPdfChartImage> imalatDetailByProductionId;
  final Map<String, PeriodSiteReportPdfChartImage> verimDetailByProductionId;
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

  static Future<PeriodSiteReportPdfChartBundle> capture({
    required BuildContext context,
    required PeriodSiteReportData report,
    required Map<String, Production> productionsById,
    required PeriodSiteReportExportSections sections,
  }) async {
    final daySet = report.days.toSet();
    final perfPeriod = report.period == PuantajReportPeriod.weekly
        ? ProductionPerformancePeriod.daily
        : ProductionPerformancePeriod.weekly;

    PeriodSiteReportPdfChartImage? imalatSummary;
    PeriodSiteReportPdfChartImage? verimSummary;
    final imalatDetails = <String, PeriodSiteReportPdfChartImage>{};
    final verimDetails = <String, PeriodSiteReportPdfChartImage>{};

    if (sections.imalat && report.imalatRows.isNotEmpty) {
      if (!context.mounted) {
        return PeriodSiteReportPdfChartBundle(
          imalatSummary: imalatSummary,
          verimSummary: verimSummary,
          imalatDetailByProductionId: imalatDetails,
          verimDetailByProductionId: verimDetails,
        );
      }
      imalatSummary = await _capture(
        context,
        PeriodProductionChartPanel.imalat(report: report),
        height: 280,
      );

      for (final row in report.imalatRows) {
        if (!context.mounted) break;
        final id = row.productionId;
        if (id.isEmpty) continue;
        final production = productionsById[id];
        if (production == null) continue;

        final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            );
        final img = await _capture(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.name,
                style: titleStyle,
              ),
              const SizedBox(height: 12),
              ProductionPerformanceBarChart(
                production: production,
                fixedPeriod: perfPeriod,
                onlyDates: daySet,
                hidePeriodChips: true,
                height: 200,
              ),
              const SizedBox(height: 16),
              VerimProductionCharts(
                production: production,
                inline: true,
                chartHeight: 120,
                onlyDates: daySet,
                stackBothChartModes: true,
              ),
            ],
          ),
          height: 920,
        );
        if (img != null) imalatDetails[id] = img;
      }
    }

    if (sections.verim && report.verimRows.isNotEmpty) {
      if (!context.mounted) {
        return PeriodSiteReportPdfChartBundle(
          imalatSummary: imalatSummary,
          verimSummary: verimSummary,
          imalatDetailByProductionId: imalatDetails,
          verimDetailByProductionId: verimDetails,
        );
      }
      verimSummary = await _capture(
        context,
        PeriodProductionChartPanel.verim(report: report),
        height: 280,
      );

      for (final row in report.verimRows) {
        if (!context.mounted) break;
        final id = row.productionId;
        if (id.isEmpty) continue;
        final production = productionsById[id];
        if (production == null) continue;

        final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            );
        final img = await _capture(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.imalatName,
                style: titleStyle,
              ),
              const SizedBox(height: 12),
              VerimProductionCharts(
                production: production,
                inline: true,
                chartHeight: 120,
                onlyDates: daySet,
                stackBothChartModes: true,
              ),
            ],
          ),
          height: 780,
        );
        if (img != null) verimDetails[id] = img;
      }
    }

    return PeriodSiteReportPdfChartBundle(
      imalatSummary: imalatSummary,
      verimSummary: verimSummary,
      imalatDetailByProductionId: imalatDetails,
      verimDetailByProductionId: verimDetails,
    );
  }
}
