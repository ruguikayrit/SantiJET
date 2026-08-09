import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/id_gen.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/request_status.dart';

final projectsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('projectsBoxProvider override edilmeli'),
);

final kesifBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('kesifBoxProvider override edilmeli'),
);

final requestsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('requestsBoxProvider override edilmeli'),
);

final quotesBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('quotesBoxProvider override edilmeli'),
);

final deliveriesBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('deliveriesBoxProvider override edilmeli'),
);

final libraryBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('libraryBoxProvider override edilmeli'),
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

  void clear() {
    state = const [];
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

class KesifNotifier extends StateNotifier<List<KesifSnapshot>> {
  KesifNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<KesifSnapshot> _load(Box box) =>
      _readList(box, _key).map(KesifSnapshot.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void upsert(KesifSnapshot snapshot) {
    final exists = state.any((e) => e.id == snapshot.id);
    state = exists
        ? [
            for (final e in state)
              if (e.id == snapshot.id) snapshot else e,
          ]
        : [...state, snapshot];
    _persist();
  }

  void replaceAll(List<KesifSnapshot> items) {
    state = List<KesifSnapshot>.from(items);
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final kesifProvider =
    StateNotifierProvider<KesifNotifier, List<KesifSnapshot>>((ref) {
  return KesifNotifier(ref.watch(kesifBoxProvider));
});

final activeKesifProvider = Provider<KesifSnapshot?>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return null;
  final items = ref.watch(kesifProvider);
  for (final k in items) {
    if (k.projectId == project.id) return k;
  }
  return null;
});

class RequestsNotifier extends StateNotifier<List<MaterialRequest>> {
  RequestsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<MaterialRequest> _load(Box box) =>
      _readList(box, _key).map(MaterialRequest.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  MaterialRequest add(MaterialRequest request) {
    state = [...state, request];
    _persist();
    return request;
  }

  void update(MaterialRequest request) {
    state = [
      for (final r in state)
        if (r.id == request.id) request else r,
    ];
    _persist();
  }

  void advanceStatus(String id) {
    state = [
      for (final r in state)
        if (r.id == id)
          r.copyWith(status: r.status.nextStatus ?? r.status)
        else
          r,
    ];
    _persist();
  }

  void cancel(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: RequestStatus.kapandi) else r,
    ];
    _persist();
  }

  void replaceAll(List<MaterialRequest> items) {
    state = List<MaterialRequest>.from(items);
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final requestsProvider =
    StateNotifierProvider<RequestsNotifier, List<MaterialRequest>>((ref) {
  return RequestsNotifier(ref.watch(requestsBoxProvider));
});

final activeRequestsProvider = Provider<List<MaterialRequest>>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return const [];
  return ref
      .watch(requestsProvider)
      .where((r) => r.projectId == project.id)
      .toList();
});

class QuotesNotifier extends StateNotifier<List<QuoteRound>> {
  QuotesNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<QuoteRound> _load(Box box) =>
      _readList(box, _key).map(QuoteRound.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void upsert(QuoteRound round) {
    final exists = state.any((e) => e.id == round.id);
    state = exists
        ? [
            for (final e in state)
              if (e.id == round.id) round else e,
          ]
        : [...state, round];
    _persist();
  }

  void replaceAll(List<QuoteRound> items) {
    state = List<QuoteRound>.from(items);
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final quotesProvider =
    StateNotifierProvider<QuotesNotifier, List<QuoteRound>>((ref) {
  return QuotesNotifier(ref.watch(quotesBoxProvider));
});

final activeQuoteRoundsProvider = Provider<List<QuoteRound>>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return const [];
  return ref
      .watch(quotesProvider)
      .where((q) => q.projectId == project.id)
      .toList();
});

class DeliveriesNotifier extends StateNotifier<List<Delivery>> {
  DeliveriesNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<Delivery> _load(Box box) =>
      _readList(box, _key).map(Delivery.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void upsert(Delivery delivery) {
    final exists = state.any((e) => e.id == delivery.id);
    state = exists
        ? [
            for (final e in state)
              if (e.id == delivery.id) delivery else e,
          ]
        : [...state, delivery];
    _persist();
  }

  void replaceAll(List<Delivery> items) {
    state = List<Delivery>.from(items);
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final deliveriesProvider =
    StateNotifierProvider<DeliveriesNotifier, List<Delivery>>((ref) {
  return DeliveriesNotifier(ref.watch(deliveriesBoxProvider));
});

final activeDeliveriesProvider = Provider<List<Delivery>>((ref) {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return const [];
  return ref
      .watch(deliveriesProvider)
      .where((d) => d.projectId == project.id)
      .toList();
});

class LibraryNotifier extends StateNotifier<List<TechSheet>> {
  LibraryNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'items';

  static List<TechSheet> _load(Box box) =>
      _readList(box, _key).map(TechSheet.fromJson).toList();

  void _persist() =>
      _writeList(_box, _key, state.map((e) => e.toJson()).toList());

  void upsert(TechSheet sheet) {
    final exists = state.any((e) => e.id == sheet.id);
    state = exists
        ? [
            for (final e in state)
              if (e.id == sheet.id) sheet else e,
          ]
        : [...state, sheet];
    _persist();
  }

  void replaceAll(List<TechSheet> items) {
    state = List<TechSheet>.from(items);
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, List<TechSheet>>((ref) {
  return LibraryNotifier(ref.watch(libraryBoxProvider));
});

/// Ana sayfa KPI özeti.
class HomeKpis {
  const HomeKpis({
    required this.openRequests,
    required this.pendingDeliveries,
    required this.quoteRounds,
    required this.libraryCount,
  });

  final int openRequests;
  final int pendingDeliveries;
  final int quoteRounds;
  final int libraryCount;
}

final homeKpisProvider = Provider<HomeKpis>((ref) {
  final requests = ref.watch(activeRequestsProvider);
  final deliveries = ref.watch(activeDeliveriesProvider);
  final rounds = ref.watch(activeQuoteRoundsProvider);
  final library = ref.watch(libraryProvider);

  final open = requests
      .where((r) => r.status != RequestStatus.kapandi)
      .length;
  final pending = requests
      .where(
        (r) =>
            r.status == RequestStatus.siparis ||
            r.status == RequestStatus.kismi,
      )
      .length;

  return HomeKpis(
    openRequests: open,
    pendingDeliveries: pending > 0 ? pending : deliveries.length,
    quoteRounds: rounds.length,
    libraryCount: library.length,
  );
});

/// Tüm yerel veriyi temizler (ayarlar hariç tema).
void clearAllMalzemeData(WidgetRef ref) {
  ref.read(projectsProvider.notifier).clear();
  ref.read(kesifProvider.notifier).clear();
  ref.read(requestsProvider.notifier).clear();
  ref.read(quotesProvider.notifier).clear();
  ref.read(deliveriesProvider.notifier).clear();
  ref.read(libraryProvider.notifier).clear();
  ref.read(activeProjectIdProvider.notifier).set(null);
}
