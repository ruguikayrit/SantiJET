import 'package:santijet_demir/domain/entities/analysis.dart';

AnalysisSummary getMockAnalysisSummary() {
  return const AnalysisSummary(
    healthScore: 92,
    totalSurvey: 3156,
    totalOrdered: 2890,
    totalDelivered: 2770,
    variance: -14,
    insights: [
      AiInsight(
        title: 'Ø16 Stok Riski',
        message: 'Beklenen stok 45t altına düştü. Acil sipariş önerilir.',
        colorValue: 0xFFEF4444,
        iconName: 'warning',
      ),
      AiInsight(
        title: 'Teslimat Performansı',
        message: 'Haftalık karşılama oranı %96 — hedefin üzerinde.',
        colorValue: 0xFF10B981,
        iconName: 'trending_up',
      ),
      AiInsight(
        title: 'Sapma Trendi',
        message: 'Perde bölgesinde -8.5t sapma. Sayım doğrulaması gerekli.',
        colorValue: 0xFFF59E0B,
        iconName: 'analytics',
      ),
      AiInsight(
        title: 'Tedarikçi Uyarısı',
        message: 'Erdemir performansı %72.7 — alternatif değerlendirin.',
        colorValue: 0xFFA855F7,
        iconName: 'local_shipping',
      ),
    ],
    diameterRates: [
      DiameterDeliveryRate(diameter: 8, rate: 98, variance: -1.2),
      DiameterDeliveryRate(diameter: 12, rate: 94, variance: -2.8),
      DiameterDeliveryRate(diameter: 16, rate: 89, variance: -14.0),
      DiameterDeliveryRate(diameter: 20, rate: 96, variance: -3.1),
      DiameterDeliveryRate(diameter: 22, rate: 91, variance: -5.4),
    ],
    varianceBars: [
      VarianceBarItem(label: 'Ø16 Perde', value: 14, status: 'critical'),
      VarianceBarItem(label: 'Ø22 Radye', value: 8.5, status: 'warning'),
      VarianceBarItem(label: 'Ø12 Döşeme', value: 3.2, status: 'normal'),
      VarianceBarItem(label: 'Ø20 Kolon', value: 2.1, status: 'normal'),
      VarianceBarItem(label: 'Ø14 Kiriş', value: 1.8, status: 'normal'),
    ],
    consumedDiameters: [
      ConsumedDiameterItem(diameter: 16, tonnage: 484, isTop: true),
      ConsumedDiameterItem(diameter: 20, tonnage: 415, isTop: false),
      ConsumedDiameterItem(diameter: 12, tonnage: 207, isTop: false),
      ConsumedDiameterItem(diameter: 22, tonnage: 198, isTop: false),
      ConsumedDiameterItem(diameter: 14, tonnage: 188, isTop: false),
    ],
  );
}

const supplierPerfBars = [
  ('Çolakoğlu', 99.7),
  ('Kardemir', 99.2),
  ('İsdemir', 97.0),
  ('Erdemir', 72.7),
];
