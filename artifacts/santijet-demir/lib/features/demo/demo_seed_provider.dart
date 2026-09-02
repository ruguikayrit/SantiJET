import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/field_count/providers/field_count_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

/// Ayarlar → Demo: keşif, sipariş, teslimat, saha sayım ve CAD metraj örneği.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Şantiye';
  static const demoProjectCode = 'DEMO-001';
  static const demoCompanyName = 'Demo İnşaat A.Ş.';
  static const demoSupplier = 'Demo Demir A.Ş.';

  static const _imalatKolonId = 'demo-imalat-kolon';
  static const _imalatKirisId = 'demo-imalat-kiris';
  static const _imalatPerdeId = 'demo-imalat-perde';

  Future<Project> loadAll() async {
    final project = await _ensureProject();
    await _ref.read(projectsControllerProvider).switchProject(project.id);

    await _ref.read(appSettingsProvider.notifier).updateCompany(
          companyName: demoCompanyName,
        );

    final survey = _buildSurvey(project.name);
    await _ref.read(surveyRepositoryProvider).write(project.id, survey);

    final orders = _buildOrders();
    await _ref.read(orderRepositoryProvider).write(project.id, orders);

    final deliveries = _buildDeliveries(orders);
    await _ref.read(deliveryRepositoryProvider).write(project.id, deliveries);

    final counts = _buildFieldCounts(survey, deliveries);
    await _ref.read(fieldCountRepositoryProvider).write(project.id, counts);

    await _writeMetraj(project.id, survey);

    _reloadProviders(project.id);
    return project;
  }

  Future<Project> _ensureProject() async {
    final existing = _ref.read(userProjectsProvider).where(
          (p) => p.name == demoProjectName || p.code == demoProjectCode,
        );
    if (existing.isNotEmpty) return existing.first;

    return _ref.read(projectsControllerProvider).createProject(
          name: demoProjectName,
          location: 'İstanbul · Demo Şantiye',
          code: demoProjectCode,
          progress: 48,
        );
  }

  void _reloadProviders(String projectId) {
    _ref.read(surveyProjectProvider.notifier).reloadForProject(projectId);
    _ref.read(ordersProvider.notifier).loadForProject(projectId);
    _ref.read(deliveriesProvider.notifier).loadForProject(projectId);
    _ref.read(fieldCountsProvider.notifier).loadForProject(projectId);
    _ref.read(savedRebarMetrajProvider.notifier).loadForProject(projectId);
  }

  SurveyProject _buildSurvey(String projectName) {
    final kolon = _imalat(
      id: _imalatKolonId,
      name: 'Kolon',
      progressPercent: 55,
      lines: const [
        DiameterLine(
          diameter: 12,
          planned: 85,
          ordered: 48,
          delivered: 42,
          progressPercent: 55,
        ),
        DiameterLine(
          diameter: 14,
          planned: 62,
          ordered: 34,
          delivered: 30,
          progressPercent: 50,
        ),
        DiameterLine(
          diameter: 16,
          planned: 44,
          ordered: 22,
          delivered: 18,
          progressPercent: 45,
        ),
      ],
    );
    final kiris = _imalat(
      id: _imalatKirisId,
      name: 'Kiriş',
      progressPercent: 42,
      lines: const [
        DiameterLine(
          diameter: 12,
          planned: 52,
          ordered: 28,
          delivered: 24,
          progressPercent: 40,
        ),
        DiameterLine(
          diameter: 14,
          planned: 70,
          ordered: 36,
          delivered: 30,
          progressPercent: 45,
        ),
        DiameterLine(
          diameter: 20,
          planned: 38,
          ordered: 16,
          delivered: 12,
          progressPercent: 35,
        ),
      ],
    );
    final perde = _imalat(
      id: _imalatPerdeId,
      name: 'Perde',
      progressPercent: 58,
      lines: const [
        DiameterLine(
          diameter: 10,
          planned: 40,
          ordered: 22,
          delivered: 20,
          progressPercent: 60,
        ),
        DiameterLine(
          diameter: 12,
          planned: 58,
          ordered: 32,
          delivered: 28,
          progressPercent: 55,
        ),
        DiameterLine(
          diameter: 16,
          planned: 46,
          ordered: 20,
          delivered: 14,
          progressPercent: 50,
        ),
      ],
    );

    return SurveyProject(
      projectName: projectName,
      date: DateTime.now(),
      revision: 'Rev.Demo',
      imalats: [kolon, kiris, perde],
    );
  }

  SurveyImalat _imalat({
    required String id,
    required String name,
    required double progressPercent,
    required List<DiameterLine> lines,
  }) {
    final planned = lines.fold<double>(0, (sum, line) => sum + line.planned);
    final ordered = lines.fold<double>(0, (sum, line) => sum + line.ordered);
    final delivered =
        lines.fold<double>(0, (sum, line) => sum + line.delivered);
    return SurveyImalat(
      id: id,
      name: name,
      totalTonnage: planned,
      progressPercent: progressPercent,
      diameters: lines.map((line) => line.diameter).toList(),
      diameterLines: lines,
      planned: planned,
      ordered: ordered,
      delivered: delivered,
      pending: (ordered - delivered).clamp(0, double.infinity),
    );
  }

  List<OrderItem> _buildOrders() {
    final now = DateTime.now();
    return [
      OrderItem(
        id: 'demo-order-completed',
        orderNo: 'SP-${now.year}-D001',
        date: now.subtract(const Duration(days: 12)),
        imalatTypes: const ['Kolon'],
        imalatTonnages: const {'Kolon': 72},
        tonnage: 72,
        status: OrderStatus.completed,
        supplier: demoSupplier,
        approvals: const OrderApprovals(
          purchasing: true,
          projectManager: true,
        ),
      ),
      OrderItem(
        id: 'demo-order-transit',
        orderNo: 'SP-${now.year}-D002',
        date: now.subtract(const Duration(days: 4)),
        imalatTypes: const ['Kiriş'],
        imalatTonnages: const {'Kiriş': 48},
        tonnage: 48,
        status: OrderStatus.inTransit,
        supplier: demoSupplier,
        approvals: const OrderApprovals(
          purchasing: true,
          projectManager: true,
        ),
      ),
      OrderItem(
        id: 'demo-order-submitted',
        orderNo: 'SP-${now.year}-D003',
        date: now.subtract(const Duration(days: 1)),
        imalatTypes: const ['Perde'],
        imalatTonnages: const {'Perde': 40},
        tonnage: 40,
        status: OrderStatus.submitted,
        supplier: demoSupplier,
        approvals: const OrderApprovals(
          purchasing: true,
          projectManager: true,
        ),
      ),
    ];
  }

  List<DeliveryItem> _buildDeliveries(List<OrderItem> orders) {
    final completed = orders.firstWhere((o) => o.id == 'demo-order-completed');
    final transit = orders.firstWhere((o) => o.id == 'demo-order-transit');
    final now = DateTime.now();

    final kolonLines = const [
      DeliveryDiameterLine(diameter: 12, ordered: 48, delivered: 42),
      DeliveryDiameterLine(diameter: 14, ordered: 34, delivered: 30),
      DeliveryDiameterLine(diameter: 16, ordered: 22, delivered: 18),
    ];
    final kolonTonnage =
        kolonLines.fold<double>(0, (sum, line) => sum + line.delivered);

    final kirisLines = const [
      DeliveryDiameterLine(diameter: 12, ordered: 28, delivered: 24),
      DeliveryDiameterLine(diameter: 14, ordered: 36, delivered: 30),
      DeliveryDiameterLine(diameter: 20, ordered: 16, delivered: 12),
    ];
    final kirisTonnage =
        kirisLines.fold<double>(0, (sum, line) => sum + line.delivered);

    return [
      DeliveryItem(
        id: 'demo-delivery-1',
        orderId: completed.id,
        orderNo: completed.orderNo,
        irsaliyeNo: 'IRS-DEMO-1001',
        date: now.subtract(const Duration(days: 10)),
        supplier: demoSupplier,
        tonnage: kolonTonnage,
        fulfillmentPercent: kolonTonnage / completed.tonnage * 100,
        status: DeliveryStatus.partial,
        diameterLines: kolonLines,
        plateNo: '34 DEMO 01',
      ),
      DeliveryItem(
        id: 'demo-delivery-2',
        orderId: transit.id,
        orderNo: transit.orderNo,
        irsaliyeNo: 'IRS-DEMO-1002',
        date: now.subtract(const Duration(days: 2)),
        supplier: demoSupplier,
        tonnage: kirisTonnage,
        fulfillmentPercent: kirisTonnage / transit.tonnage * 100,
        status: DeliveryStatus.partial,
        diameterLines: kirisLines,
        plateNo: '34 DEMO 02',
      ),
    ];
  }

  List<FieldCountRecord> _buildFieldCounts(
    SurveyProject survey,
    List<DeliveryItem> deliveries,
  ) {
    final deliveredByDiameter = <int, double>{};
    for (final delivery in deliveries) {
      for (final line in delivery.diameterLines) {
        deliveredByDiameter[line.diameter] =
            (deliveredByDiameter[line.diameter] ?? 0) + line.delivered;
      }
    }

    final plannedUsageByDiameter = <int, double>{};
    for (final imalat in survey.imalats) {
      for (final line in imalat.diameterLines) {
        plannedUsageByDiameter[line.diameter] =
            (plannedUsageByDiameter[line.diameter] ?? 0) + line.expectedUsage;
      }
    }

    final diameters = {
      ...deliveredByDiameter.keys,
      ...plannedUsageByDiameter.keys,
    }.toList()
      ..sort();

    final lines = <FieldCountLineRecord>[];
    for (final diameter in diameters) {
      final delivered = deliveredByDiameter[diameter] ?? 0;
      final plannedUsage = plannedUsageByDiameter[diameter] ?? 0;
      final expectedStock =
          (delivered - plannedUsage).clamp(0, double.infinity).toDouble();
      // Sayım: beklenenin biraz altında → mukayesede sapma görünsün.
      final actual =
          (expectedStock * 0.92).clamp(0.0, double.infinity).toDouble();
      lines.add(
        FieldCountLineRecord(
          diameter: diameter,
          delivered: delivered,
          plannedUsage: plannedUsage,
          expectedStock: expectedStock,
          actual: actual,
        ),
      );
    }

    final expected =
        lines.fold<double>(0, (sum, line) => sum + line.expectedStock);
    final actual = lines.fold<double>(0, (sum, line) => sum + line.actual);

    return [
      FieldCountRecord(
        id: 'demo-count-1',
        title: 'A Blok · Bodrum',
        date: DateTime.now().subtract(const Duration(days: 1)),
        personnel: 'Demo Saha Ekibi',
        region: 'A Blok · Bodrum',
        expected: expected,
        actual: actual,
        status: 'warning',
        lines: lines,
        varianceCauses: const ['Kesim firesi', 'Montaj kaybı'],
      ),
    ];
  }

  Future<void> _writeMetraj(String projectId, SurveyProject survey) async {
    final kolon = survey.imalats.firstWhere((i) => i.id == _imalatKolonId);
    final details = <RebarMetrajTextDetail>[
      _pieceDetail(
        source: 'Ø12 L=6.00 n=40',
        diameter: 12,
        lengthM: 6.0,
        quantity: 40,
        elementCode: 'K01',
        elementTypeCode: 'K',
      ),
      _pieceDetail(
        source: 'Ø12 L=5.80 n=36',
        diameter: 12,
        lengthM: 5.8,
        quantity: 36,
        elementCode: 'K01',
        elementTypeCode: 'K',
      ),
      _pieceDetail(
        source: 'Ø14 L=7.20 n=28',
        diameter: 14,
        lengthM: 7.2,
        quantity: 28,
        elementCode: 'K02',
        elementTypeCode: 'K',
      ),
      _pieceDetail(
        source: 'Ø14 L=7.00 n=24',
        diameter: 14,
        lengthM: 7.0,
        quantity: 24,
        elementCode: 'K02',
        elementTypeCode: 'K',
      ),
      _pieceDetail(
        source: 'Ø16 L=8.00 n=18',
        diameter: 16,
        lengthM: 8.0,
        quantity: 18,
        elementCode: 'K03',
        elementTypeCode: 'K',
      ),
      _pieceDetail(
        source: 'Ø16 L=7.85 n=16',
        diameter: 16,
        lengthM: 7.85,
        quantity: 16,
        elementCode: 'K03',
        elementTypeCode: 'K',
      ),
    ];

    final linesByDiameter = <int, RebarMetrajLine>{};
    for (final detail in details) {
      final diameter = detail.diameter!;
      final lengthM = detail.lengthM!;
      final existing = linesByDiameter[diameter];
      final addLength = lengthM * detail.quantity;
      final addWeight = detail.weightKg;
      if (existing == null) {
        linesByDiameter[diameter] = RebarMetrajLine(
          diameter: diameter,
          totalLengthM: addLength,
          weightKg: addWeight,
          barCount: detail.quantity,
          layerName: 'DEMO',
        );
      } else {
        linesByDiameter[diameter] = RebarMetrajLine(
          diameter: diameter,
          totalLengthM: existing.totalLengthM + addLength,
          weightKg: existing.weightKg + addWeight,
          barCount: existing.barCount + detail.quantity,
          layerName: 'DEMO',
        );
      }
    }

    final result = RebarMetrajResult(
      fileName: 'demo_kolon.dwg',
      sourceFormat: 'DWG',
      parsedAt: DateTime.now(),
      lines: linesByDiameter.values.toList(),
      textDetails: details,
      skippedEntityCount: 0,
      warnings: const ['[DEMO] Örnek CAD metraj kaydı'],
    );

    final repo = _ref.read(rebarMetrajRepositoryProvider);
    await _ref.read(projectDataRepositoryProvider).writeDomain(
      projectId,
      'rebar_metraj',
      {'records': <Map<String, dynamic>>[]},
    );

    await repo.saveResult(
      projectId: projectId,
      result: result,
      title: 'Demo · Kolon CAD Metraj',
      surveyImalatId: kolon.id,
      surveyImalatName: kolon.name,
    );

    await _ref.read(projectDataRepositoryProvider).markSeeded(projectId);
  }

  RebarMetrajTextDetail _pieceDetail({
    required String source,
    required int diameter,
    required double lengthM,
    required int quantity,
    required String elementCode,
    required String elementTypeCode,
  }) {
    final unitKg = RebarWeightCalculator.weightKg(
      diameterMm: diameter,
      lengthM: lengthM,
    );
    return RebarMetrajTextDetail(
      entityType: 'TEXT',
      sourceText: source,
      included: true,
      diameter: diameter,
      lengthM: lengthM,
      quantity: quantity,
      weightKg: unitKg * quantity,
      elementCode: elementCode,
      elementTypeCode: elementTypeCode,
      benzerCount: 1,
      unitQuantity: quantity,
      rebarRole: RebarLabelRole.longitudinal,
    );
  }
}

final demoSeedControllerProvider = Provider<DemoSeedController>((ref) {
  return DemoSeedController(ref);
});
