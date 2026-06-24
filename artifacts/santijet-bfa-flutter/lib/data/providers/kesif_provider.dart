import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/entities/poz_analiz.dart';

/// Keşif projeleri — Hive `kesif_projects` kutusunda kalıcıdır.
class KesifNotifier extends StateNotifier<List<KesifProject>> {
  KesifNotifier(this._box) : super(_read(_box));

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

  String createProject(String ad, {String aciklama = ''}) {
    final now = DateTime.now().toIso8601String();
    final project = KesifProject(
      id: IdGen.make('kp'),
      ad: ad.trim().isEmpty ? 'Yeni Keşif' : ad.trim(),
      aciklama: aciklama.trim(),
      satirlar: const [],
      olusturmaTarihi: now,
      guncellemeTarihi: now,
    );
    state = [project, ...state];
    _persist();
    return project.id;
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
