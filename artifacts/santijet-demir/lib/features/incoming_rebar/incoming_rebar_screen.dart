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
  bool _asPercent = false;

  @override
  Widget build(BuildContext context) {
    final hasActiveProject = ref.watch(activeProjectProvider) != null;
    final project = ref.watch(activeProjectProvider);
    final period = ref.watch(incomingRebarPeriodProvider);
    final deliveries = filterDeliveriesByPeriod(
      ref.watch(deliveriesProvider),
      period,
    );
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  _FilterRow(
                    projectName: project?.name ?? 'Şantiye',
                    periodLabel: switch (period) {
                      IncomingRebarPeriod.all => 'Tümü',
                      IncomingRebarPeriod.month => 'Bu Ay',
                      IncomingRebarPeriod.year => 'Bu Yıl',
                    },
                    onProject: () => _pickProject(context, ref),
                    onPeriod: () => _pickPeriod(context, ref, period),
                  ),
                  const SizedBox(height: 10),
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
                          'Çap Bazında Durum',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C2430),
                          ),
                        ),
                      ),
                      _UnitSwitch(
                        asPercent: _asPercent,
                        onChanged: (value) => setState(() => _asPercent = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DeliveredDiameterTable(
                    rows: diameterRows,
                    asPercent: _asPercent,
                  ),
                  const SizedBox(height: 12),
                  _DeliveryRecordsShortcut(
                    recordCount: deliveries.length,
                    tonnage: recordedTonnage,
                    onTap: () => context.push(AppRoutes.deliveryList),
                  ),
                ],
              ),
            ),
          if (hasActiveProject && canCreate)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _DeliveryActions(),
            ),
        ],
      ),
    );
  }

  Future<void> _pickProject(BuildContext context, WidgetRef ref) async {
    final projects = ref.read(userProjectsProvider);
    final activeId = ref.read(activeProjectIdProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final item in projects)
                ListTile(
                  title: Text(item.name),
                  trailing: item.id == activeId
                      ? const Icon(Icons.check, color: AppColors.electricBlueLight)
                      : null,
                  onTap: () async {
                    await ref.read(projectsControllerProvider).switchProject(item.id);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPeriod(
    BuildContext context,
    WidgetRef ref,
    IncomingRebarPeriod current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in IncomingRebarPeriod.values)
                ListTile(
                  title: Text(switch (item) {
                    IncomingRebarPeriod.all => 'Tümü',
                    IncomingRebarPeriod.month => 'Bu Ay',
                    IncomingRebarPeriod.year => 'Bu Yıl',
                  }),
                  trailing: item == current
                      ? const Icon(Icons.check, color: AppColors.electricBlueLight)
                      : null,
                  onTap: () {
                    ref.read(incomingRebarPeriodProvider.notifier).state = item;
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.projectName,
    required this.periodLabel,
    required this.onProject,
    required this.onPeriod,
  });

  final String projectName;
  final String periodLabel;
  final VoidCallback onProject;
  final VoidCallback onPeriod;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _FilterChip(
            icon: Icons.apartment_outlined,
            label: projectName,
            onTap: onProject,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _FilterChip(
            icon: Icons.calendar_today_outlined,
            label: periodLabel,
            onTap: onPeriod,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.electricBlueLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2430),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF8B95A5)),
            ],
          ),
        ),
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

class _UnitSwitch extends StatelessWidget {
  const _UnitSwitch({required this.asPercent, required this.onChanged});

  final bool asPercent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('Miktar', !asPercent, () => onChanged(false)),
          _seg('Yüzde', asPercent, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.electricBlueLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF5C6B80),
            height: 1,
          ),
        ),
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

class _DeliveryActions extends ConsumerWidget {
  const _DeliveryActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openForm() => context.push(AppRoutes.selectInTransitOrder);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: openForm,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.electricBlueLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Yeni Teslimat Kaydı'),
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
