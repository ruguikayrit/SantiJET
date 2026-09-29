import 'package:flutter/material.dart';

/// ŞantiJET Pro modülü. Eski uygulama adreslerine bağlanmaz.
class ProModule {
  const ProModule({
    required this.id,
    required this.label,
    required this.group,
    required this.summary,
    required this.icon,
  });

  final String id;
  final String label;
  final ProModuleGroup group;
  final String summary;
  final IconData icon;

  /// Mühendis yok. Çelik bu önizlemede yok; ileride eklenecek.
  static const catalog = <ProModule>[
    ProModule(
      id: 'saha',
      label: 'SAHA',
      group: ProModuleGroup.operasyon,
      summary: 'Puantaj, günlük rapor, imalat',
      icon: Icons.groups_outlined,
    ),
    ProModule(
      id: 'beton',
      label: 'BETON',
      group: ProModuleGroup.imalat,
      summary: 'Keşif, sipariş, döküm, test',
      icon: Icons.foundation_outlined,
    ),
    ProModule(
      id: 'demir',
      label: 'DEMİR',
      group: ProModuleGroup.imalat,
      summary: 'Sipariş, gelen demir, saha sayım, analiz',
      icon: Icons.architecture_outlined,
    ),
    ProModule(
      id: 'malzeme',
      label: 'MALZEME',
      group: ProModuleGroup.tedarik,
      summary: 'Keşif, talep, teslim, kütüphane',
      icon: Icons.inventory_2_outlined,
    ),
    ProModule(
      id: 'is-programi',
      label: 'İŞ PROGRAMI',
      group: ProModuleGroup.planlama,
      summary: 'Program, Gantt, özet',
      icon: Icons.account_tree_outlined,
    ),
    ProModule(
      id: 'maliyet',
      label: 'MALİYET',
      group: ProModuleGroup.finans,
      summary: 'Analiz, metraj, keşif, yaklaşık maliyet',
      icon: Icons.receipt_long_outlined,
    ),
    ProModule(
      id: 'kasa',
      label: 'KASA',
      group: ProModuleGroup.finans,
      summary: 'Kasa, hareketler, rapor',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  static ProModule byId(String id) =>
      catalog.firstWhere((module) => module.id == id);
}

enum ProModuleGroup {
  operasyon('OPERASYON'),
  imalat('İMALAT'),
  tedarik('TEDARİK'),
  planlama('PLANLAMA'),
  finans('FİNANS');

  const ProModuleGroup(this.label);
  final String label;
}
