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
    if (service.isPdfReport(reportId)) {
      return service.build(reportId, context);
    }

    final category = reportCategories.firstWhere(
      (item) => item.id == reportId,
      orElse: () => reportCategories.first,
    );

    return ReportPayload(
      title: category.title,
      headers: const ['Alan', 'Değer'],
      rows: [
        ['Rapor', category.title],
        ['Format', category.format],
        ['Proje', context.projectName],
        ['Durum', 'Hazırlanıyor'],
      ],
    );
  }

  bool _ensureCanExport(
    BuildContext context,
    ReportService service,
    ReportContext reportContext,
    String reportTitle,
  ) {
    if (!service.isPdfReport(reportId)) return true;

    final validation = service.validate(reportId, reportContext);
    if (validation.isValid) return true;

    showReportMissingDataDialog(
      context,
      reportTitle: reportTitle,
      missingRequirements: validation.missingRequirements,
    );
    return false;
  }

  Future<void> _exportReport(
    BuildContext context, {
    required ReportPayload payload,
    required bool asPdf,
  }) async {
    try {
      if (asPdf) {
        await exportService.sharePdf(
          title: payload.title,
          headers: payload.headers,
          rows: payload.rows,
        );
      } else {
        await exportService.shareExcel(
          title: payload.title,
          headers: payload.headers,
          rows: payload.rows,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(
            content: Text('${asPdf ? 'PDF' : 'Excel'} dışa aktarıldı'),
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

  Future<void> _previewPdf(
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
    final isPdf = format.toUpperCase() == 'PDF';
    final payload = _resolvePayload(service, reportContext);
    final previewRows = payload.rows.take(6).toList();

    void export({required bool asPdf}) {
      if (!_ensureCanExport(context, service, reportContext, title)) return;
      _exportReport(context, payload: payload, asPdf: asPdf);
    }

    void preview() {
      if (!_ensureCanExport(context, service, reportContext, title)) return;
      _previewPdf(context, payload: payload);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(title, style: AppTypography.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
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
                _MetaRow('Tarih', DateFormat('d MMM yyyy, HH:mm').format(date)),
                _MetaRow('Oluşturan', generatedByName),
                _MetaRow('Proje', reportContext.projectName),
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
                for (var i = 0; i < previewRows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: i < previewRows.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            previewRows[i].first,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            previewRows[i].length > 1 ? previewRows[i][1] : '',
                            style: AppTypography.titleMedium,
                            textAlign: TextAlign.end,
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
                label: 'İndir',
                onPressed: () => export(asPdf: isPdf),
              ),
              _ActionButton(
                icon: Icons.upload,
                label: 'Dışa Aktar',
                onPressed: () => export(asPdf: isPdf),
              ),
              _ActionButton(
                icon: Icons.share,
                label: 'Paylaş',
                onPressed: () => export(asPdf: isPdf),
              ),
              if (isPdf)
                _ActionButton(
                  icon: Icons.visibility,
                  label: 'Görüntüle',
                  onPressed: preview,
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
