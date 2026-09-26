import 'package:flutter/material.dart';

/// ŞantiJET Pro modülü. Ekranlar kaynak uygulamada kalır; kabuk yalnız açar.
class ProModule {
  const ProModule({
    required this.id,
    required this.label,
    required this.group,
    required this.summary,
    required this.path,
    required this.icon,
  });

  final String id;
  final String label;
  final ProModuleGroup group;
  final String summary;

  /// Yayın yolu. Kaynak uygulamanın Pages adresi değişmez.
  final String path;
  final IconData icon;

  String get route => '/$id';

  static const origin = String.fromEnvironment(
    'MODULE_ORIGIN',
    defaultValue: 'https://ruguikayrit.github.io/SantiJET',
  );

  String get url => '$origin$path';

  /// Mühendis yok. Çelik bu önizlemede yok; ileride eklenecek.
  static const catalog = <ProModule>[
    ProModule(
      id: 'saha',
      label: 'SAHA',
      group: ProModuleGroup.operasyon,
      summary: 'Puantaj, günlük rapor, imalat',
      path: '/puantaj/',
      icon: Icons.groups_outlined,
    ),
    ProModule(
      id: 'beton',
      label: 'BETON',
      group: ProModuleGroup.imalat,
      summary: 'Keşif, sipariş, döküm, test',
      path: '/beton/',
      icon: Icons.foundation_outlined,
    ),
    ProModule(
      id: 'demir',
      label: 'DEMİR',
      group: ProModuleGroup.imalat,
      summary: 'Sipariş, gelen demir, saha sayım, analiz',
      path: '/demir/',
      icon: Icons.architecture_outlined,
    ),
    ProModule(
      id: 'tahvil',
      label: 'TAHVİL',
      group: ProModuleGroup.imalat,
      summary: 'Saha, temel, kolon, kiriş, döşeme',
      path: '/tahvil/',
      icon: Icons.calculate_outlined,
    ),
    ProModule(
      id: 'malzeme',
      label: 'MALZEME',
      group: ProModuleGroup.tedarik,
      summary: 'Keşif, talep, teslim, kütüphane',
      path: '/malzeme/',
      icon: Icons.inventory_2_outlined,
    ),
    ProModule(
      id: 'is-programi',
      label: 'İŞ PROGRAMI',
      group: ProModuleGroup.planlama,
      summary: 'Program, Gantt, özet',
      path: '/is-programi/',
      icon: Icons.account_tree_outlined,
    ),
    ProModule(
      id: 'maliyet',
      label: 'MALİYET',
      group: ProModuleGroup.finans,
      summary: 'Analiz, metraj, keşif, yaklaşık maliyet',
      path: '/maliyet/',
      icon: Icons.receipt_long_outlined,
    ),
    ProModule(
      id: 'kasa',
      label: 'KASA',
      group: ProModuleGroup.finans,
      summary: 'Kasa, hareketler, rapor',
      path: '/kasa/',
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
