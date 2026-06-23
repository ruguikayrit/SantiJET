import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/id_gen.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Kullanıcı/kopya analizleri — Hive `user_analizleri` kutusunda saklanır.
class UserAnalizNotifier extends StateNotifier<List<PozAnaliz>> {
  UserAnalizNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'items';

  static List<PozAnaliz> _read(Box box) {
    final raw = box.get(_key);
    if (raw is! List) return const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(PozAnaliz.fromJson)
        .where((a) => a.id.isNotEmpty && a.kaynakTip != KaynakTip.sistem)
        .toList();
  }

  void _persist() {
    _box.put(_key, state.map((a) => a.toJson()).toList());
  }

  String add(PozAnaliz analiz) {
    final now = DateTime.now().toIso8601String();
    final item = analiz.copyWith(
      id: analiz.id.isEmpty ? IdGen.make('pa') : analiz.id,
      kaynakTip: analiz.kaynakTip == KaynakTip.sistem
          ? KaynakTip.kullanici
          : analiz.kaynakTip,
      olusturmaTarihi:
          analiz.olusturmaTarihi.isEmpty ? now : analiz.olusturmaTarihi,
      guncellemeTarihi: now,
    );
    state = [...state, item];
    _persist();
    return item.id;
  }

  void update(String id, PozAnaliz patch) {
    final now = DateTime.now().toIso8601String();
    state = [
      for (final a in state)
        if (a.id == id)
          patch.copyWith(
            id: id,
            kaynakTip: patch.kaynakTip == KaynakTip.sistem
                ? KaynakTip.kullanici
                : patch.kaynakTip,
            guncellemeTarihi: now,
          )
        else
          a,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((a) => a.id != id).toList();
    _persist();
  }

  void replaceAll(List<PozAnaliz> items) {
    state = items
        .where((a) => a.id.isNotEmpty && a.kaynakTip != KaynakTip.sistem)
        .toList();
    _persist();
  }

  void merge(List<PozAnaliz> items) {
    final byId = {for (final a in state) a.id: a};
    for (final a in items) {
      if (a.id.isEmpty || a.kaynakTip == KaynakTip.sistem) continue;
      byId[a.id] = a;
    }
    state = byId.values.toList();
    _persist();
  }

  PozAnaliz clone(PozAnaliz source, {String? yeniAd}) {
    final now = DateTime.now().toIso8601String();
    final copy = source.copyWith(
      id: IdGen.make('pa'),
      analizAdi: yeniAd ?? 'Kopya — ${source.analizAdi}',
      kaynakTip: KaynakTip.kopya,
      olusturmaTarihi: now,
      guncellemeTarihi: now,
      kalemler: [
        for (final k in source.kalemler) k.copyWith(id: IdGen.make('k')),
      ],
    );
    state = [...state, copy];
    _persist();
    return copy;
  }
}

/// Hive `user_analizleri` kutusu — bootstrap'ta açılır ve override edilir.
final userAnalizBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('userAnalizBoxProvider override edilmeli'),
);

final userAnalizProvider =
    StateNotifierProvider<UserAnalizNotifier, List<PozAnaliz>>(
  (ref) => UserAnalizNotifier(ref.watch(userAnalizBoxProvider)),
);
