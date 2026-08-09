import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/main_discipline.dart';
import '../../domain/enums/request_status.dart';
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

  List<MaterialRequest> _replaceRequests(
    String projectId,
    KesifSnapshot kesif,
  ) {
    final kept = _ref
        .read(requestsProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    final selected = kesif.lines.take(4).toList();
    final now = DateTime.now();
    final requests = <MaterialRequest>[
      // Beklemede — kısmi onay
      MaterialRequest(
        id: IdGen.make('req'),
        projectId: projectId,
        name: selected[0].materialHint.isNotEmpty
            ? selected[0].materialHint
            : selected[0].tanim,
        category: selected[0].altGrup,
        unit: selected[0].birim,
        quantity: selected[0].miktar,
        requestDate: now.subtract(const Duration(days: 2)),
        requestedBy: 'Ahmet Yılmaz',
        status: RequestStatus.pending,
        note: 'Blok A ıslak hacimler',
        usageLocation: 'Blok A',
        pozCode: selected[0].pozNo,
        approvals: const RequestApprovals(sef: true),
        kesifLineId: selected[0].id,
        kesifSnapshotId: kesif.id,
      ),
      // Onaylandı — 3 onay → Teslim’de Gelen oluşur
      MaterialRequest(
        id: IdGen.make('req'),
        projectId: projectId,
        name: selected[1].materialHint.isNotEmpty
            ? selected[1].materialHint
            : selected[1].tanim,
        category: selected[1].altGrup,
        unit: selected[1].birim,
        quantity: selected[1].miktar,
        requestDate: now.subtract(const Duration(days: 5)),
        requestedBy: 'Mehmet Kaya',
        status: RequestStatus.approved,
        note: 'Kat boyası partisi',
        usageLocation: 'Blok B',
        pozCode: selected[1].pozNo,
        approvals: const RequestApprovals(
          sef: true,
          mudur: true,
          satinAlma: true,
        ),
        kesifLineId: selected[1].id,
        kesifSnapshotId: kesif.id,
      ),
      // Teslim edildi
      MaterialRequest(
        id: IdGen.make('req'),
        projectId: projectId,
        name: selected[2].tanim,
        category: selected[2].altGrup,
        unit: selected[2].birim,
        quantity: selected[2].miktar,
        requestDate: now.subtract(const Duration(days: 10)),
        requestedBy: 'Ayşe Demir',
        status: RequestStatus.delivered,
        note: 'Cephe yalıtım',
        usageLocation: 'Cephe',
        pozCode: selected[2].pozNo,
        approvals: const RequestApprovals(
          sef: true,
          mudur: true,
          satinAlma: true,
        ),
        receivedBy: 'Saha Depo',
        kesifLineId: selected[2].id,
        kesifSnapshotId: kesif.id,
      ),
      // Reddedildi
      MaterialRequest(
        id: IdGen.make('req'),
        projectId: projectId,
        name: selected[3].tanim,
        category: selected[3].altGrup,
        unit: selected[3].birim,
        quantity: selected[3].miktar,
        requestDate: now.subtract(const Duration(days: 3)),
        requestedBy: 'Can Öztürk',
        status: RequestStatus.rejected,
        note: 'Stoktan karşılanacak',
        pozCode: selected[3].pozNo,
        kesifLineId: selected[3].id,
        kesifSnapshotId: kesif.id,
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
