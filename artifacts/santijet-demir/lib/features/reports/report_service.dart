import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/reports/report_context.dart';

class ReportService {
  const ReportService();

  static const pdfReportIds = {'pdf', 'stok', 'teslimat', 'sapma', 'aylik'};

  bool isPdfReport(String reportId) => pdfReportIds.contains(reportId);

  ReportValidation validate(String reportId, ReportContext context) {
    if (!isPdfReport(reportId)) {
      return const ReportValidation(isValid: true, missingRequirements: []);
    }

    final missing = <String>[];
    void require(bool condition, String label) {
      if (!condition) missing.add(label);
    }

    require(context.hasActiveProject, 'Aktif proje seçimi');

    switch (reportId) {
      case 'pdf':
        require(context.hasSurveyData, 'Keşif / imalat metraj verisi');
        require(context.hasOrders, 'Sipariş kaydı');
        require(context.hasDeliveries, 'Teslimat kaydı');
        require(context.hasFieldCounts, 'Saha sayım kaydı');
      case 'stok':
        require(context.hasSurveyData, 'Keşif / imalat metraj verisi');
        require(context.hasReconciliationData, 'Mukayese / stok verisi');
        require(context.hasFieldCounts, 'Saha sayım kaydı');
      case 'teslimat':
        require(context.hasOrders, 'Sipariş kaydı');
        require(context.hasDeliveries, 'Teslimat kaydı');
      case 'sapma':
        require(context.hasSurveyData, 'Keşif / imalat metraj verisi');
        require(context.hasFieldCounts, 'Saha sayım kaydı');
        require(context.hasReconciliationData, 'Mukayese / sapma verisi');
      case 'aylik':
        require(context.hasMonthlyActivity, 'Bu aya ait proje aktivitesi');
    }

    return ReportValidation(
      isValid: missing.isEmpty,
      missingRequirements: missing,
    );
  }

  ReportPayload build(String reportId, ReportContext context) {
    return switch (reportId) {
      'pdf' => _buildGeneralSummary(context),
      'stok' => _buildStockReport(context),
      'teslimat' => _buildDeliveryReport(context),
      'sapma' => _buildVarianceReport(context),
      'aylik' => _buildMonthlyReport(context),
      _ => _buildGeneralSummary(context),
    };
  }

  ReportPayload _buildGeneralSummary(ReportContext context) {
    final summary = context.summary;
    return ReportPayload(
      title: 'Genel Özet Raporu',
      headers: const ['Alan', 'Değer'],
      rows: [
        ['Proje', context.projectName],
        ['Keşif Toplam', AppFormat.tonnage(summary.survey)],
        ['Sipariş Toplam', AppFormat.tonnage(summary.ordered)],
        ['Teslim Toplam', AppFormat.tonnage(summary.delivered)],
        ['Planlanan Kullanım', AppFormat.tonnage(summary.plannedUsage)],
        ['Gerçek Kullanım', AppFormat.tonnage(summary.actualUsage)],
        ['Planlanan Stok', AppFormat.tonnage(summary.plannedStock)],
        ['Gerçek Stok', AppFormat.tonnage(summary.fieldCount)],
        ['Fire', AppFormat.tonnage(summary.fire)],
        ['Saha Sayım Kaydı', '${context.fieldCounts.length} adet'],
        ['Sipariş Kaydı', '${context.orders.length} adet'],
        ['Teslimat Kaydı', '${context.deliveries.length} adet'],
      ],
    );
  }

  ReportPayload _buildStockReport(ReportContext context) {
    return ReportPayload(
      title: 'Stok Raporu',
      headers: const ['Çap', 'Planlanan Stok', 'Gerçek Stok', 'Fark'],
      rows: [
        for (final row in context.reconciliationRows)
          [
            'Ø${row.diameter}',
            AppFormat.tonnage(row.expectedStock),
            AppFormat.tonnage(row.counted),
            AppFormat.tonnage(row.counted - row.expectedStock),
          ],
        [
          'TOPLAM',
          AppFormat.tonnage(context.summary.plannedStock),
          AppFormat.tonnage(context.summary.fieldCount),
          AppFormat.tonnage(context.summary.fieldCount - context.summary.plannedStock),
        ],
      ],
    );
  }

  ReportPayload _buildDeliveryReport(ReportContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');
    return ReportPayload(
      title: 'Teslimat Raporu',
      headers: const [
        'Sipariş No',
        'İrsaliye',
        'Firma',
        'Tarih',
        'Ağırlık/ton',
        'Durum',
      ],
      rows: [
        for (final delivery in context.deliveries)
          [
            delivery.orderNo,
            delivery.irsaliyeNo,
            delivery.supplier,
            dateFormat.format(delivery.date),
            AppFormat.tonnage(delivery.tonnage),
            delivery.status.label,
          ],
      ],
    );
  }

  ReportPayload _buildVarianceReport(ReportContext context) {
    return ReportPayload(
      title: 'Sapma Raporu',
      headers: const ['Çap', 'Planlanan Stok', 'Sayım', 'Sapma', 'Sapma %'],
      rows: [
        for (final row in context.reconciliationRows)
          () {
            final variance = row.expectedStock - row.counted;
            return [
              'Ø${row.diameter}',
              AppFormat.tonnage(row.expectedStock),
              AppFormat.tonnage(row.counted),
              AppFormat.tonnage(variance),
              row.expectedStock > 0
                  ? '${((variance / row.expectedStock) * 100).toStringAsFixed(1)}%'
                  : '—',
            ];
          }(),
      ],
    );
  }

  ReportPayload _buildMonthlyReport(ReportContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final monthLabel = DateFormat('MMMM yyyy', 'tr_TR').format(now);

    bool inMonth(DateTime date) =>
        !date.isBefore(monthStart) && date.isBefore(nextMonth);

    final monthOrders =
        context.orders.where((order) => inMonth(order.date)).toList();
    final monthDeliveries =
        context.deliveries.where((delivery) => inMonth(delivery.date)).toList();
    final monthCounts =
        context.fieldCounts.where((count) => inMonth(count.date)).toList();

    final deliveredTonnage =
        monthDeliveries.fold(0.0, (sum, item) => sum + item.tonnage);
    final orderedTonnage =
        monthOrders.fold(0.0, (sum, item) => sum + item.tonnage);

    return ReportPayload(
      title: 'Aylık Rapor — $monthLabel',
      headers: const ['Alan', 'Değer'],
      rows: [
        ['Proje', context.projectName],
        ['Dönem', monthLabel],
        ['Sipariş Adedi', '${monthOrders.length}'],
        ['Sipariş Tonajı', AppFormat.tonnage(orderedTonnage)],
        ['Teslimat Adedi', '${monthDeliveries.length}'],
        ['Teslimat Tonajı', AppFormat.tonnage(deliveredTonnage)],
        ['Saha Sayım Adedi', '${monthCounts.length}'],
        ['Keşif Revizyonu', DateFormat('d MMM yyyy', 'tr_TR').format(context.survey.date)],
        ['Güncel Fire', AppFormat.tonnage(context.summary.fire)],
      ],
    );
  }
}
