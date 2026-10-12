import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/incoming_rebar_report_preview.dart';
import 'package:santijet_demir/features/incoming_rebar/incoming_rebar_tracking_report.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivered_diameter_table.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';

class IncomingRebarScreen extends ConsumerStatefulWidget {
  const IncomingRebarScreen({super.key});

  @override
  ConsumerState<IncomingRebarScreen> createState() => _IncomingRebarScreenState();
}

class _IncomingRebarScreenState extends ConsumerState<IncomingRebarScreen> {
  @override
  Widget build(BuildContext context) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final deliveries = ref.watch(deliveriesProvider);
    final surveyDiameters = surveyDiametersFromImalats(
      ref.watch(surveyProjectProvider).imalats,
    );
    final summary = computeIncomingRebarSummary(
      deliveries,
      surveyDiameters: surveyDiameters,
    );
    final diameterRows = buildDeliveredDiameterRows(
      deliveries,
      surveyDiameters: surveyDiameters,
    );
    final canCreate = ref.watch(canCreateDeliveryProvider);
    final recordedTonnage = deliveries.fold(0.0, (sum, item) => sum + item.tonnage);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      floatingActionButton: hasActiveProject && canCreate
          ? FloatingActionButton(
              heroTag: 'new-delivery',
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: () => context.push(AppRoutes.selectInTransitOrder),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: Column(
        children: [
          SantijetHeader(
            subtitle: 'Gelen Demir',
            onCreateReport: () => showDeliveredTrackingReportSheet(context, ref),
          ),
          if (!hasActiveProject)
            Expanded(
              child: ModuleEmptyState(
                type: EmptyStateType.noProject,
                actionLabel: 'Proje Seç',
                onAction: () => context.push(AppRoutes.projects),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  SizedBox(
                    height: 100,
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.local_shipping_outlined,
                            color: AppColors.electricBlueLight,
                            label: 'Toplam Sipariş',
                            value: AppFormat.tonnage(summary.totalOrdered),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            label: 'Teslim Alınan',
                            value: AppFormat.tonnage(summary.totalDelivered),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.pie_chart_outline,
                            color: AppColors.electricBlueLight,
                            label: 'Teslim Oranı',
                            value: summary.totalOrdered <= 0
                                ? '%0'
                                : '%${(summary.totalDelivered / summary.totalOrdered * 100).round()}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.schedule,
                            color: const Color(0xFFF59E0B),
                            label: 'Kalan Sipariş',
                            value: AppFormat.tonnage(
                              summary.remainingOrder < 0 ? 0 : summary.remainingOrder,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.add_circle_outline,
                            color: const Color(0xFF8B5CF6),
                            label: 'Fazla Teslimat',
                            value: AppFormat.tonnage(summary.excess),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.critical,
                            label: 'Eksik Teslimat',
                            value: AppFormat.tonnage(summary.missing),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.electricBlueLight,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Çap Bazlı Durum',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C2430),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DeliveredDiameterTable(rows: diameterRows),
                  const SizedBox(height: 12),
                  _DeliveryRecordsShortcut(
                    recordCount: deliveries.length,
                    tonnage: recordedTonnage,
                    onTap: () => context.push(AppRoutes.deliveryList),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B95A5),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryRecordsShortcut extends StatelessWidget {
  const _DeliveryRecordsShortcut({
    required this.recordCount,
    required this.tonnage,
    required this.onTap,
  });

  final int recordCount;
  final double tonnage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = recordCount == 0
        ? 'Henüz teslimat kaydı yok'
        : '$recordCount kayıt · Toplam ${AppFormat.tonnage(tonnage)}';

    return Material(
      color: const Color(0xFFF3FBF6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB7E4C7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: AppColors.success, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teslimat Kayıtları',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5C6B80),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}

const _trackingTableTitle = 'Gelen Demir Takip Tablosu';

Future<void> showDeliveredTrackingReportSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final report = buildIncomingTrackingReport(
    ref.read(deliveriesProvider),
    imalats: ref.read(surveyProjectProvider).imalats,
  );

  void open(Future<void> Function() action) {
    if (report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Takip tablosunda kayıt yok')),
      );
      return;
    }
    Navigator.pop(context);
    action();
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  _trackingTableTitle,
                  style: AppTypography.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF önizleme'),
                onTap: () => open(() => openTrackingPdfPreview(context, report)),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Excel önizleme'),
                onTap: () => open(
                  () => openTrackingExcelPreview(context, report),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
