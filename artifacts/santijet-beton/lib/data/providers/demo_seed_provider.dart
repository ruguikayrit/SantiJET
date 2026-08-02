import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/id_gen.dart';
import '../../domain/entities/concrete_discovery.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/concrete_pour.dart';
import '../../domain/entities/metraj_variance_note.dart';
import '../../domain/entities/mixer_entry.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/quality_sample.dart';
import 'app_data_provider.dart';

/// Ayarlar → Demo: tüm Beton özelliklerini test etmeye yetecek örnek veri.
class DemoSeedController {
  DemoSeedController(this._ref);

  final Ref _ref;

  static const demoProjectName = 'Demo Şantiye';
  static const demoProjectCode = 'DEMO-001';

  Future<Project> loadAll() async {
    final project = _ensureProject();
    _ref.read(activeProjectIdProvider.notifier).set(project.id);

    _replaceDiscovery(project.id);
    final orders = _replaceOrders(project.id);
    _replacePours(projectId: project.id, orders: orders);
    _replaceVariance(project.id);
    _replaceQuality(project.id);
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

  void _replaceDiscovery(String projectId) {
    final kept = _ref
        .read(discoveryProvider)
        .where((e) => e.projectId != projectId)
        .toList();
    _ref.read(discoveryProvider.notifier).replaceAll([
      ...kept,
      ConcreteDiscoveryItem(
        id: IdGen.make('kes'),
        projectId: projectId,
        elementName: 'Temel Radye',
        plannedM3: 420,
        location: 'A Blok · Kot -3.20',
        concreteClass: 'C35/45',
        sortOrder: 0,
      ),
      ConcreteDiscoveryItem(
        id: IdGen.make('kes'),
        projectId: projectId,
        elementName: 'Kolon & Perde B1',
        plannedM3: 180,
        location: 'A Blok · Bodrum',
        concreteClass: 'C30/37',
        sortOrder: 1,
      ),
      ConcreteDiscoveryItem(
        id: IdGen.make('kes'),
        projectId: projectId,
        elementName: 'Döşeme K1',
        plannedM3: 95,
        location: 'A Blok · Kat 1',
        concreteClass: 'C30/37',
        sortOrder: 2,
      ),
      ConcreteDiscoveryItem(
        id: IdGen.make('kes'),
        projectId: projectId,
        elementName: 'Döşeme K2',
        plannedM3: 88,
        location: 'A Blok · Kat 2',
        concreteClass: 'C30/37',
        sortOrder: 3,
      ),
    ]);
  }

  List<ConcreteOrder> _replaceOrders(String projectId) {
    final kept = _ref
        .read(ordersProvider)
        .where((e) => e.projectId != projectId)
        .toList();
    final today = AppDate.format(AppDate.today());
    final tomorrow =
        AppDate.format(AppDate.today().add(const Duration(days: 1)));

    final orderPerde = ConcreteOrder(
      id: IdGen.make('sip'),
      projectId: projectId,
      plannedDate: today,
      plannedM3: 48,
      elementName: 'Kolon & Perde B1',
      block: 'A Blok',
      floor: 'Bodrum Kat',
      concreteClass: 'C30/37',
      supplier: 'Akdeniz Beton',
      plannedStartHour: '07:30',
      slumpCm: 14,
      pumpCount: 1,
      pumpType: 'Mobil',
      notes: '[DEMO] Pompa + 2 mikser peş peşe',
    );
    final orderTemel = ConcreteOrder(
      id: IdGen.make('sip'),
      projectId: projectId,
      plannedDate: AppDate.format(
        AppDate.today().subtract(const Duration(days: 1)),
      ),
      plannedM3: 80,
      elementName: 'Temel Radye',
      block: 'A Blok',
      floor: 'Kot -3.20',
      concreteClass: 'C35/45',
      supplier: 'Akdeniz Beton',
      plannedStartHour: '06:00',
      slumpCm: 16,
      pumpCount: 1,
      pumpType: 'Sabit',
      notes: '[DEMO] Temel dökümü',
    );
    final orderDoseme = ConcreteOrder(
      id: IdGen.make('sip'),
      projectId: projectId,
      plannedDate: tomorrow,
      plannedM3: 55,
      elementName: 'Döşeme K1',
      block: 'A Blok',
      floor: 'Kat 1',
      concreteClass: 'C30/37',
      supplier: 'Akdeniz Beton',
      plannedStartHour: '08:00',
      slumpCm: 16,
      pumpCount: 1,
      pumpType: 'Sabit',
      notes: '[DEMO] Döşeme planı',
    );

    final demoOrders = [orderTemel, orderPerde, orderDoseme];
    _ref.read(ordersProvider.notifier).replaceAll([...kept, ...demoOrders]);
    return demoOrders;
  }

  void _replacePours({
    required String projectId,
    required List<ConcreteOrder> orders,
  }) {
    final kept = _ref
        .read(poursProvider)
        .where((e) => e.projectId != projectId)
        .toList();
    final today = AppDate.format(AppDate.today());
    final yesterday = AppDate.format(
      AppDate.today().subtract(const Duration(days: 1)),
    );
    final orderTemel = orders.firstWhere((o) => o.elementName.contains('Temel'));
    final orderPerde =
        orders.firstWhere((o) => o.elementName.contains('Kolon'));

    final pours = <ConcretePour>[
      ConcretePour(
        id: IdGen.make('dok'),
        projectId: projectId,
        date: yesterday,
        volumeM3: 86,
        elementName: 'Temel Radye',
        block: 'A Blok',
        floor: 'Kot -3.20',
        concreteClass: 'C35/45',
        supplier: 'Akdeniz Beton',
        ticketNo: 'IR-10421',
        mixerCount: 2,
        mixerPlate: '34 ABC 123',
        mixers: [
          MixerEntry(
            id: IdGen.make('mx'),
            ticketNo: 'IR-10421',
            plate: '34 ABC 123',
            volumeM3: 43,
            concreteClass: 'C35/45',
          ),
          MixerEntry(
            id: IdGen.make('mx'),
            ticketNo: 'IR-10422',
            plate: '34 ABC 124',
            volumeM3: 43,
            concreteClass: 'C35/45',
          ),
        ],
        pumpCount: 1,
        pumpType: 'Sabit',
        slumpCm: 16,
        sampleType: ConcreteSampleType.cylinder,
        sampleCount: 6,
        sampleTakenHour: '08:15',
        pourStart: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        pourEnd: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        orderId: orderTemel.id,
        notes: '[DEMO] Temel dökümü',
      ),
      ConcretePour(
        id: IdGen.make('dok'),
        projectId: projectId,
        date: today,
        volumeM3: 42,
        elementName: 'Kolon & Perde B1',
        block: 'A Blok',
        floor: 'Bodrum Kat',
        concreteClass: 'C30/37',
        supplier: 'Akdeniz Beton',
        ticketNo: 'IR-10488',
        mixerCount: 1,
        mixerPlate: '34 XYZ 456',
        mixers: [
          MixerEntry(
            id: IdGen.make('mx'),
            ticketNo: 'IR-10488',
            plate: '34 XYZ 456',
            volumeM3: 42,
            concreteClass: 'C30/37',
          ),
        ],
        pumpCount: 1,
        pumpType: 'Mobil',
        slumpCm: 14,
        sampleType: ConcreteSampleType.cube,
        sampleCount: 4,
        sampleTakenHour: '07:45',
        pourStart: DateTime.now().subtract(const Duration(hours: 3)),
        orderId: orderPerde.id,
        notes: '[DEMO] Kolon & perde dökümü',
      ),
      ConcretePour(
        id: IdGen.make('dok'),
        projectId: projectId,
        date: AppDate.format(
          AppDate.today().subtract(const Duration(days: 3)),
        ),
        volumeM3: 38,
        elementName: 'Döşeme K1',
        block: 'A Blok',
        floor: 'Kat 1',
        concreteClass: 'C30/37',
        supplier: 'Akdeniz Beton',
        ticketNo: 'IR-10390',
        mixerCount: 1,
        mixers: [
          MixerEntry(
            id: IdGen.make('mx'),
            ticketNo: 'IR-10390',
            plate: '34 DEF 789',
            volumeM3: 38,
            concreteClass: 'C30/37',
          ),
        ],
        pumpCount: 1,
        pumpType: 'Sabit',
        slumpCm: 15,
        sampleType: ConcreteSampleType.cylinder,
        sampleCount: 3,
        sampleTakenHour: '09:00',
        notes: '[DEMO] Döşeme dökümü',
      ),
    ];

    _ref.read(poursProvider.notifier).replaceAll([...kept, ...pours]);
  }

  void _replaceVariance(String projectId) {
    final kept = _ref
        .read(varianceProvider)
        .where((e) => e.projectId != projectId)
        .toList();
    final yesterday = AppDate.format(
      AppDate.today().subtract(const Duration(days: 1)),
    );
    _ref.read(varianceProvider.notifier).replaceAll([
      ...kept,
      MetrajVarianceNote(
        id: IdGen.make('fark'),
        projectId: projectId,
        date: yesterday,
        plannedM3: 80,
        actualM3: 86,
        reason: 'Kalıp şişmesi / ek dolgu',
        elementName: 'Temel Radye',
        detail: '[DEMO] Kenar kalıplarında 6 m³ ek döküm yapıldı.',
      ),
    ]);
  }

  void _replaceQuality(String projectId) {
    final kept = _ref
        .read(qualityProvider)
        .where((e) => e.projectId != projectId)
        .toList();
    final today = AppDate.today();
    String day(int offset) =>
        AppDate.format(today.subtract(Duration(days: offset)));

    _ref.read(qualityProvider.notifier).replaceAll([
      ...kept,
      QualitySample(
        id: IdGen.make('num'),
        projectId: projectId,
        elementGroup: ConcreteElementGroup.temel,
        labReportNo: 'LAB-2026-0142',
        sampleDate: day(7),
        sampleCode: 'TEM-01',
        concreteClass: 'C35/45',
        ageDays: 7,
        strengthMpa: 28.4,
        minStrengthMpa: 26.8,
        isCompliant: true,
        notes: '[DEMO] 7 günlük erken dayanım',
      ),
      QualitySample(
        id: IdGen.make('num'),
        projectId: projectId,
        elementGroup: ConcreteElementGroup.temel,
        labReportNo: 'LAB-2026-0188',
        sampleDate: day(1),
        sampleCode: 'TEM-02',
        concreteClass: 'C35/45',
        ageDays: 28,
        strengthMpa: 42.1,
        minStrengthMpa: 39.6,
        isCompliant: true,
        notes: '[DEMO] 28 günlük sonuç',
      ),
      QualitySample(
        id: IdGen.make('num'),
        projectId: projectId,
        elementGroup: ConcreteElementGroup.kolonPerde,
        labReportNo: 'LAB-2026-0195',
        sampleDate: day(2),
        sampleCode: 'KP-01',
        concreteClass: 'C30/37',
        ageDays: 7,
        strengthMpa: 22.5,
        minStrengthMpa: 20.1,
        isCompliant: true,
        notes: '[DEMO] Kolon & perde 7 gün',
      ),
      QualitySample(
        id: IdGen.make('num'),
        projectId: projectId,
        elementGroup: ConcreteElementGroup.kolonPerde,
        labReportNo: 'LAB-2026-0201',
        sampleDate: day(0),
        sampleCode: 'KP-02',
        concreteClass: 'C30/37',
        ageDays: 28,
        notes: '[DEMO] Sonuç bekleniyor',
      ),
      QualitySample(
        id: IdGen.make('num'),
        projectId: projectId,
        elementGroup: ConcreteElementGroup.doseme,
        labReportNo: 'LAB-2026-0170',
        sampleDate: day(10),
        sampleCode: 'DOS-01',
        concreteClass: 'C30/37',
        ageDays: 28,
        strengthMpa: 31.2,
        minStrengthMpa: 27.0,
        isCompliant: false,
        slagNote: 'Cüruf oranı %18',
        notes: '[DEMO] Min dayanım sınırın altında',
      ),
      QualitySample(
        id: IdGen.make('num'),
        projectId: projectId,
        elementGroup: ConcreteElementGroup.doseme,
        labReportNo: 'LAB-2026-0177',
        sampleDate: day(4),
        sampleCode: 'DOS-02',
        concreteClass: 'C30/37',
        ageDays: 7,
        strengthMpa: 19.8,
        minStrengthMpa: 18.5,
        isCompliant: true,
      ),
    ]);
  }
}

final demoSeedControllerProvider = Provider<DemoSeedController>((ref) {
  return DemoSeedController(ref);
});
