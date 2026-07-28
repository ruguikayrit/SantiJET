import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/data/mock/mock_reports.dart';
import 'package:santijet_demir/domain/entities/report.dart';
import 'package:santijet_demir/features/reports/providers/reports_provider.dart';
import 'package:santijet_demir/features/reports/report_dialogs.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  void _openReport(
    BuildContext context,
    WidgetRef ref,
    ReportCategory category,
  ) {
    final service = ref.read(reportServiceProvider);
    if (service.isPdfReport(category.id)) {
      final contextData = ref.read(reportContextProvider);
      final validation = service.validate(category.id, contextData);
      if (!validation.isValid) {
        showReportMissingDataDialog(
          context,
          reportTitle: category.title,
          missingRequirements: validation.missingRequirements,
        );
        return;
      }
    }

    context.push(AppRoutes.reportDetail(category.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(reportCategoriesProvider);
    final recentReports = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Raporlar')),
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
                'DEMO — 16 rapor örnek veri ile hazır. İndir / Önizle ile PDF açılır.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text('Rapor Kategorileri', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryCard(
                category: cat,
                onTap: () => _openReport(context, ref, cat),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Son Raporlar', style: AppTypography.headlineMedium),
          const SizedBox(height: 10),
          ...recentReports.map((report) {
            return _ReportListTile(
              report: report,
              onTap: () => context.push(AppRoutes.reportDetail(report.id)),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final ReportCategory category;
  final VoidCallback onTap;

  IconData get _icon => switch (category.iconName) {
        'summarize' => Icons.summarize,
        'architecture' => Icons.architecture,
        'trending_up' => Icons.trending_up,
        'auto_fix_high' => Icons.auto_fix_high,
        'receipt_long' => Icons.receipt_long,
        'account_balance' => Icons.account_balance,
        'local_shipping' => Icons.local_shipping,
        'swap_vert' => Icons.swap_vert,
        'assignment' => Icons.assignment,
        'inventory_2' => Icons.inventory_2,
        'compare_arrows' => Icons.compare_arrows,
        'analytics' => Icons.analytics,
        'local_fire_department' => Icons.local_fire_department,
        'transform' => Icons.transform,
        'content_cut' => Icons.content_cut,
        'calendar_month' => Icons.calendar_month,
        'picture_as_pdf' => Icons.picture_as_pdf,
        'table_chart' => Icons.table_chart,
        'inventory' => Icons.inventory,
        'warehouse' => Icons.warehouse,
        'date_range' => Icons.date_range,
        _ => Icons.description,
      };

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, color: color, size: 24),
              const Spacer(),
              Text(category.title, style: AppTypography.titleMedium),
              Text(
                category.subtitle,
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              StatusBadge(label: category.format, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({required this.report, required this.onTap});

  final ReportItem report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatColor =
        report.format == 'PDF' ? AppColors.critical : AppColors.success;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, style: AppTypography.titleMedium),
                    Text(
                      '${report.category} · ${DateFormat('d MMM yyyy').format(report.date)}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: report.format, color: formatColor),
              const SizedBox(width: 8),
              Text(report.size, style: AppTypography.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
