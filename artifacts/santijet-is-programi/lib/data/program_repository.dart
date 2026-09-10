import 'dart:convert';

import 'package:hive/hive.dart';

import '../domain/program_item.dart';

const programBoxName = 'isprog_program_items';
const settingsBoxName = 'isprog_settings';
const licenseBoxName = 'isprog_license';

class ProgramRepository {
  ProgramRepository(this._box);
  final Box<String> _box;

  List<ProgramItem> readAll() {
    final items = _box.values
        .map(
          (raw) => ProgramItem.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        )
        .toList();
    items.sort((a, b) => a.startDate.compareTo(b.startDate));
    return items;
  }

  Future<void> save(ProgramItem item) =>
      _box.put(item.id, jsonEncode(item.toJson()));

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();

  /// İçe aktarılan faaliyetleri yazar. Aynı kimlikli satır varsa üzerine yazar.
  Future<void> saveAll(List<ProgramItem> items) =>
      _box.putAll({for (final item in items) item.id: jsonEncode(item.toJson())});

  /// Mevcut programı siler ve içe aktarılan listeyi tek kaynak yapar.
  Future<void> replaceAll(List<ProgramItem> items) async {
    await clear();
    await saveAll(items);
  }

  Future<void> replaceWithDemo({DateTime? today}) async {
    final now = _dateOnly(today ?? DateTime.now());
    await clear();
    for (final item in demoProgramItems(now)) {
      await save(item);
    }
  }
}

List<ProgramItem> demoProgramItems(DateTime today) {
  DateTime day(int offset) => today.add(Duration(days: offset));

  return [
    ProgramItem(
      id: 'demo-01',
      santiyeId: 'Merkez Şantiyesi',
      name: 'Hafriyat ve zemin tesviyesi',
      startDate: day(-30),
      endDate: day(-20),
      progress: 100,
      status: ProgramStatus.completed,
      responsible: 'Saha Ekibi',
    ),
    ProgramItem(
      id: 'demo-02',
      santiyeId: 'Merkez Şantiyesi',
      name: 'Temel altı grobeton',
      startDate: day(-19),
      endDate: day(-14),
      progress: 100,
      status: ProgramStatus.completed,
      responsible: 'Beton Ekibi',
    ),
    ProgramItem(
      id: 'demo-03',
      santiyeId: 'Merkez Şantiyesi',
      name: 'Radye temel donatısı',
      startDate: day(-12),
      endDate: day(-3),
      progress: 70,
      status: ProgramStatus.inProgress,
      responsible: 'Ahmet Usta',
      notes: 'B blok filizleri bekleniyor.',
    ),
    ProgramItem(
      id: 'demo-04',
      santiyeId: 'Merkez Şantiyesi',
      name: 'Perde kalıp imalatı',
      startDate: day(-8),
      endDate: day(3),
      progress: 45,
      status: ProgramStatus.inProgress,
      responsible: 'Kalıp Ekibi',
    ),
    ProgramItem(
      id: 'demo-05',
      santiyeId: 'Merkez Şantiyesi',
      name: 'Temel bohçalama yalıtımı',
      startDate: day(-10),
      endDate: day(-5),
      progress: 55,
      status: ProgramStatus.inProgress,
      responsible: 'Yalıtım Ekibi',
    ),
    ProgramItem(
      id: 'demo-06',
      santiyeId: 'Merkez Şantiyesi',
      name: 'Zemin kat kolonları',
      startDate: day(4),
      endDate: day(12),
      progress: 0,
      status: ProgramStatus.planned,
      responsible: 'Mehmet Usta',
    ),
    ProgramItem(
      id: 'demo-07',
      santiyeId: 'Merkez Şantiyesi',
      name: 'Zemin kat döşeme',
      startDate: day(13),
      endDate: day(22),
      progress: 0,
      status: ProgramStatus.planned,
      responsible: 'Kalıp Ekibi',
    ),
    ProgramItem(
      id: 'demo-08',
      santiyeId: 'Depo Şantiyesi',
      name: 'Çelik kolon montajı',
      startDate: day(-2),
      endDate: day(8),
      progress: 25,
      status: ProgramStatus.inProgress,
      responsible: 'Montaj Ekibi',
    ),
    ProgramItem(
      id: 'demo-09',
      santiyeId: 'Depo Şantiyesi',
      name: 'Çatı aşık montajı',
      startDate: day(9),
      endDate: day(16),
      progress: 0,
      status: ProgramStatus.planned,
      responsible: 'Montaj Ekibi',
    ),
    ProgramItem(
      id: 'demo-10',
      santiyeId: 'Depo Şantiyesi',
      name: 'Endüstriyel zemin betonu',
      startDate: day(17),
      endDate: day(24),
      progress: 0,
      status: ProgramStatus.planned,
      responsible: 'Beton Ekibi',
    ),
  ];
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
