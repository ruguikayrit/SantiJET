import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/main_discipline.dart';
import '../../domain/enums/request_status.dart';
import '../../domain/kesif/material_need_calculator.dart';
import 'app_data_provider.dart';

/// Ayarlar → Demo: Malzeme akışını test etmeye yetecek örnek veri.
/// Pro RN `malzeme` kurgusu: tek kalem talep + 3 onay + talepten Gelen.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Şantiye';
  static const demoProjectCode = 'DEMO-MALZ-001';

  Future<Project> loadAll() async {
    final project = _ensureProject();
    _ref.read(activeProjectIdProvider.notifier).set(project.id);

    final kesif = _replaceKesif(project.id);
    _replaceUnitConsumptions(project.id, kesif);
    final requests = _replaceRequests(project.id, kesif);
    _replaceQuotes(project.id, requests);
    _replaceDeliveries(project.id, requests);
    _replaceLibrary();
    return project;
  }

  Project _ensureProject() {
    final projects = _ref.read(projectsProvider);
    for (final p in projects) {
      if (p.name == demoProjectName || p.code == demoProjectCode) {
        return p;
      }
    }
    return _ref.read(projectsProvider.notifier).add(
          name: demoProjectName,
          code: demoProjectCode,
          company: 'Demo İnşaat A.Ş.',
        );
  }

  KesifSnapshot _replaceKesif(String projectId) {
    final kept = _ref
        .read(kesifProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    final lines = <KesifLine>[
      KesifLine(
        id: IdGen.make('kln'),
        pozNo: 'Y.19.001',
        tanim: 'Seramik kaplama — ıslak hacim',
        birim: 'm²',
        miktar: 420,
        anaGrup: MainDiscipline.insaat,
        altGrup: 'Kaplama / seramik',
        materialHint: 'Seramik yapıştırıcı C2TE',
      ),
      KesifLine(
        id: IdGen.make('kln'),
        pozNo: 'Y.18.045',
        tanim: 'İç cephe boyası — 2 kat',
        birim: 'm²',
        miktar: 1800,
        anaGrup: MainDiscipline.insaat,
        altGrup: 'Boyalar',
        materialHint: 'İç cephe boyası',
      ),
      KesifLine(
        id: IdGen.make('kln'),
        pozNo: 'Y.25.012',
        tanim: 'XPS ısı yalıtımı 5 cm',
        birim: 'm²',
        miktar: 650,
        anaGrup: MainDiscipline.insaat,
        altGrup: 'Yalıtım',
      ),
      KesifLine(
        id: IdGen.make('kln'),
        pozNo: 'E.12.003',
        tanim: 'NYA kablo 3x2.5',
        birim: 'm',
        miktar: 2400,
        anaGrup: MainDiscipline.elektrik,
        altGrup: 'Pano / kablo',
      ),
      KesifLine(
        id: IdGen.make('kln'),
        pozNo: 'E.08.021',
        tanim: 'LED panel armatür 60x60',
        birim: 'ad',
        miktar: 180,
        anaGrup: MainDiscipline.elektrik,
        altGrup: 'Aydınlatma',
      ),
      KesifLine(
        id: IdGen.make('kln'),
        pozNo: 'M.04.010',
        tanim: 'PPR boru Ø25',
        birim: 'm',
        miktar: 920,
        anaGrup: MainDiscipline.mekanik,
        altGrup: 'Sıhhi tesisat',
      ),
      KesifLine(
        id: IdGen.make('kln'),
        pozNo: 'M.11.002',
        tanim: 'Yangın dolabı + hortum',
        birim: 'ad',
        miktar: 12,
        anaGrup: MainDiscipline.mekanik,
        altGrup: 'Yangın',
      ),
    ];

    final snapshot = KesifSnapshot(
      id: IdGen.make('ksf'),
      projectId: projectId,
      name: 'Demo Keşif v1',
      kesifProjectId: 'bfa-mock-001',
      source: 'mock',
      importedAt: DateTime.now(),
      lines: lines,
    );

    _ref.read(kesifProvider.notifier).replaceAll([...kept, snapshot]);
    return snapshot;
  }

  void _replaceUnitConsumptions(String projectId, KesifSnapshot kesif) {
    final kept = _ref
        .read(unitConsumptionsProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    UnitConsumption forPoz({
      required String pozNo,
      required String materialName,
      required String materialUnit,
      required double rate,
      required String kesifUnit,
      String category = '',
    }) =>
        UnitConsumption(
          id: IdGen.make('ucn'),
          projectId: projectId,
          materialName: materialName,
          materialUnit: materialUnit,
          rate: rate,
          pozNo: pozNo,
          kesifUnit: kesifUnit,
          category: category,
        );

    final lines = {for (final l in kesif.lines) l.pozNo: l};
    final items = <UnitConsumption>[
      if (lines.containsKey('Y.19.001')) ...[
        forPoz(
          pozNo: 'Y.19.001',
          materialName: 'Seramik yapıştırıcı C2TE',
          materialUnit: 'kg',
          rate: 5,
          kesifUnit: 'm²',
          category: 'Kaplama',
        ),
        forPoz(
          pozNo: 'Y.19.001',
          materialName: 'Seramik derz dolgu',
          materialUnit: 'kg',
          rate: 0.4,
          kesifUnit: 'm²',
          category: 'Kaplama',
        ),
      ],
      if (lines.containsKey('Y.18.045'))
        forPoz(
          pozNo: 'Y.18.045',
          materialName: 'İç cephe boyası',
          materialUnit: 'lt',
          rate: 0.18,
          kesifUnit: 'm²',
          category: 'Boyalar',
        ),
      if (lines.containsKey('Y.25.012'))
        forPoz(
          pozNo: 'Y.25.012',
          materialName: 'XPS levha 5 cm',
          materialUnit: 'm²',
          rate: 1.05,
          kesifUnit: 'm²',
          category: 'Yalıtım',
        ),
      if (lines.containsKey('E.12.003'))
        forPoz(
          pozNo: 'E.12.003',
          materialName: 'NYA kablo 3x2.5',
          materialUnit: 'm',
          rate: 1.08,
          kesifUnit: 'm',
          category: 'Kablo',
        ),
      if (lines.containsKey('E.08.021'))
        forPoz(
          pozNo: 'E.08.021',
          materialName: 'LED panel 60x60',
          materialUnit: 'ad',
          rate: 1,
          kesifUnit: 'ad',
          category: 'Aydınlatma',
        ),
      if (lines.containsKey('M.04.010'))
        forPoz(
          pozNo: 'M.04.010',
          materialName: 'PPR boru Ø25',
          materialUnit: 'm',
          rate: 1.05,
          kesifUnit: 'm',
          category: 'Sıhhi tesisat',
        ),
      if (lines.containsKey('M.11.002'))
        forPoz(
          pozNo: 'M.11.002',
          materialName: 'Yangın dolabı + hortum',
          materialUnit: 'ad',
          rate: 1,
          kesifUnit: 'ad',
          category: 'Yangın',
        ),
    ];

    _ref
        .read(unitConsumptionsProvider.notifier)
        .replaceAll([...kept, ...items]);
  }

  List<MaterialRequest> _replaceRequests(
    String projectId,
    KesifSnapshot kesif,
  ) {
    final kept = _ref
        .read(requestsProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    final consumptions = _ref
        .read(unitConsumptionsProvider)
        .where((e) => e.projectId == projectId)
        .toList();
    final needs = computeMaterialNeeds(
      lines: kesif.lines,
      consumptions: consumptions,
    ).take(4).toList();
    final now = DateTime.now();

    MaterialRequest reqFromNeed(
      MaterialNeed n, {
      required RequestStatus status,
      RequestApprovals approvals = const RequestApprovals(),
      String requestedBy = 'Saha',
      String note = '',
      String usageLocation = '',
      String receivedBy = '',
      int daysAgo = 0,
    }) {
      return MaterialRequest(
        id: IdGen.make('req'),
        projectId: projectId,
        name: n.materialName,
        category: n.consumption.category.isNotEmpty
            ? n.consumption.category
            : n.kesifLine.altGrup,
        unit: n.materialUnit,
        quantity: n.quantity,
        requestDate: now.subtract(Duration(days: daysAgo)),
        requestedBy: requestedBy,
        status: status,
        note: note,
        usageLocation: usageLocation,
        pozCode: n.pozNo,
        approvals: approvals,
        receivedBy: receivedBy,
        kesifLineId: n.kesifLine.id,
        kesifSnapshotId: kesif.id,
      );
    }

    final requests = <MaterialRequest>[
      if (needs.isNotEmpty)
        reqFromNeed(
          needs[0],
          status: RequestStatus.pending,
          approvals: const RequestApprovals(sef: true),
          requestedBy: 'Ahmet Yılmaz',
          note: 'Blok A ıslak hacimler',
          usageLocation: 'Blok A',
          daysAgo: 2,
        ),
      if (needs.length > 1)
        reqFromNeed(
          needs[1],
          status: RequestStatus.approved,
          approvals: const RequestApprovals(
            sef: true,
            mudur: true,
            satinAlma: true,
          ),
          requestedBy: 'Mehmet Kaya',
          note: 'Kat boyası partisi',
          usageLocation: 'Blok B',
          daysAgo: 5,
        ),
      if (needs.length > 2)
        reqFromNeed(
          needs[2],
          status: RequestStatus.delivered,
          approvals: const RequestApprovals(
            sef: true,
            mudur: true,
            satinAlma: true,
          ),
          requestedBy: 'Ayşe Demir',
          note: 'Cephe yalıtım',
          usageLocation: 'Cephe',
          receivedBy: 'Saha Depo',
          daysAgo: 10,
        ),
      if (needs.length > 3)
        reqFromNeed(
          needs[3],
          status: RequestStatus.rejected,
          requestedBy: 'Can Öztürk',
          note: 'Stoktan karşılanacak',
          daysAgo: 3,
        ),
    ];

    _ref.read(requestsProvider.notifier).replaceAll([...kept, ...requests]);
    return requests;
  }

  void _replaceQuotes(String projectId, List<MaterialRequest> requests) {
    final kept = _ref
        .read(quotesProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    final open = requests
        .where((r) => r.status != RequestStatus.rejected)
        .take(3)
        .toList();
    if (open.isEmpty) {
      _ref.read(quotesProvider.notifier).replaceAll(kept);
      return;
    }

    QuoteLine lineFor(MaterialRequest r, double price) => QuoteLine(
          id: IdGen.make('qln'),
          requestLineId: r.id,
          quantity: r.quantity,
          unitPrice: price,
          pozNo: r.pozCode,
          materialName: r.displayName,
          birim: r.unit,
        );

    final a = SupplierQuote(
      id: IdGen.make('sup'),
      supplierName: 'Anadolu Yapı Malzeme',
      paymentTermDays: 30,
      deliveryDays: 7,
      lines: [
        for (var i = 0; i < open.length; i++)
          lineFor(open[i], [48, 22, 95, 18][i % 4].toDouble()),
      ],
    );
    final b = SupplierQuote(
      id: IdGen.make('sup'),
      supplierName: 'Marmara Teknik',
      paymentTermDays: 45,
      deliveryDays: 10,
      lines: [
        for (var i = 0; i < open.length; i++)
          lineFor(open[i], [45, 24, 89, 19][i % 4].toDouble()),
      ],
    );

    final round = QuoteRound(
      id: IdGen.make('qrd'),
      projectId: projectId,
      requestId: open.first.id,
      title: 'Teklif turu — demo',
      createdAt: DateTime.now(),
      quotes: [a, b],
    );

    _ref.read(quotesProvider.notifier).replaceAll([...kept, round]);
  }

  void _replaceDeliveries(String projectId, List<MaterialRequest> requests) {
    final kept = _ref
        .read(deliveriesProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    final deliveries = <Delivery>[];

    // Manuel gelen (irsaliye)
    deliveries.add(
      Delivery(
        id: IdGen.make('dlv'),
        projectId: projectId,
        name: 'Çimento CEM I 42.5',
        category: 'Bağlayıcı',
        unit: 'ton',
        quantity: 24,
        irsaliyeQty: 24,
        date: DateTime.now().subtract(const Duration(days: 1)),
        supplier: 'Anadolu Yapı Malzeme',
        waybillNo: 'IRS-2026-0142',
        kantarEnabled: true,
      ),
    );

    // Onaylı talepler → Talepten Gelen
    for (final r in requests) {
      if (!r.approvals.allApproved) continue;
      if (r.status == RequestStatus.rejected) continue;
      deliveries.add(
        Delivery(
          id: IdGen.make('dlv'),
          projectId: projectId,
          name: r.displayName,
          category: r.category,
          unit: r.unit,
          quantity: r.quantity,
          irsaliyeQty: r.status == RequestStatus.delivered
              ? r.quantity
              : r.quantity * 0.6,
          date: DateTime.now().subtract(const Duration(days: 2)),
          supplier: 'Anadolu Yapı Malzeme',
          waybillNo: 'IRS-TLP-${r.pozCode.replaceAll('.', '')}',
          materialRequestId: r.id,
          pozCode: r.pozCode,
          notes: 'Talepten otomatik oluşturuldu',
          kantarEnabled: false,
        ),
      );
    }

    _ref
        .read(deliveriesProvider.notifier)
        .replaceAll([...kept, ...deliveries]);
  }

  void _replaceLibrary() {
    _ref.read(libraryProvider.notifier).replaceAll([
      TechSheet(
        id: IdGen.make('tds'),
        productName: 'Flex Yapıştırıcı C2TE',
        manufacturer: 'DemoChem',
        filePath: null,
        fileName: 'demochem_c2te_tds.pdf',
        mimeType: 'application/pdf',
        tags: const ['seramik', 'yapıştırıcı', 'C2TE'],
        notes:
            'Placeholder TDS — dosya henüz eklenmedi. Sipariş öncesi teknik karar örneği.',
        createdAt: DateTime.now(),
      ),
    ]);
  }
}

final demoSeedProvider = Provider<DemoSeedController>((ref) {
  return DemoSeedController(ref);
});

/// İlk frame’de boşsa demo veri tohumlar.
void seedDemoIfEmpty(WidgetRef ref) {
  if (ref.read(projectsProvider).isNotEmpty) return;
  ref.read(demoSeedProvider).loadAll();
}
