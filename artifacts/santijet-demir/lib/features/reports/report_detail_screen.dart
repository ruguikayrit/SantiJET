import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/mock/mock_reports.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/domain/entities/report.dart';
import 'package:santijet_demir/features/reports/providers/reports_provider.dart';
import 'package:santijet_demir/features/reports/report_context.dart';
import 'package:santijet_demir/features/reports/report_dialogs.dart';
import 'package:santijet_demir/features/reports/report_service.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  ReportCategory? _findCategory(List<ReportCategory> categories) {
    for (final c in categories) {
      if (c.id == reportId) return c;
    }
    return null;
  }

  ReportItem? _findReport(List<ReportItem> reports) {
    for (final r in reports) {
      if (r.id == reportId) return r;
    }
    return null;
  }

  ReportPayload _resolvePayload(ReportService service, ReportContext context) {
    return service.build(reportId, context);
  }

  bool _ensureCanExport(
    BuildContext context,
    ReportService service,
    ReportContext reportContext,
    String reportTitle,
  ) {
    final validation = service.validate(reportId, reportContext);
    if (validation.isValid) return true;

    showReportMissingDataDialog(
      context,
      reportTitle: reportTitle,
      missingRequirements: validation.missingRequirements,
    );
    return false;
  }

  Future<void> _previewWithDemo(
    BuildContext context, {
    required ReportPayload payload,
  }) async {
    try {
      await exportService.previewPdf(
        title: payload.title,
        headers: payload.headers,
        rows: payload.rows,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(content: Text('Önizleme hatası: $e')),
        );
      }
    }
  }

  Future<void> _shareReport(
    BuildContext context, {
    required ReportPayload payload,
  }) async {
    try {
      await exportService.sharePdf(
        title: payload.title,
        headers: payload.headers,
        rows: payload.rows,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          const SnackBar(
            content: Text('PDF paylaşıldı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(
            content: Text('Dışa aktarma hatası: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(reportCategoriesProvider);
    final reports = ref.watch(reportsProvider);
    final reportContext = ref.watch(reportContextProvider);
    final service = ref.read(reportServiceProvider);
    final generatedBy = ref.watch(profileDisplayNameProvider);

    final category = _findCategory(categories);
    final report = _findReport(reports);

    final title = report?.title ?? category?.title ?? 'Rapor';
    final format = report?.format ?? category?.format ?? 'PDF';
    final date = report?.date ?? DateTime.now();
    final generatedByName = report?.generatedBy ?? generatedBy;
    final payload = _resolvePayload(service, reportContext);
    final previewRows = payload.rows.take(8).toList();
    final colCount = payload.headers.length;

    void openPreview() {
      if (!_ensureCanExport(context, service, reportContext, title)) return;
      _previewWithDemo(context, payload: payload);
    }

    void share() {
      if (!_ensureCanExport(context, service, reportContext, title)) return;
      _shareReport(context, payload: payload);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(title, style: AppTypography.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (useDemoReports) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: AppRadii.md,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'DEMO VERİ — Bu önizleme örnek kayıtlarla üretilir. '
                'Canlı proje verisine geçince kaldırılacak.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _MetaRow('Format', format),
                _MetaRow('Satır', '${payload.rows.length}'),
                _MetaRow(
                  'Tarih',
                  DateFormat('d MMM yyyy, HH:mm').format(date),
                ),
                _MetaRow('Oluşturan', generatedByName),
                _MetaRow(
                  'Proje',
                  useDemoReports ? 'Demo Proje' : reportContext.projectName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Önizleme', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight.withValues(alpha: 0.35),
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (final h in payload.headers)
                        Expanded(
                          child: Text(
                            h,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                for (var i = 0; i < previewRows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: i < previewRows.length - 1
                          ? Border(bottom: BorderSide(color: AppColors.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        for (var c = 0; c < colCount; c++)
                          Expanded(
                            child: Text(
                              c < previewRows[i].length ? previewRows[i][c] : '',
                              style: c == 0
                                  ? AppTypography.bodySmall
                                  : AppTypography.titleMedium.copyWith(
                                      fontSize: 13,
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (payload.rows.length > previewRows.length)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '+ ${payload.rows.length - previewRows.length} satır daha',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                icon: Icons.download,
                label: 'İndir / Önizle',
                onPressed: openPreview,
              ),
              _ActionButton(
                icon: Icons.visibility,
                label: 'Görüntüle',
                onPressed: openPreview,
              ),
              _ActionButton(
                icon: Icons.share,
                label: 'Paylaş',
                onPressed: share,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
