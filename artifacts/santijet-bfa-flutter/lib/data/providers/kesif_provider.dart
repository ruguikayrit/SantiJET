import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../core/utils/id_gen.dart';
import '../../core/utils/project_code_generator.dart';
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/entities/poz_analiz.dart';

/// Keşif projeleri — Hive `kesif_projects` kutusunda kalıcıdır.
class KesifNotifier extends StateNotifier<List<KesifProject>> {
  KesifNotifier(this._box) : super(_read(_box)) {
    _ensureProjectCodes();
  }

  final Box _box;
  static const _key = 'items';

  static List<KesifProject> _read(Box box) {
    final raw = box.get(_key);
    if (raw is! List) return const [];
    final items = raw
        .whereType<Map<dynamic, dynamic>>()
        .map(KesifProject.fromJson)
        .where((p) => p.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.guncellemeTarihi.compareTo(a.guncellemeTarihi));
    return items;
  }

  void _persist() {
    _box.put(_key, state.map((p) => p.toJson()).toList());
  }

  void _ensureProjectCodes() {
    var changed = false;
    final used = <String>{};
    final next = <KesifProject>[];
    for (final p in state) {
      var kod = p.kod.trim().toUpperCase();
      if (kod.isEmpty || used.contains(kod)) {
        kod = _uniqueCode(used);
        changed = true;
      }
      used.add(kod);
      next.add(kod == p.kod ? p : p.copyWith(kod: kod));
    }
    if (changed) {
      state = next;
      _persist();
    }
  }

  String _uniqueCode([Set<String>? used]) {
    final taken = used ?? state.map((e) => e.kod.toUpperCase()).toSet();
    for (var i = 0; i < 20; i++) {
      final code = ProjectCodeGenerator.generate();
      if (!taken.contains(code)) return code;
    }
    return ProjectCodeGenerator.generate();
  }

  String createProject(
    String ad, {
    String aciklama = '',
    String konum = '',
    String? kod,
  }) {
    final now = DateTime.now().toIso8601String();
    final project = KesifProject(
      id: IdGen.make('kp'),
      ad: ad.trim().isEmpty ? 'Yeni Proje' : ad.trim(),
      aciklama: aciklama.trim(),
      konum: konum.trim(),
      kod: (kod ?? _uniqueCode()).trim().toUpperCase(),
      satirlar: const [],
      olusturmaTarihi: now,
      guncellemeTarihi: now,
    );
    state = [project, ...state];
    _persist();
    return project.id;
  }

  void updateProject(KesifProject project) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == project.id)
          project.copyWith(guncellemeTarihi: now)
        else
          p,
    ];
    _persist();
  }

  KesifProject? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  void deleteProject(String id) {
    state = state.where((p) => p.id != id).toList();
    _persist();
  }

  void replaceAll(List<KesifProject> projects) {
    state = [...projects]
      ..sort((a, b) => b.guncellemeTarihi.compareTo(a.guncellemeTarihi));
    _persist();
  }

  void merge(List<KesifProject> projects) {
    final byId = {for (final p in state) p.id: p};
    for (final p in projects) {
      if (p.id.isEmpty) continue;
      byId[p.id] = p;
    }
    state = byId.values.toList()
      ..sort((a, b) => b.guncellemeTarihi.compareTo(a.guncellemeTarihi));
    _persist();
  }

  void addSatir(String projectId, PozAnaliz analiz, double miktar) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: [...p.satirlar, buildKesifSatiri(analiz, miktar)],
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }

  void updateMiktar(String projectId, String satirId, double miktar) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: [
              for (final s in p.satirlar)
                if (s.id == satirId)
                  s.copyWith(
                    miktar: miktar,
                    tutar: AnalizHesap.satirTutar(miktar, s.birimFiyati),
                    // Manuel miktar cetvel kalemlerinin yerini alır.
                    metrajKalemleri: const [],
                  )
                else
                  s,
            ],
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }

  void upsertMetrajKalemi(
    String projectId,
    String satirId,
    MetrajKalemi kalem,
  ) {
    final now = DateTime.now().toIso8601String();
    final normalized = kalem.withHesap();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: [
              for (final s in p.satirlar)
                if (s.id == satirId)
                  _withKalem(s, normalized)
                else
                  s,
            ],
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }

  static KesifSatiri _withKalem(KesifSatiri s, MetrajKalemi normalized) {
    final exists = s.metrajKalemleri.any((k) => k.id == normalized.id);
    final next = exists
        ? [
            for (final k in s.metrajKalemleri)
              if (k.id == normalized.id) normalized else k,
          ]
        : [...s.metrajKalemleri, normalized];
    return s.copyWith(metrajKalemleri: next).withMetrajRollup();
  }

  void removeMetrajKalemi(
    String projectId,
    String satirId,
    String kalemId,
  ) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: [
              for (final s in p.satirlar)
                if (s.id == satirId)
                  s
                      .copyWith(
                        metrajKalemleri: s.metrajKalemleri
                            .where((k) => k.id != kalemId)
                            .toList(),
                      )
                      .withMetrajRollup()
                else
                  s,
            ],
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }

  void updateMetrajNotu(String projectId, String satirId, String notu) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: [
              for (final s in p.satirlar)
                if (s.id == satirId)
                  s.copyWith(metrajNotu: notu.trim())
                else
                  s,
            ],
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }

  void updateBirimFiyat(String projectId, String satirId, double birimFiyati) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: [
              for (final s in p.satirlar)
                if (s.id == satirId)
                  s.copyWith(
                    birimFiyati: birimFiyati,
                    tutar: AnalizHesap.satirTutar(s.miktar, birimFiyati),
                    fiyatKaynagi: KesifFiyatKaynagi.manuel,
                  )
                else
                  s,
            ],
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }

  void removeSatir(String projectId, String satirId) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: p.satirlar.where((s) => s.id != satirId).toList(),
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }

  void importSatirlar(
    String projectId,
    List<({PozAnaliz analiz, double miktar})> items,
  ) {
    if (items.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            satirlar: [
              ...p.satirlar,
              for (final item in items)
                buildKesifSatiri(item.analiz, item.miktar),
            ],
            guncellemeTarihi: now,
          )
        else
          p,
    ];
    _persist();
  }
}

/// Hive `kesif_projects` kutusu — bootstrap'ta açılır ve override edilir.
final kesifBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('kesifBoxProvider override edilmeli'),
);

final kesifProvider = StateNotifierProvider<KesifNotifier, List<KesifProject>>(
  (ref) => KesifNotifier(ref.watch(kesifBoxProvider)),
);

/// Aktif proje (keşif) — Ayarlar kutusu + Projelerim.
class ActiveKesifIdNotifier extends StateNotifier<String?> {
  ActiveKesifIdNotifier(this._box) : super(_box.get(_key) as String?);

  final Box _box;
  static const _key = 'activeKesifId';

  void set(String? id) {
    state = id;
    if (id == null || id.isEmpty) {
      _box.delete(_key);
    } else {
      _box.put(_key, id);
    }
  }
}

final activeKesifIdProvider =
    StateNotifierProvider<ActiveKesifIdNotifier, String?>(
  (ref) => ActiveKesifIdNotifier(ref.watch(settingsBoxProvider)),
);

/// Aktif keşif projesi — id geçersizse listedeki ilk proje.
final activeKesifProvider = Provider<KesifProject?>((ref) {
  final list = ref.watch(kesifProvider);
  if (list.isEmpty) return null;
  final id = ref.watch(activeKesifIdProvider);
  if (id != null) {
    for (final p in list) {
      if (p.id == id) return p;
    }
  }
  return list.first;
});
