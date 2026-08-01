import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/id_gen.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_discovery.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/concrete_pour.dart';
import '../../domain/entities/metraj_variance_note.dart';
import '../../domain/entities/mixer_entry.dart';
import '../../domain/entities/project.dart';

final projectsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('projectsBoxProvider override edilmeli'),
);

final discoveryBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('discoveryBoxProvider override edilmeli'),
);

final poursBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('poursBoxProvider override edilmeli'),
);

final ordersBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('ordersBoxProvider override edilmeli'),
);

final varianceBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('varianceBoxProvider override edilmeli'),
);

/// Aktif proje kimliği (Hive settings kutusu üzerinden).
class ActiveProjectNotifier extends StateNotifier<String?> {
  ActiveProjectNotifier(this._settingsBox) : super(_read(_settingsBox));

  final Box _settingsBox;
  static const _key = 'activeProjectId';

  static String? _read(Box box) => box.get(_key) as String?;

  void set(String? id) {
    state = id;
    if (id == null) {
      _settingsBox.delete(_key);
    } else {
      _settingsBox.put(_key, id);
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
      return decoded
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
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
  static const _key = 'items';

  static List<Project> _load(Box box) =>
      _readList(box, _key).map(Project.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  Project add({required String name, String code = '', String company = ''}) {
    final project = Project(
      id: IdGen.make('prj'),
      name: name.trim(),
      code: code.trim(),
      company: company.trim(),
      createdAt: DateTime.now(),
    );
    state = [...state, project];
    _persist();
    return project;
  }

  void update(Project project) {
    state = [
      for (final p in state)
        if (p.id == project.id) project else p,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  void replaceAll(List<Project> items) {
    state = List<Project>.from(items);
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

class DiscoveryNotifier extends StateNotifier<List<ConcreteDiscoveryItem>> {
  DiscoveryNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<ConcreteDiscoveryItem> _load(Box box) =>
      _readList(box, _key).map(ConcreteDiscoveryItem.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void add(ConcreteDiscoveryItem draft) {
    state = [...state, draft.copyWith(id: IdGen.make('kes'))];
    _persist();
  }

  void update(ConcreteDiscoveryItem item) {
    state = [
      for (final e in state)
        if (e.id == item.id) item else e,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void replaceAll(List<ConcreteDiscoveryItem> items) {
    state = List<ConcreteDiscoveryItem>.from(items);
    _persist();
  }
}

final discoveryProvider =
    StateNotifierProvider<DiscoveryNotifier, List<ConcreteDiscoveryItem>>(
        (ref) {
  return DiscoveryNotifier(ref.watch(discoveryBoxProvider));
});

class PoursNotifier extends StateNotifier<List<ConcretePour>> {
  PoursNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<ConcretePour> _load(Box box) =>
      _readList(box, _key).map(ConcretePour.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void add(ConcretePour draft) {
    state = [...state, draft.copyWith(id: IdGen.make('dok'))];
    _persist();
  }

  void update(ConcretePour item) {
    state = [
      for (final e in state)
        if (e.id == item.id) item else e,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void replaceAll(List<ConcretePour> items) {
    state = List<ConcretePour>.from(items);
    _persist();
  }
}

final poursProvider =
    StateNotifierProvider<PoursNotifier, List<ConcretePour>>((ref) {
  return PoursNotifier(ref.watch(poursBoxProvider));
});

class OrdersNotifier extends StateNotifier<List<ConcreteOrder>> {
  OrdersNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<ConcreteOrder> _load(Box box) =>
      _readList(box, _key).map(ConcreteOrder.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void add(ConcreteOrder draft) {
    state = [...state, draft.copyWith(id: IdGen.make('sip'))];
    _persist();
  }

  void update(ConcreteOrder item) {
    state = [
      for (final e in state)
        if (e.id == item.id) item else e,
    ];
    _persist();
  }

  void markShared(String id) {
    state = [
      for (final e in state)
        if (e.id == id) e.copyWith(sharedViaWhatsApp: true) else e,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void replaceAll(List<ConcreteOrder> items) {
    state = List<ConcreteOrder>.from(items);
    _persist();
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<ConcreteOrder>>((ref) {
  return OrdersNotifier(ref.watch(ordersBoxProvider));
});

class VarianceNotifier extends StateNotifier<List<MetrajVarianceNote>> {
  VarianceNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<MetrajVarianceNote> _load(Box box) =>
      _readList(box, _key).map(MetrajVarianceNote.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void add(MetrajVarianceNote draft) {
    state = [...state, draft.copyWith(id: IdGen.make('fark'))];
    _persist();
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void replaceAll(List<MetrajVarianceNote> items) {
    state = List<MetrajVarianceNote>.from(items);
    _persist();
  }
}

final varianceProvider =
    StateNotifierProvider<VarianceNotifier, List<MetrajVarianceNote>>((ref) {
  return VarianceNotifier(ref.watch(varianceBoxProvider));
});

final activeDiscoveryProvider = Provider<List<ConcreteDiscoveryItem>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(discoveryProvider);
  if (project == null) return const [];
  final list = all.where((e) => e.projectId == project.id).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return list;
});

final activePoursProvider = Provider<List<ConcretePour>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(poursProvider);
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
    ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
  return list;
});

final activeVarianceProvider = Provider<List<MetrajVarianceNote>>((ref) {
  final project = ref.watch(activeProjectProvider);
  final all = ref.watch(varianceProvider);
  if (project == null) return const [];
  return all.where((e) => e.projectId == project.id).toList();
});

final todayPoursProvider = Provider<List<ConcretePour>>((ref) {
  final today = AppDate.format(AppDate.today());
  return ref.watch(activePoursProvider).where((p) => p.date == today).toList();
});

final projectProgressProvider = Provider<({
  double planned,
  double poured,
  double ordered,
  double progressPct,
  double orderGap,
  double remaining,
})>((ref) {
  final discovery = ref.watch(activeDiscoveryProvider);
  final pours = ref.watch(activePoursProvider);
  final orders = ref.watch(activeOrdersProvider);
  final planned = BetonProgress.sumPlanned(discovery);
  final poured = BetonProgress.sumPoured(pours);
  final ordered = BetonProgress.sumOrdered(orders);
  return (
    planned: planned,
    poured: poured,
    ordered: ordered,
    progressPct: BetonProgress.progressPercent(
      plannedM3: planned,
      pouredM3: poured,
    ),
    orderGap: BetonProgress.orderGap(orderedM3: ordered, pouredM3: poured),
    remaining: BetonProgress.remaining(plannedM3: planned, pouredM3: poured),
  );
});

final elementProgressProvider = Provider<List<ElementProgressRow>>((ref) {
  final discovery = ref.watch(activeDiscoveryProvider);
  final pours = ref.watch(activePoursProvider);
  final pouredByElement = <String, double>{};
  for (final p in pours) {
    final key = p.elementName.trim().isEmpty ? 'Diğer' : p.elementName.trim();
    pouredByElement[key] = (pouredByElement[key] ?? 0) + p.volumeM3;
  }

  final rows = <ElementProgressRow>[
    for (final d in discovery)
      ElementProgressRow(
        elementName: d.elementName,
        plannedM3: d.plannedM3,
        pouredM3: pouredByElement[d.elementName] ?? 0,
        location: d.location,
        concreteClass: d.concreteClass,
      ),
  ];

  // Keşifte olmayan ama dökülmüş elementler
  for (final entry in pouredByElement.entries) {
    if (discovery.any((d) => d.elementName == entry.key)) continue;
    rows.add(
      ElementProgressRow(
        elementName: entry.key,
        plannedM3: 0,
        pouredM3: entry.value,
      ),
    );
  }
  return rows;
});

/// İlk açılışta örnek proje + veri tohumu.
void seedDemoIfEmpty({
  required ProjectsNotifier projects,
  required DiscoveryNotifier discovery,
  required PoursNotifier pours,
  required OrdersNotifier orders,
  required VarianceNotifier variance,
  required ActiveProjectNotifier active,
}) {
  if (projects.state.isNotEmpty) return;

  final project = projects.add(
    name: 'Merkez Ofis Blok A',
    code: 'MOA-2026',
    company: 'ŞantiJET Yapı',
  );
  active.set(project.id);

  discovery.replaceAll([
    ConcreteDiscoveryItem(
      id: IdGen.make('kes'),
      projectId: project.id,
      elementName: 'Temel Radye',
      plannedM3: 420,
      location: 'Blok A · Kot -3.20',
      concreteClass: 'C35/45',
      sortOrder: 0,
    ),
    ConcreteDiscoveryItem(
      id: IdGen.make('kes'),
      projectId: project.id,
      elementName: 'Perde Duvar B1',
      plannedM3: 180,
      location: 'Blok A · Bodrum',
      concreteClass: 'C30/37',
      sortOrder: 1,
    ),
    ConcreteDiscoveryItem(
      id: IdGen.make('kes'),
      projectId: project.id,
      elementName: 'Döşeme K1',
      plannedM3: 95,
      location: 'Blok A · Kat 1',
      concreteClass: 'C30/37',
      sortOrder: 2,
    ),
  ]);

  final today = AppDate.format(AppDate.today());
  final yesterday = AppDate.format(AppDate.today().subtract(const Duration(days: 1)));

  pours.replaceAll([
    ConcretePour(
      id: IdGen.make('dok'),
      projectId: project.id,
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
      pourStart: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      pourEnd: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    ConcretePour(
      id: IdGen.make('dok'),
      projectId: project.id,
      date: today,
      volumeM3: 42,
      elementName: 'Perde Duvar B1',
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
      pourStart: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ]);

  final orderPerde = ConcreteOrder(
    id: IdGen.make('sip'),
    projectId: project.id,
    plannedDate: today,
    plannedM3: 48,
    elementName: 'Perde Duvar B1',
    block: 'A Blok',
    floor: 'Bodrum Kat',
    concreteClass: 'C30/37',
    supplier: 'Akdeniz Beton',
    plannedStartHour: '07:30',
    slumpCm: 14,
    pumpCount: 1,
    pumpType: 'Mobil',
    notes: 'Pompa + 2 mikser peş peşe',
  );
  final orderDoseme = ConcreteOrder(
    id: IdGen.make('sip'),
    projectId: project.id,
    plannedDate: AppDate.format(AppDate.today().add(const Duration(days: 1))),
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
  );

  orders.replaceAll([orderPerde, orderDoseme]);

  // Bugünkü dökümü siparişe bağla
  final linkedPours = pours.state.map((p) {
    if (p.date == today && p.elementName == orderPerde.elementName) {
      return p.copyWith(orderId: orderPerde.id);
    }
    return p;
  }).toList();
  pours.replaceAll(linkedPours);

  variance.replaceAll([
    MetrajVarianceNote(
      id: IdGen.make('fark'),
      projectId: project.id,
      date: yesterday,
      plannedM3: 80,
      actualM3: 86,
      reason: 'Kalıp şişmesi / ek dolgu',
      elementName: 'Temel Radye',
      detail: 'Kenar kalıplarında 6 m³ ek döküm yapıldı.',
    ),
  ]);
}
