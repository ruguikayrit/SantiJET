import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/id_gen.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/pour_plan.dart';
import '../../domain/entities/pour_record.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/quality_sample.dart';

final projectsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('projectsBoxProvider override edilmeli'),
);
final pourPlansBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('pourPlansBoxProvider override edilmeli'),
);
final pourRecordsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('pourRecordsBoxProvider override edilmeli'),
);
final ordersBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('ordersBoxProvider override edilmeli'),
);
final qualityBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('qualityBoxProvider override edilmeli'),
);

class ActiveProjectNotifier extends StateNotifier<String?> {
  ActiveProjectNotifier(this._box) : super(_box.get('activeProjectId') as String?);
  final Box _box;
  void set(String? id) {
    state = id;
    if (id == null) {
      _box.delete('activeProjectId');
    } else {
      _box.put('activeProjectId', id);
    }
  }
}

final activeProjectIdProvider =
    StateNotifierProvider<ActiveProjectNotifier, String?>((ref) {
  return ActiveProjectNotifier(ref.watch(settingsBoxProvider));
});

List<Map<String, dynamic>> _readList(Box box, String key) {
  final raw = box.get(key);
  if (raw is String && raw.isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }
  if (raw is List) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

void _writeList(Box box, String key, List<Map<String, dynamic>> items) {
  box.put(key, jsonEncode(items));
}

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier(this._box) : super(_load(_box));
  final Box _box;
  static List<Project> _load(Box box) =>
      _readList(box, 'items').map(Project.fromJson).toList();
  void _persist() =>
      _writeList(_box, 'items', state.map((e) => e.toJson()).toList());
  bool get isEmpty => state.isEmpty;
  Project add({required String name, String code = '', String company = ''}) {
    final p = Project(
      id: IdGen.make('prj'),
      name: name.trim(),
      code: code.trim(),
      company: company.trim(),
      createdAt: DateTime.now(),
    );
    state = [...state, p];
    _persist();
    return p;
  }
  void update(Project project) {
    state = [for (final p in state) if (p.id == project.id) project else p];
    _persist();
  }
  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }
  void replaceAll(List<Project> items) {
    state = List.from(items);
    _persist();
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  return ProjectsNotifier(ref.watch(projectsBoxProvider));
});

final activeProjectProvider = Provider<Project?>((ref) {
  final id = ref.watch(activeProjectIdProvider);
  final projects = ref.watch(projectsProvider);
  if (projects.isEmpty) return null;
  if (id != null) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
  }
  return projects.first;
});

class PourPlansNotifier extends StateNotifier<List<PourPlan>> {
  PourPlansNotifier(this._box) : super(_load(_box));
  final Box _box;
  static List<PourPlan> _load(Box box) =>
      _readList(box, 'items').map(PourPlan.fromJson).toList();
  void _persist() =>
      _writeList(_box, 'items', state.map((e) => e.toJson()).toList());
  void add(PourPlan draft) {
    state = [...state, draft.copyWith(id: IdGen.make('pln'))];
    _persist();
  }
  void update(PourPlan item) {
    state = [for (final e in state) if (e.id == item.id) item else e];
    _persist();
  }
  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }
  void deleteForProject(String projectId) {
    state = state.where((e) => e.projectId != projectId).toList();
    _persist();
  }
  void replaceAll(List<PourPlan> items) {
    state = List.from(items);
    _persist();
  }
}

final pourPlansProvider =
    StateNotifierProvider<PourPlansNotifier, List<PourPlan>>((ref) {
  return PourPlansNotifier(ref.watch(pourPlansBoxProvider));
});

class PourRecordsNotifier extends StateNotifier<List<PourRecord>> {
  PourRecordsNotifier(this._box) : super(_load(_box));
  final Box _box;
  static List<PourRecord> _load(Box box) =>
      _readList(box, 'items').map(PourRecord.fromJson).toList();
  void _persist() =>
      _writeList(_box, 'items', state.map((e) => e.toJson()).toList());
  void add(PourRecord draft) {
    state = [...state, draft.copyWith(id: IdGen.make('dok'))];
    _persist();
  }
  void update(PourRecord item) {
    state = [for (final e in state) if (e.id == item.id) item else e];
    _persist();
  }
  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }
  void deleteForProject(String projectId) {
    state = state.where((e) => e.projectId != projectId).toList();
    _persist();
  }
  void replaceAll(List<PourRecord> items) {
    state = List.from(items);
    _persist();
  }
}

final pourRecordsProvider =
    StateNotifierProvider<PourRecordsNotifier, List<PourRecord>>((ref) {
  return PourRecordsNotifier(ref.watch(pourRecordsBoxProvider));
});

class OrdersNotifier extends StateNotifier<List<ConcreteOrder>> {
  OrdersNotifier(this._box) : super(_load(_box));
  final Box _box;
  static List<ConcreteOrder> _load(Box box) =>
      _readList(box, 'items').map(ConcreteOrder.fromJson).toList();
  void _persist() =>
      _writeList(_box, 'items', state.map((e) => e.toJson()).toList());
  void add(ConcreteOrder draft) {
    state = [...state, draft.copyWith(id: IdGen.make('sip'))];
    _persist();
  }
  void update(ConcreteOrder item) {
    state = [for (final e in state) if (e.id == item.id) item else e];
    _persist();
  }
  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }
  void deleteForProject(String projectId) {
    state = state.where((e) => e.projectId != projectId).toList();
    _persist();
  }
  void replaceAll(List<ConcreteOrder> items) {
    state = List.from(items);
    _persist();
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<ConcreteOrder>>((ref) {
  return OrdersNotifier(ref.watch(ordersBoxProvider));
});

class QualityNotifier extends StateNotifier<List<QualitySample>> {
  QualityNotifier(this._box) : super(_load(_box));
  final Box _box;
  static List<QualitySample> _load(Box box) =>
      _readList(box, 'items').map(QualitySample.fromJson).toList();
  void _persist() =>
      _writeList(_box, 'items', state.map((e) => e.toJson()).toList());
  void add(QualitySample draft) {
    state = [...state, draft.copyWith(id: IdGen.make('num'))];
    _persist();
  }
  void update(QualitySample item) {
    state = [for (final e in state) if (e.id == item.id) item else e];
    _persist();
  }
  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }
  void deleteForProject(String projectId) {
    state = state.where((e) => e.projectId != projectId).toList();
    _persist();
  }
  void replaceAll(List<QualitySample> items) {
    state = List.from(items);
    _persist();
  }
}

final qualityProvider =
    StateNotifierProvider<QualityNotifier, List<QualitySample>>((ref) {
  return QualityNotifier(ref.watch(qualityBoxProvider));
});

final activePourPlansProvider = Provider<List<PourPlan>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(pourPlansProvider);
  if (project == null) return const [];
  final list = all.where((e) => e.projectId == project.id).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return list;
});

final activePourRecordsProvider = Provider<List<PourRecord>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(pourRecordsProvider);
  if (project == null) return const [];
  final list = all.where((e) => e.projectId == project.id).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return list;
});

final activeOrdersProvider = Provider<List<ConcreteOrder>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(ordersProvider);
  if (project == null) return const [];
  final list = all.where((e) => e.projectId == project.id).toList()
    ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
  return list;
});

final activeQualityProvider = Provider<List<QualitySample>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(qualityProvider);
  if (project == null) return const [];
  final list = all.where((e) => e.projectId == project.id).toList()
    ..sort((a, b) => b.sampleDate.compareTo(a.sampleDate));
  return list;
});

class DashboardSummary {
  const DashboardSummary({
    required this.todayPlannedM3,
    required this.todayPouredM3,
    required this.openOrders,
    required this.pendingSamples,
  });
  final double todayPlannedM3;
  final double todayPouredM3;
  final int openOrders;
  final int pendingSamples;
}

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final today = AppDate.format(AppDate.today());
  final plans = ref.watch(activePourPlansProvider);
  final pours = ref.watch(activePourRecordsProvider);
  final orders = ref.watch(activeOrdersProvider);
  final samples = ref.watch(activeQualityProvider);
  return DashboardSummary(
    todayPlannedM3: plans
        .where((p) => p.date == today && p.status == PourPlanStatus.planned)
        .fold(0, (s, p) => s + p.plannedM3),
    todayPouredM3: pours
        .where((p) => p.date == today)
        .fold(0, (s, p) => s + p.actualM3),
    openOrders: orders
        .where((o) =>
            o.status == OrderStatus.open || o.status == OrderStatus.partial)
        .length,
    pendingSamples: samples.where((s) => s.isPending).length,
  );
});

/// Demo veri sürümü — artırınca mevcut yerel veri temizlenip yeniden tohumlanır.
const demoSeedVersion = 2;

/// Staging / test için zengin örnek veri.
void ensureDemoSeed({
  required Box settingsBox,
  required ProjectsNotifier projects,
  required PourPlansNotifier plans,
  required PourRecordsNotifier pours,
  required OrdersNotifier orders,
  required QualityNotifier quality,
  required ActiveProjectNotifier active,
}) {
  final current = settingsBox.get('demoSeedVersion') as int? ?? 0;
  if (current >= demoSeedVersion && !projects.isEmpty) return;

  projects.replaceAll([]);
  plans.replaceAll([]);
  pours.replaceAll([]);
  orders.replaceAll([]);
  quality.replaceAll([]);

  final p1 = projects.add(
    name: 'Kadıköy Rezidans',
    code: 'BET-R1-001',
    company: 'ŞantiJET Yapı A.Ş.',
  );
  final p2 = projects.add(
    name: 'Ankara AVM Otopark',
    code: 'BET-R1-002',
    company: 'Anadolu İnşaat Ltd.',
  );
  active.set(p1.id);

  final today = AppDate.today();
  String d(int daysAgo) =>
      AppDate.format(today.subtract(Duration(days: daysAgo)));

  // —— Proje 1: planlar ——
  plans.add(PourPlan(
    id: '',
    projectId: p1.id,
    date: d(0),
    location: 'Blok A — Temel',
    concreteClass: 'C30/37',
    plannedM3: 48,
    status: PourPlanStatus.planned,
    notes: 'Sabah 07:00 mikser hattı',
  ));
  plans.add(PourPlan(
    id: '',
    projectId: p1.id,
    date: d(0),
    location: 'Blok A — Bodrum perde',
    concreteClass: 'C25/30',
    plannedM3: 22,
    status: PourPlanStatus.planned,
  ));
  plans.add(PourPlan(
    id: '',
    projectId: p1.id,
    date: d(1),
    location: 'Blok B — Perde',
    concreteClass: 'C25/30',
    plannedM3: 32,
    status: PourPlanStatus.completed,
  ));
  plans.add(PourPlan(
    id: '',
    projectId: p1.id,
    date: d(2),
    location: 'Blok B — Döşeme',
    concreteClass: 'C30/37',
    plannedM3: 55,
    status: PourPlanStatus.completed,
  ));
  plans.add(PourPlan(
    id: '',
    projectId: p1.id,
    date: d(3),
    location: 'Blok C — Merdiven',
    concreteClass: 'C20/25',
    plannedM3: 8,
    status: PourPlanStatus.cancelled,
    notes: 'Kalıp gecikmesi',
  ));

  // —— Proje 1: dökümler ——
  pours.add(PourRecord(
    id: '',
    projectId: p1.id,
    date: d(0),
    actualM3: 18.5,
    concreteClass: 'C30/37',
    location: 'Blok A — Temel (kısmi)',
    mixerNote: '2 mikser',
    pumpNote: 'Sabit pompa',
    notes: 'Öğleden sonra devam',
  ));
  pours.add(PourRecord(
    id: '',
    projectId: p1.id,
    date: d(1),
    actualM3: 31.5,
    concreteClass: 'C25/30',
    location: 'Blok B — Perde',
    mixerNote: '3 mikser',
    pumpNote: 'Mobil pompa',
  ));
  pours.add(PourRecord(
    id: '',
    projectId: p1.id,
    date: d(2),
    actualM3: 54.0,
    concreteClass: 'C30/37',
    location: 'Blok B — Döşeme',
    mixerNote: '5 mikser',
    pumpNote: 'Sabit pompa',
  ));
  pours.add(PourRecord(
    id: '',
    projectId: p1.id,
    date: d(4),
    actualM3: 12.0,
    concreteClass: 'C16/20',
    location: 'Blok A — Grobeton',
    mixerNote: '1 mikser',
  ));

  // —— Proje 1: siparişler ——
  orders.add(ConcreteOrder(
    id: '',
    projectId: p1.id,
    orderDate: d(0),
    supplier: 'Akdeniz Hazır Beton',
    orderedM3: 70,
    deliveredM3: 20,
    waybillNo: 'IRS-7841',
    concreteClass: 'C30/37',
    status: OrderStatus.partial,
    notes: 'Kalan öğleden sonra',
  ));
  orders.add(ConcreteOrder(
    id: '',
    projectId: p1.id,
    orderDate: d(1),
    supplier: 'Akdeniz Hazır Beton',
    orderedM3: 32,
    deliveredM3: 32,
    waybillNo: 'IRS-7830',
    concreteClass: 'C25/30',
    status: OrderStatus.delivered,
  ));
  orders.add(ConcreteOrder(
    id: '',
    projectId: p1.id,
    orderDate: d(2),
    supplier: 'Marmara Beton',
    orderedM3: 55,
    deliveredM3: 55,
    waybillNo: 'IRS-2204',
    concreteClass: 'C30/37',
    status: OrderStatus.delivered,
  ));
  orders.add(ConcreteOrder(
    id: '',
    projectId: p1.id,
    orderDate: d(0),
    supplier: 'Marmara Beton',
    orderedM3: 22,
    deliveredM3: 0,
    waybillNo: '',
    concreteClass: 'C25/30',
    status: OrderStatus.open,
  ));

  // —— Proje 1: kalite ——
  quality.add(QualitySample(
    id: '',
    projectId: p1.id,
    sampleDate: d(1),
    sampleCode: 'N-R1-014',
    ageDays: 7,
    notes: '7 günlük sonuç bekleniyor',
  ));
  quality.add(QualitySample(
    id: '',
    projectId: p1.id,
    sampleDate: d(2),
    sampleCode: 'N-R1-013',
    ageDays: 28,
    notes: '28 günlük numune kürde',
  ));
  quality.add(QualitySample(
    id: '',
    projectId: p1.id,
    sampleDate: d(28),
    sampleCode: 'N-R1-001',
    ageDays: 28,
    strengthMpa: 38.2,
    slagNote: 'Cüruf katkılı',
    notes: 'Şartname üstü',
  ));
  quality.add(QualitySample(
    id: '',
    projectId: p1.id,
    sampleDate: d(14),
    sampleCode: 'N-R1-008',
    ageDays: 7,
    strengthMpa: 24.6,
  ));

  // —— Proje 2: özet örnek ——
  plans.add(PourPlan(
    id: '',
    projectId: p2.id,
    date: d(0),
    location: 'Otopark B1 radye',
    concreteClass: 'C35/45',
    plannedM3: 120,
    status: PourPlanStatus.planned,
  ));
  plans.add(PourPlan(
    id: '',
    projectId: p2.id,
    date: d(5),
    location: 'Otopark B2 radye',
    concreteClass: 'C35/45',
    plannedM3: 95,
    status: PourPlanStatus.completed,
  ));
  pours.add(PourRecord(
    id: '',
    projectId: p2.id,
    date: d(5),
    actualM3: 96.5,
    concreteClass: 'C35/45',
    location: 'Otopark B2 radye',
    mixerNote: '8 mikser',
    pumpNote: '2 sabit pompa',
  ));
  orders.add(ConcreteOrder(
    id: '',
    projectId: p2.id,
    orderDate: d(0),
    supplier: 'Ankara Beton Sanayi',
    orderedM3: 120,
    deliveredM3: 0,
    concreteClass: 'C35/45',
    status: OrderStatus.open,
  ));
  orders.add(ConcreteOrder(
    id: '',
    projectId: p2.id,
    orderDate: d(5),
    supplier: 'Ankara Beton Sanayi',
    orderedM3: 95,
    deliveredM3: 96.5,
    waybillNo: 'IRS-AN-441',
    concreteClass: 'C35/45',
    status: OrderStatus.delivered,
  ));
  quality.add(QualitySample(
    id: '',
    projectId: p2.id,
    sampleDate: d(5),
    sampleCode: 'N-AVM-003',
    ageDays: 7,
  ));
  quality.add(QualitySample(
    id: '',
    projectId: p2.id,
    sampleDate: d(35),
    sampleCode: 'N-AVM-001',
    ageDays: 28,
    strengthMpa: 42.1,
    slagNote: 'Yüksek cüruf oranı',
  ));

  settingsBox.put('demoSeedVersion', demoSeedVersion);
}
