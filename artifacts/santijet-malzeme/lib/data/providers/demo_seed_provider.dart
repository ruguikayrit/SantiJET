import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/main_discipline.dart';
import '../../domain/enums/request_status.dart';
import 'app_data_provider.dart';

/// Ayarlar → Demo: Malzeme akışını test etmeye yetecek örnek veri.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Şantiye';
  static const demoProjectCode = 'DEMO-MALZ-001';

  Future<Project> loadAll() async {
    final project = _ensureProject();
    _ref.read(activeProjectIdProvider.notifier).set(project.id);

    final kesif = _replaceKesif(project.id);
    final request = _replaceRequests(project.id, kesif);
    _replaceQuotes(project.id, request);
    _replaceDeliveries(project.id, request);
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

  MaterialRequest _replaceRequests(String projectId, KesifSnapshot kesif) {
    final kept = _ref
        .read(requestsProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    final selected = kesif.lines.take(4).toList();
    final lines = selected
        .map(
          (l) => MaterialRequestLine(
            id: IdGen.make('rln'),
            materialName:
                l.materialHint.isNotEmpty ? l.materialHint : l.tanim,
            birim: l.birim,
            miktar: l.miktar,
            kesifLineId: l.id,
            pozNo: l.pozNo,
          ),
        )
        .toList();

    final request = MaterialRequest(
      id: IdGen.make('req'),
      projectId: projectId,
      title: 'Haftalık malzeme talebi #1',
      kesifSnapshotId: kesif.id,
      status: RequestStatus.taslak,
      createdAt: DateTime.now(),
      notes: 'Demo taslak talep — 2 sahte tedarikçi teklifiyle mukayese.',
      lines: lines,
    );

    _ref.read(requestsProvider.notifier).replaceAll([...kept, request]);
    return request;
  }

  void _replaceQuotes(String projectId, MaterialRequest request) {
    final kept = _ref
        .read(quotesProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    QuoteLine lineFor(MaterialRequestLine rl, double price) => QuoteLine(
          id: IdGen.make('qln'),
          requestLineId: rl.id,
          quantity: rl.miktar,
          unitPrice: price,
          pozNo: rl.pozNo,
          materialName: rl.materialName,
          birim: rl.birim,
        );

    final a = SupplierQuote(
      id: IdGen.make('sup'),
      supplierName: 'Anadolu Yapı Malzeme',
      paymentTermDays: 30,
      deliveryDays: 7,
      lines: [
        for (var i = 0; i < request.lines.length; i++)
          lineFor(request.lines[i], [48, 22, 95, 18][i % 4].toDouble()),
      ],
    );
    final b = SupplierQuote(
      id: IdGen.make('sup'),
      supplierName: 'Marmara Teknik',
      paymentTermDays: 45,
      deliveryDays: 10,
      lines: [
        for (var i = 0; i < request.lines.length; i++)
          lineFor(request.lines[i], [45, 24, 89, 19][i % 4].toDouble()),
      ],
    );

    final round = QuoteRound(
      id: IdGen.make('qrd'),
      projectId: projectId,
      requestId: request.id,
      title: 'Teklif turu — demo',
      createdAt: DateTime.now(),
      quotes: [a, b],
    );

    _ref.read(quotesProvider.notifier).replaceAll([...kept, round]);
  }

  void _replaceDeliveries(String projectId, MaterialRequest request) {
    final kept = _ref
        .read(deliveriesProvider)
        .where((e) => e.projectId != projectId)
        .toList();

    if (request.lines.isEmpty) {
      _ref.read(deliveriesProvider.notifier).replaceAll(kept);
      return;
    }

    final first = request.lines.first;
    final delivery = Delivery(
      id: IdGen.make('dlv'),
      projectId: projectId,
      date: DateTime.now().subtract(const Duration(days: 1)),
      requestId: request.id,
      irsaliyeNo: 'IRS-2026-0142',
      supplierName: 'Anadolu Yapı Malzeme',
      lines: [
        DeliveryLine(
          id: IdGen.make('dln'),
          materialName: first.materialName,
          birim: first.birim,
          quantity: first.miktar * 0.4,
          requestLineId: first.id,
          kesifLineId: first.kesifLineId,
          pozNo: first.pozNo,
        ),
      ],
    );

    _ref.read(deliveriesProvider.notifier).replaceAll([...kept, delivery]);
  }

  void _replaceLibrary() {
    // Dosya yok — sadece placeholder metadata (Faz 3: dosya deposu).
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
