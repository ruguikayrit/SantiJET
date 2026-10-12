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
          progress: 44,
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
    final imalats = [
      _imalatWithBlocks(
        id: _kolonId,
        name: 'Kolon',
        progressPercent: 52,
        lines: const [
          DiameterLine(diameter: 12, planned: 96, ordered: 52, delivered: 46, progressPercent: 52),
          DiameterLine(diameter: 14, planned: 74, ordered: 38, delivered: 32, progressPercent: 50),
          DiameterLine(diameter: 16, planned: 48, ordered: 24, delivered: 20, progressPercent: 48),
        ],
      ),
      _imalatWithBlocks(
        id: _kirisId,
        name: 'Kiriş',
        progressPercent: 38,
        lines: const [
          DiameterLine(diameter: 12, planned: 58, ordered: 32, delivered: 22, progressPercent: 38),
          DiameterLine(diameter: 14, planned: 82, ordered: 44, delivered: 28, progressPercent: 36),
          DiameterLine(diameter: 20, planned: 36, ordered: 18, delivered: 10, progressPercent: 32),
        ],
      ),
      _imalatWithBlocks(
        id: _perdeId,
        name: 'Perde',
        progressPercent: 41,
        lines: const [
          DiameterLine(diameter: 10, planned: 42, ordered: 22, delivered: 14, progressPercent: 42),
          DiameterLine(diameter: 12, planned: 64, ordered: 34, delivered: 22, progressPercent: 40),
          DiameterLine(diameter: 16, planned: 52, ordered: 26, delivered: 16, progressPercent: 38),
        ],
      ),
      _imalatWithBlocks(
        id: _temelId,
        name: 'Temel',
        progressPercent: 66,
        lines: const [
          DiameterLine(diameter: 12, planned: 88, ordered: 58, delivered: 52, progressPercent: 66),
          DiameterLine(diameter: 14, planned: 76, ordered: 48, delivered: 42, progressPercent: 64),
          DiameterLine(diameter: 16, planned: 68, ordered: 44, delivered: 38, progressPercent: 62),
          DiameterLine(diameter: 20, planned: 54, ordered: 32, delivered: 28, progressPercent: 60),
        ],
      ),
      _imalatWithBlocks(
        id: _dosemeId,
        name: 'Döşeme',
        progressPercent: 34,
        lines: const [
          DiameterLine(diameter: 10, planned: 42, ordered: 18, delivered: 8, progressPercent: 34),
          DiameterLine(diameter: 12, planned: 56, ordered: 24, delivered: 10, progressPercent: 32),
          DiameterLine(diameter: 14, planned: 48, ordered: 20, delivered: 8, progressPercent: 30),
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
        date: now.subtract(const Duration(days: 14)),
        imalatTypes: const ['Kolon'],
        imalatTonnages: const {'Kolon': 72},
        tonnage: 72,
        status: OrderStatus.completed,
        supplier: demoSupplier,
        diameterAmounts: const {12: 28, 14: 26, 16: 18},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
      OrderItem(
        id: 'demo-order-002',
        orderNo: 'SP-$year-0002',
        date: now.subtract(const Duration(days: 6)),
        imalatTypes: const ['Kiriş'],
        imalatTonnages: const {'Kiriş': 58},
        tonnage: 58,
        status: OrderStatus.inTransit,
        supplier: demoSupplier,
        diameterAmounts: const {12: 16, 14: 28, 20: 14},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
      OrderItem(
        id: 'demo-order-003',
        orderNo: 'SP-$year-0003',
        date: now.subtract(const Duration(days: 2)),
        imalatTypes: const ['Perde'],
        imalatTonnages: const {'Perde': 50},
        tonnage: 50,
        status: OrderStatus.submitted,
        supplier: demoSupplier,
        diameterAmounts: const {10: 10, 12: 22, 16: 18},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
      ),
      OrderItem(
        id: 'demo-order-004',
        orderNo: 'SP-$year-0004',
        date: now.subtract(const Duration(hours: 8)),
        imalatTypes: const ['Temel'],
        imalatTonnages: const {'Temel': 94},
        tonnage: 94,
        status: OrderStatus.pendingApproval,
        supplier: demoSupplier,
        diameterAmounts: const {12: 24, 14: 22, 16: 20, 20: 28},
        approvals: const OrderApprovals(purchasing: false, projectManager: false),
      ),
      OrderItem(
        id: 'demo-order-005',
        orderNo: 'SP-$year-0005',
        date: now.subtract(const Duration(days: 20)),
        imalatTypes: const ['Döşeme'],
        imalatTonnages: const {'Döşeme': 46},
        tonnage: 46,
        status: OrderStatus.cancelled,
        supplier: demoSupplier,
        diameterAmounts: const {10: 12, 12: 18, 14: 16},
        approvals: const OrderApprovals(purchasing: true, projectManager: true),
        cancellation: OrderCancellation(
          cancelledByName: 'Demo Proje Müdürü',
          cancellationReason: 'İmalat takvimi revizyonu — döşeme siparişi iptal.',
          cancelledAt: now.subtract(const Duration(days: 18)),
        ),
      ),
    ];
  }

  List<DeliveryItem> _buildDeliveries(List<OrderItem> orders) {
    final kolon = orders.firstWhere((o) => o.id == 'demo-order-001');
    final kiris = orders.firstWhere((o) => o.id == 'demo-order-002');
    final now = DateTime.now();

    const kolonLines = [
      DeliveryDiameterLine(diameter: 12, ordered: 28, delivered: 26),
      DeliveryDiameterLine(diameter: 14, ordered: 26, delivered: 24),
      DeliveryDiameterLine(diameter: 16, ordered: 18, delivered: 16),
    ];
    const kirisLines = [
      DeliveryDiameterLine(diameter: 12, ordered: 16, delivered: 12),
      DeliveryDiameterLine(diameter: 14, ordered: 28, delivered: 20),
      DeliveryDiameterLine(diameter: 20, ordered: 14, delivered: 8),
    ];

    final kolonDelivered =
        kolonLines.fold<double>(0, (sum, line) => sum + line.delivered);
    final kirisDelivered =
        kirisLines.fold<double>(0, (sum, line) => sum + line.delivered);

    return [
      DeliveryItem(
        id: 'demo-delivery-001',
        orderId: kolon.id,
        orderNo: kolon.orderNo,
        irsaliyeNo: 'IRS-2026-0142',
        date: now.subtract(const Duration(days: 11)),
        supplier: demoSupplier,
        tonnage: kolonDelivered,
        fulfillmentPercent: kolonDelivered / kolon.tonnage * 100,
        status: DeliveryStatus.partial,
        diameterLines: kolonLines,
        plateNo: '34 DK 4821',
      ),
      DeliveryItem(
        id: 'demo-delivery-002',
        orderId: kiris.id,
        orderNo: kiris.orderNo,
        irsaliyeNo: 'IRS-2026-0198',
        date: now.subtract(const Duration(days: 1)),
        supplier: demoSupplier,
        tonnage: kirisDelivered,
        fulfillmentPercent: kirisDelivered / kiris.tonnage * 100,
        status: DeliveryStatus.partial,
        diameterLines: kirisLines,
        plateNo: '34 FN 9033',
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
        expected: 0,
        actual: 86.4,
        status: 'completed',
        note: 'Sabah sayımı — yağmur sonrası nemli zemin.',
        lines: const [
          FieldCountLineRecord(
            diameter: 12,
            delivered: 0,
            plannedUsage: 0,
            expectedStock: 0,
            actual: 24.2,
          ),
          FieldCountLineRecord(
            diameter: 14,
            delivered: 0,
            plannedUsage: 0,
            expectedStock: 0,
            actual: 28.6,
          ),
          FieldCountLineRecord(
            diameter: 16,
            delivered: 0,
            plannedUsage: 0,
            expectedStock: 0,
            actual: 18.4,
          ),
          FieldCountLineRecord(
            diameter: 20,
            delivered: 0,
            plannedUsage: 0,
            expectedStock: 0,
            actual: 15.2,
          ),
        ],
      ),
      FieldCountRecord(
        id: 'demo-count-prev',
        title: 'C Blok · Perde hattı',
        date: now.subtract(const Duration(days: 3)),
        personnel: 'Ayşe Kaya',
        region: 'C Blok · Perde hattı',
        expected: 0,
        actual: 52.8,
        status: 'completed',
        note: 'Perde öncesi stok kontrolü.',
        lines: const [
          FieldCountLineRecord(
            diameter: 10,
            delivered: 0,
            plannedUsage: 0,
            expectedStock: 0,
            actual: 8.6,
          ),
          FieldCountLineRecord(
            diameter: 12,
            delivered: 0,
            plannedUsage: 0,
            expectedStock: 0,
            actual: 22.4,
          ),
          FieldCountLineRecord(
            diameter: 16,
            delivered: 0,
            plannedUsage: 0,
            expectedStock: 0,
            actual: 21.8,
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
