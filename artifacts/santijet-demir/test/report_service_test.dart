import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/field_count/field_count_calculator.dart';
import 'package:santijet_demir/features/reports/report_context.dart';
import 'package:santijet_demir/features/reports/report_service.dart';

void main() {
  const service = ReportService();

  ReportContext emptyContext({bool withProject = true}) {
    return ReportContext(
      projectName: withProject ? 'Test Proje' : 'Proje seçilmedi',
      hasActiveProject: withProject,
      survey: SurveyProject(
        projectName: 'Test Proje',
        date: DateTime(2026, 1, 1),
        revision: 'A',
        imalats: const [],
      ),
      orders: const [],
      deliveries: const [],
      fieldCounts: const [],
      reconciliationRows: const [],
      summary: computeReconciliationTotals(const []),
    );
  }

  test('pdf raporu eksik verilerde uyarı listesi döner', () {
    final validation = service.validate('pdf', emptyContext());

    expect(validation.isValid, isFalse);
    expect(validation.missingRequirements, contains('Keşif / imalat metraj verisi'));
    expect(validation.missingRequirements, contains('Sipariş kaydı'));
    expect(validation.missingRequirements, contains('Teslimat kaydı'));
    expect(validation.missingRequirements, contains('Saha sayım kaydı'));
  });

  test('teslimat raporu sipariş ve teslimat ister', () {
    final validation = service.validate('teslimat', emptyContext());

    expect(validation.isValid, isFalse);
    expect(validation.missingRequirements, contains('Sipariş kaydı'));
    expect(validation.missingRequirements, contains('Teslimat kaydı'));
  });

  test('veriler tamamlandığında pdf raporu geçerli olur', () {
    final now = DateTime.now();
    final context = ReportContext(
      projectName: 'Test Proje',
      hasActiveProject: true,
      survey: SurveyProject(
        projectName: 'Test Proje',
        date: now,
        revision: 'A',
        imalats: const [
          SurveyImalat(
            id: '1',
            name: 'Temel',
            totalTonnage: 100,
            progressPercent: 50,
            diameters: [16],
            diameterLines: [],
            planned: 100,
            ordered: 80,
            delivered: 60,
            pending: 20,
          ),
        ],
      ),
      orders: [
        OrderItem(
          id: 'o1',
          orderNo: 'SP-1',
          date: now,
          supplier: 'ABC',
          status: OrderStatus.completed,
          imalatTypes: const ['Temel'],
          tonnage: 80,
        ),
      ],
      deliveries: [
        DeliveryItem(
          id: 'd1',
          orderId: 'o1',
          orderNo: 'SP-1',
          irsaliyeNo: 'IR-1',
          date: now,
          supplier: 'ABC',
          tonnage: 60,
          fulfillmentPercent: 100,
          status: DeliveryStatus.received,
          diameterLines: const [],
        ),
      ],
      fieldCounts: [
        FieldCountRecord(
          id: 'c1',
          title: 'Sayım',
          date: now,
          personnel: 'Uğur',
          region: 'A Blok',
          expected: 10,
          actual: 9,
          status: 'completed',
        ),
      ],
      reconciliationRows: const [
        ReconciliationRow(
          diameter: 16,
          survey: 100,
          ordered: 80,
          delivered: 60,
          plannedUsage: 50,
          expectedStock: 10,
          counted: 9,
          used: 51,
        ),
      ],
      summary: computeReconciliationTotals(const [
        ReconciliationRow(
          diameter: 16,
          survey: 100,
          ordered: 80,
          delivered: 60,
          plannedUsage: 50,
          expectedStock: 10,
          counted: 9,
          used: 51,
        ),
      ]),
    );

    final validation = service.validate('pdf', context);
    expect(validation.isValid, isTrue);

    final payload = service.build('pdf', context);
    expect(payload.title, 'Genel Özet Raporu');
    expect(payload.rows.first, ['Proje', 'Test Proje']);
  });
}
