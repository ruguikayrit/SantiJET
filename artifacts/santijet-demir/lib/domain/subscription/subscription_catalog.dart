import 'package:santijet_demir/domain/enums/subscription_plan.dart';

/// Abonelik paket kataloğu — fiyatlar tek yerden güncellenir.
class SubscriptionPackageInfo {
  const SubscriptionPackageInfo({
    required this.plan,
    required this.title,
    required this.subtitle,
    required this.monthlyPriceLabel,
    required this.features,
    required this.includesAnalysis,
    required this.includesPrediction,
    this.highlighted = false,
    this.badge,
  });

  final SubscriptionPlan plan;
  final String title;
  final String subtitle;
  final String monthlyPriceLabel;
  final List<String> features;
  final bool includesAnalysis;
  final bool includesPrediction;
  final bool highlighted;
  final String? badge;
}

abstract final class SubscriptionCatalog {
  static const demirTakip = SubscriptionPackageInfo(
    plan: SubscriptionPlan.demirTakip,
    title: 'Demir Takip',
    subtitle: 'Sipariş, teslimat, saha sayımı ve mukayese',
    monthlyPriceLabel: '990 TL/ay',
    includesAnalysis: false,
    includesPrediction: false,
    features: [
      'Otomatik metraj / keşif',
      'Demir sipariş ve takip',
      'Gelen demir / teslimat',
      'Saha sayımı',
      'Mukayese tablosu',
    ],
  );

  static const demirTakipAnaliz = SubscriptionPackageInfo(
    plan: SubscriptionPlan.demirTakipAnaliz,
    title: 'Demir Takip & Analiz & Tahmin',
    subtitle: 'Takip + fire analizi + tahmin motoru',
    monthlyPriceLabel: '2.990 TL/ay',
    includesAnalysis: true,
    includesPrediction: true,
    highlighted: true,
    badge: 'Önerilen',
    features: [
      'Demir Takip paketindeki her şey',
      'Hesap / Analiz / Rapor',
      'Fire analizi ve tahvil',
      'Demir tahmin motoru',
      'İş programı ve günlük puantaj',
    ],
  );

  static const List<SubscriptionPackageInfo> purchasable = [
    demirTakip,
    demirTakipAnaliz,
  ];

  static SubscriptionPackageInfo infoFor(SubscriptionPlan plan) {
    return switch (plan) {
      SubscriptionPlan.demirTakipAnaliz => demirTakipAnaliz,
      SubscriptionPlan.demirTakip => demirTakip,
      SubscriptionPlan.none => demirTakip,
    };
  }
}
