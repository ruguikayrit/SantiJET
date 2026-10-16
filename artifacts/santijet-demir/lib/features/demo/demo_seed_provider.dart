import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/project_data_repository.dart';
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
import 'package:santijet_demir/features/survey/imalat_block_template.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

/// Ayarlar / misafir girişi: Demo Şantiye verisini siler ve tutarlı örnek set kurar.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Şantiye';
  static const demoProjectCode = 'DEMO-2026';
  static const _legacyDemoCodes = {'DEMO-001', 'DEMO-2026'};
  static const demoCompanyName = 'Demo İnşaat A.Ş.';
  static const demoSupplier = 'Kardemir Demir San.';

  static const _kolonId = 'demo-kolon';
  static const _kirisId = 'demo-kiris';
  static const _perdeId = 'demo-perde';
  static const _temelId = 'demo-temel';
  static const _dosemeId = 'demo-doseme';
  static const _merdivenId = 'demo-merdiven';

  /// Mevcut demo projesinin tüm modül verisini siler, sonra yeni senaryoyu yazar.
  Future<Project> loadAll() async {
    final project = await _ensureDemoProject();
    await _wipeProjectData(project.id);

    await _ref.read(appSettingsProvider.notifier).updateCompany(
          companyName: demoCompanyName,
        );

    final survey = _buildSurvey(project.name);
    await _ref.read(surveyRepositoryProvider).write(project.id, survey);

    final orders = _buildOrders();
    await _ref.read(orderRepositoryProvider).write(project.id, orders);

    final deliveries = _buildDeliveries(orders);
    await _ref.read(deliveryRepositoryProvider).write(project.id, deliveries);

    final counts = _buildFieldCounts();
    await _ref.read(fieldCountRepositoryProvider).write(project.id, counts);

    await _writeMetraj(project.id);

    await _ref.read(projectsControllerProvider).switchProject(project.id);
    _reloadProviders(project.id);
    return project;
  }

  Future<Project> _ensureDemoProject() async {
    final matches = _ref.read(userProjectsProvider).where(
          (p) =>
              p.name == demoProjectName ||
              (p.code != null && _legacyDemoCodes.contains(p.code)),
        );
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 150));
    final endDate = startDate.add(const Duration(days: 365));

    if (matches.isNotEmpty) {
      final existing = matches.first;
      if (existing.startDate != null && existing.endDate != null) {
        return existing;
      }
      final dated = existing.copyWith(startDate: startDate, endDate: endDate);
      try {
        await _ref.read(projectsControllerProvider).updateProject(dated);
        return dated;
      } catch (_) {
        return existing;
      }
    }

    return _ref.read(projectsControllerProvider).createProject(
          name: demoProjectName,
          location: 'İstanbul · Kartal · 4 Blok Konut',
          startDate: startDate,
          endDate: endDate,
          code: demoProjectCode,
          progress: 39,
        );
  }

  Future<void> _wipeProjectData(String projectId) async {
    final box = _ref.read(projectsBoxProvider);
    for (final domain in ProjectDataRepository.projectDomains) {
      await box.delete('pdata:$projectId:$domain');
    }
    await box.delete('pdata:$projectId:seeded');
  }

  void _reloadProviders(String projectId) {
    _ref.read(surveyProjectProvider.notifier).reloadForProject(projectId);
    _ref.read(ordersProvider.notifier).loadForProject(projectId);
    _ref.read(deliveriesProvider.notifier).loadForProject(projectId);
    _ref.read(fieldCountsProvider.notifier).loadForProject(projectId);
    _ref.read(savedRebarMetrajProvider.notifier).loadForProject(projectId);
  }

  SurveyProject _buildSurvey(String projectName) {
    final now = DateTime.now();
    // İlerleme, teslim edilen demiri aşmaz. Döşeme siparişi iptal; merdiven henüz gelmedi.
    final imalats = [
      _imalatWithBlocks(
        id: _temelId,
        name: 'Temel',
        progressPercent: 57.5,
        lines: const [
          DiameterLine(diameter: 12, planned: 48, ordered: 40, delivered: 40, progressPercent: 62),
          DiameterLine(diameter: 14, planned: 36, ordered: 28, delivered: 28, progressPercent: 58),
          DiameterLine(diameter: 16, planned: 32, ordered: 22, delivered: 22, progressPercent: 56),
          DiameterLine(diameter: 20, planned: 24, ordered: 18, delivered: 18, progressPercent: 50),
        ],
      ),
      _imalatWithBlocks(
        id: _kolonId,
        name: 'Kolon',
        progressPercent: 39.8,
        lines: const [
          DiameterLine(diameter: 12, planned: 46, ordered: 28, delivered: 28, progressPercent: 42),
          DiameterLine(diameter: 14, planned: 36, ordered: 22, delivered: 22, progressPercent: 40),
          DiameterLine(diameter: 16, planned: 28, ordered: 16, delivered: 16, progressPercent: 36),
        ],
      ),
      _imalatWithBlocks(
        id: _kirisId,
        name: 'Kiriş',
        progressPercent: 30.6,
        lines: const [
          DiameterLine(diameter: 12, planned: 24, ordered: 18, delivered: 12, progressPercent: 34),
          DiameterLine(diameter: 14, planned: 32, ordered: 16, delivered: 10, progressPercent: 30),
          DiameterLine(diameter: 20, planned: 24, ordered: 12, delivered: 8, progressPercent: 28),
        ],
      ),
      _imalatWithBlocks(
        id: _perdeId,
        name: 'Perde',
        progressPercent: 36,
        lines: const [
          DiameterLine(diameter: 10, planned: 18, ordered: 16, delivered: 14, progressPercent: 40),
          DiameterLine(diameter: 12, planned: 24, ordered: 18, delivered: 16, progressPercent: 36),
          DiameterLine(diameter: 16, planned: 18, ordered: 10, delivered: 8, progressPercent: 32),
        ],
      ),
      _imalatWithBlocks(
        id: _dosemeId,
        name: 'Döşeme',
        progressPercent: 0,
        lines: const [
          DiameterLine(diameter: 10, planned: 12, ordered: 0, delivered: 0, progressPercent: 0),
          DiameterLine(diameter: 12, planned: 10, ordered: 0, delivered: 0, progressPercent: 0),
          DiameterLine(diameter: 14, planned: 8, ordered: 0, delivered: 0, progressPercent: 0),
        ],
      ),
      _imalatWithBlocks(
        id: _merdivenId,
        name: 'Merdiven',
        progressPercent: 0,
        lines: const [
          DiameterLine(diameter: 10, planned: 16, ordered: 8, delivered: 0, progressPercent: 0),
          DiameterLine(diameter: 12, planned: 14, ordered: 6, delivered: 0, progressPercent: 0),
          DiameterLine(diameter: 14, planned: 10, ordered: 4, delivered: 0, progressPercent: 0),
        ],
      ),
    ];

    return SurveyProject(
      projectName: projectName,
      date: now,
      revision: 'Rev.2026.03',
      imalats: imalats,
    );
  }

  SurveyImalat _imalatWithBlocks({
    required String id,
    required String name,
    required double progressPercent,
    required List<DiameterLine> lines,
  }) {
    final base = _imalatSummary(
      id: id,
      name: name,
      progressPercent: progressPercent,
      lines: lines,
    );
    final blocks = ImalatBlockTemplate.build(base);
    final patchedBlocks = [
      for (final block in blocks)
        block.copyWith(
          items: [
            for (final item in block.items)
              item.copyWith(progressPercent: progressPercent),
          ],
        ),
    ];
    return base.copyWith(blocks: patchedBlocks);
  }

  SurveyImalat _imalatSummary({
    required String id,
    required String name,
    required double progressPercent,
    required List<DiameterLine> lines,
  }) {
    final planned = lines.fold<double>(0, (sum, line) => sum + line.planned);
    final ordered = lines.fold<double>(0, (sum, line) => sum + line.ordered);
    final delivered = lines.fold<double>(0, (sum, line) => sum + line.delivered);
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
    final year = now.year;
    return [
      OrderItem(
        id: 'demo-order-001',
        orderNo: 'SP-$year-0001',
        date: now.subtract(const Duration(days: 40)),
        imalatTypes: const ['Temel'],
        imalatTonnages: const {'Temel': 108},
        tonnage: 108,
        status: OrderStatus.completed,
        supplier: demoSupplier,
        diameterAmounts: const {12: 40, 14: 28, 16: 22, 20: 18},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
      OrderItem(
        id: 'demo-order-002',
        orderNo: 'SP-$year-0002',
        date: now.subtract(const Duration(days: 21)),
        imalatTypes: const ['Kolon'],
        imalatTonnages: const {'Kolon': 66},
        tonnage: 66,
        status: OrderStatus.completed,
        supplier: demoSupplier,
        diameterAmounts: const {12: 28, 14: 22, 16: 16},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
      OrderItem(
        id: 'demo-order-003',
        orderNo: 'SP-$year-0003',
        date: now.subtract(const Duration(days: 9)),
        imalatTypes: const ['Kiriş'],
        imalatTonnages: const {'Kiriş': 46},
        tonnage: 46,
        status: OrderStatus.inTransit,
        supplier: demoSupplier,
        diameterAmounts: const {12: 18, 14: 16, 20: 12},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
      OrderItem(
        id: 'demo-order-004',
        orderNo: 'SP-$year-0004',
        date: now.subtract(const Duration(days: 6)),
        imalatTypes: const ['Perde'],
        imalatTonnages: const {'Perde': 44},
        tonnage: 44,
        status: OrderStatus.inTransit,
        supplier: demoSupplier,
        diameterAmounts: const {10: 16, 12: 18, 16: 10},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
      OrderItem(
        id: 'demo-order-005',
        orderNo: 'SP-$year-0005',
        date: now.subtract(const Duration(days: 20)),
        imalatTypes: const ['Döşeme'],
        imalatTonnages: const {'Döşeme': 30},
        tonnage: 30,
        status: OrderStatus.cancelled,
        supplier: demoSupplier,
        diameterAmounts: const {10: 8, 12: 12, 14: 10},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
        cancellation: OrderCancellation(
          cancelledByName: 'Demo Proje Müdürü',
          cancellationReason: 'İmalat takvimi revizyonu — döşeme siparişi iptal.',
          cancelledAt: now.subtract(const Duration(days: 18)),
        ),
      ),
      OrderItem(
        id: 'demo-order-006',
        orderNo: 'SP-$year-0006',
        date: now.subtract(const Duration(days: 2)),
        imalatTypes: const ['Merdiven'],
        imalatTonnages: const {'Merdiven': 18},
        tonnage: 18,
        status: OrderStatus.submitted,
        supplier: demoSupplier,
        diameterAmounts: const {10: 8, 12: 6, 14: 4},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
    ];
  }

  List<DeliveryItem> _buildDeliveries(List<OrderItem> orders) {
    final temel = orders.firstWhere((o) => o.id == 'demo-order-001');
    final kolon = orders.firstWhere((o) => o.id == 'demo-order-002');
    final kiris = orders.firstWhere((o) => o.id == 'demo-order-003');
    final perde = orders.firstWhere((o) => o.id == 'demo-order-004');
    final now = DateTime.now();

    const temelLines = [
      DeliveryDiameterLine(diameter: 12, ordered: 40, delivered: 40),
      DeliveryDiameterLine(diameter: 14, ordered: 28, delivered: 28),
      DeliveryDiameterLine(diameter: 16, ordered: 22, delivered: 22),
      DeliveryDiameterLine(diameter: 20, ordered: 18, delivered: 18),
    ];
    const kolonLines = [
      DeliveryDiameterLine(diameter: 12, ordered: 28, delivered: 28),
      DeliveryDiameterLine(diameter: 14, ordered: 22, delivered: 22),
      DeliveryDiameterLine(diameter: 16, ordered: 16, delivered: 16),
    ];
    const kirisLines = [
      DeliveryDiameterLine(diameter: 12, ordered: 18, delivered: 12),
      DeliveryDiameterLine(diameter: 14, ordered: 16, delivered: 10),
      DeliveryDiameterLine(diameter: 20, ordered: 12, delivered: 8),
    ];
    const perdeLines = [
      DeliveryDiameterLine(diameter: 10, ordered: 16, delivered: 14),
      DeliveryDiameterLine(diameter: 12, ordered: 18, delivered: 16),
      DeliveryDiameterLine(diameter: 16, ordered: 10, delivered: 8),
    ];

    double deliveredOf(List<DeliveryDiameterLine> lines) =>
        lines.fold<double>(0, (sum, line) => sum + line.delivered);

    final temelDelivered = deliveredOf(temelLines);
    final kolonDelivered = deliveredOf(kolonLines);
    final kirisDelivered = deliveredOf(kirisLines);
    final perdeDelivered = deliveredOf(perdeLines);

    return [
      DeliveryItem(
        id: 'demo-delivery-001',
        orderId: temel.id,
        orderNo: temel.orderNo,
        irsaliyeNo: 'IRS-2026-0108',
        date: now.subtract(const Duration(days: 28)),
        supplier: demoSupplier,
        tonnage: temelDelivered,
        fulfillmentPercent: temelDelivered / temel.tonnage * 100,
        status: DeliveryStatus.received,
        diameterLines: temelLines,
        plateNo: '34 TM 1108',
      ),
      DeliveryItem(
        id: 'demo-delivery-002',
        orderId: kolon.id,
        orderNo: kolon.orderNo,
        irsaliyeNo: 'IRS-2026-0142',
        date: now.subtract(const Duration(days: 12)),
        supplier: demoSupplier,
        tonnage: kolonDelivered,
        fulfillmentPercent: kolonDelivered / kolon.tonnage * 100,
        status: DeliveryStatus.received,
        diameterLines: kolonLines,
        plateNo: '34 DK 4821',
      ),
      DeliveryItem(
        id: 'demo-delivery-003',
        orderId: kiris.id,
        orderNo: kiris.orderNo,
        irsaliyeNo: 'IRS-2026-0198',
        date: now.subtract(const Duration(days: 4)),
        supplier: demoSupplier,
        tonnage: kirisDelivered,
        fulfillmentPercent: kirisDelivered / kiris.tonnage * 100,
        status: DeliveryStatus.partial,
        diameterLines: kirisLines,
        plateNo: '34 FN 9033',
      ),
      DeliveryItem(
        id: 'demo-delivery-004',
        orderId: perde.id,
        orderNo: perde.orderNo,
        irsaliyeNo: 'IRS-2026-0214',
        date: now.subtract(const Duration(days: 2)),
        supplier: demoSupplier,
        tonnage: perdeDelivered,
        fulfillmentPercent: perdeDelivered / perde.tonnage * 100,
        status: DeliveryStatus.partial,
        diameterLines: perdeLines,
        plateNo: '34 PR 2210',
      ),
    ];
  }

  List<FieldCountRecord> _buildFieldCounts() {
    final now = DateTime.now();
    return [
      FieldCountRecord(
        id: 'demo-count-latest',
        title: 'A Blok · Zemin depo',
        date: now.subtract(const Duration(hours: 5)),
        personnel: 'Mehmet Yılmaz',
        region: 'A Blok · Zemin depo',
        expected: 71.56,
        actual: 62.8,
        status: 'completed',
        note: 'Sabah sayımı — yağmur sonrası nemli zemin.',
        lines: const [
          FieldCountLineRecord(
            diameter: 10,
            delivered: 14,
            plannedUsage: 7.2,
            expectedStock: 6.8,
            actual: 5.2,
          ),
          FieldCountLineRecord(
            diameter: 12,
            delivered: 96,
            plannedUsage: 65.88,
            expectedStock: 30.12,
            actual: 27,
          ),
          FieldCountLineRecord(
            diameter: 14,
            delivered: 60,
            plannedUsage: 44.88,
            expectedStock: 15.12,
            actual: 13.6,
          ),
          FieldCountLineRecord(
            diameter: 16,
            delivered: 46,
            plannedUsage: 33.76,
            expectedStock: 12.24,
            actual: 10.8,
          ),
          FieldCountLineRecord(
            diameter: 20,
            delivered: 26,
            plannedUsage: 18.72,
            expectedStock: 7.28,
            actual: 6.2,
          ),
        ],
      ),
      FieldCountRecord(
        id: 'demo-count-prev',
        title: 'C Blok · Perde hattı',
        date: now.subtract(const Duration(days: 3)),
        personnel: 'Ayşe Kaya',
        region: 'C Blok · Perde hattı',
        expected: 96,
        actual: 96,
        status: 'completed',
        note: 'Perde öncesi stok kontrolü.',
        lines: const [
          FieldCountLineRecord(
            diameter: 10,
            delivered: 14,
            plannedUsage: 7.2,
            expectedStock: 6.8,
            actual: 8,
          ),
          FieldCountLineRecord(
            diameter: 12,
            delivered: 96,
            plannedUsage: 65.88,
            expectedStock: 30.12,
            actual: 40,
          ),
          FieldCountLineRecord(
            diameter: 14,
            delivered: 60,
            plannedUsage: 44.88,
            expectedStock: 15.12,
            actual: 22,
          ),
          FieldCountLineRecord(
            diameter: 16,
            delivered: 46,
            plannedUsage: 33.76,
            expectedStock: 12.24,
            actual: 16,
          ),
          FieldCountLineRecord(
            diameter: 20,
            delivered: 26,
            plannedUsage: 18.72,
            expectedStock: 7.28,
            actual: 10,
          ),
        ],
      ),
    ];
  }

  Future<void> _writeMetraj(String projectId) async {
    final details = <RebarMetrajTextDetail>[
      _pieceDetail(
        source: 'Ø12 L=5.40 n=48',
        diameter: 12,
        lengthM: 5.4,
        quantity: 48,
        elementCode: 'K-A1',
        elementTypeCode: 'K',
      ),
      _pieceDetail(
        source: 'Ø14 L=6.80 n=32',
        diameter: 14,
        lengthM: 6.8,
        quantity: 32,
        elementCode: 'K-A2',
        elementTypeCode: 'K',
      ),
      _pieceDetail(
        source: 'Ø16 L=7.50 n=20',
        diameter: 16,
        lengthM: 7.5,
        quantity: 20,
        elementCode: 'K-B1',
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
          layerName: 'KOLON',
        );
      } else {
        linesByDiameter[diameter] = RebarMetrajLine(
          diameter: diameter,
          totalLengthM: existing.totalLengthM + addLength,
          weightKg: existing.weightKg + addWeight,
          barCount: existing.barCount + detail.quantity,
          layerName: 'KOLON',
        );
      }
    }

    final result = RebarMetrajResult(
      fileName: 'demo_kolon_a_blok.dwg',
      sourceFormat: 'DWG',
      parsedAt: DateTime.now(),
      lines: linesByDiameter.values.toList(),
      textDetails: details,
      skippedEntityCount: 0,
      warnings: const ['Demo: Kolon A blok CAD metraj örneği'],
    );

    await _ref.read(projectDataRepositoryProvider).writeDomain(
          projectId,
          'rebar_metraj',
          {'records': <Map<String, dynamic>>[]},
        );

    await _ref.read(rebarMetrajRepositoryProvider).saveResult(
          projectId: projectId,
          result: result,
          title: 'Demo · Kolon A Blok Metraj',
          surveyImalatId: _kolonId,
          surveyImalatName: 'Kolon',
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
