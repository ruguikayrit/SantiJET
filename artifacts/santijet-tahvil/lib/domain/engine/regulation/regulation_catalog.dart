import 'dart:math' as math;

import 'regulation_rule.dart';

/// TS 500 ve TBDY 2018 sınırları. Motor bu değerleri satır içine gömmemelidir.
class RegulationCatalog {
  const RegulationCatalog();

  static const ts500 = 'TS 500';
  static const tbdy2018 = 'TBDY 2018';

  double get foundationMinRatio => 0.002;
  double get slabMinRatio => 0.002;
  double get beamMinRatio => 0.002;
  double get columnMinRatio => 0.01;
  double get columnMaxRatio => 0.04;

  double get minClearSpacingMm => 25;
  double get foundationMinCoverMm => 40;
  double get columnMinCoverMm => 25;
  double get beamMinCoverMm => 25;
  double get slabMinCoverMm => 20;

  double get foundationMaxSpacingCapMm => 250;
  double get slabMaxSpacingCapMm => 250;
  double get columnMaxFaceSpacingMm => 250;

  int get columnMinBarCount => 4;
  int get maxBeamLayers => 2;
  int get beamMaxBarsHint => 12;
  int get columnMaxBarsHint => 20;

  double get minStirrupDiameterMm => 8;
  double get confinementStirrupCapMm => 150;
  double get middleStirrupCapMm => 200;
  double get beamCriticalStirrupCapMm => 150;

  double get referenceStripMm => 1000;

  double foundationMaxSpacingMm(double thicknessMm) =>
      math.min(2 * thicknessMm, foundationMaxSpacingCapMm);

  double slabMaxSpacingMm(double thicknessMm) =>
      math.min(2 * thicknessMm, slabMaxSpacingCapMm);

  double minClearForBar(double barDiameterMm) =>
      math.max(barDiameterMm, minClearSpacingMm);

  double minStirrupDiameterForLongBar(double longBarMm) =>
      math.max(minStirrupDiameterMm, longBarMm / 3);

  double confinementStirrupMaxMm({
    required double minSectionSideMm,
    required double longBarMm,
  }) {
    return math.min(
      math.min(minSectionSideMm / 3, confinementStirrupCapMm),
      8 * longBarMm,
    );
  }

  double middleStirrupMaxMm(double minSectionSideMm) =>
      math.min(minSectionSideMm, middleStirrupCapMm);

  double beamCriticalStirrupMaxMm({
    required double effectiveDepthMm,
    required double longBarMm,
  }) {
    return math.min(
      math.min(effectiveDepthMm / 4, 8 * longBarMm),
      beamCriticalStirrupCapMm,
    );
  }

  double beamMiddleStirrupMaxMm(double effectiveDepthMm) =>
      math.min(effectiveDepthMm / 2, middleStirrupCapMm);

  RegulationRule get asNotLessThanProject => const RegulationRule(
        ruleCode: 'AS-GE',
        standard: ts500,
        article: '7.1 / 8.1',
        description: 'Yeni donatı alanı proje alanından küçük olamaz',
      );

  RegulationRule get foundationMinRebar => const RegulationRule(
        ruleCode: 'FND-MIN',
        standard: ts500,
        article: '8.3',
        description: 'Temelde minimum donatı oranı',
      );

  RegulationRule get foundationMaxSpacing => const RegulationRule(
        ruleCode: 'FND-SMAX',
        standard: ts500,
        article: '8.2.5',
        description: 'Temel donatı aralığı üst sınırı',
      );

  RegulationRule get foundationCover => const RegulationRule(
        ruleCode: 'FND-C',
        standard: ts500,
        article: '7.7',
        description: 'Temel paspayı',
      );

  RegulationRule get foundationPlacement => const RegulationRule(
        ruleCode: 'FND-FIT',
        standard: ts500,
        article: '7.4.2',
        description: 'Donatıların temel kesitine sığması',
      );

  RegulationRule get foundationAnchorage => const RegulationRule(
        ruleCode: 'FND-ANC',
        standard: ts500,
        article: '9',
        description: 'Kenetlenme / bindirme — proje müellifi değerlendirmesi',
      );

  RegulationRule get slabMinRebar => const RegulationRule(
        ruleCode: 'SLB-MIN',
        standard: ts500,
        article: '8.1.3',
        description: 'Döşemede minimum donatı oranı',
      );

  RegulationRule get slabMaxSpacing => const RegulationRule(
        ruleCode: 'SLB-SMAX',
        standard: ts500,
        article: '8.2.5',
        description: 'Döşeme donatı aralığı üst sınırı',
      );

  RegulationRule get slabCover => const RegulationRule(
        ruleCode: 'SLB-C',
        standard: ts500,
        article: '7.7',
        description: 'Döşeme paspayı',
      );

  RegulationRule get slabPlacement => const RegulationRule(
        ruleCode: 'SLB-FIT',
        standard: ts500,
        article: '7.4.2',
        description: 'Döşeme kalınlığı ve fiziksel yerleşim',
      );

  RegulationRule get columnRatio => const RegulationRule(
        ruleCode: 'COL-RHO',
        standard: tbdy2018,
        article: '7.3.3',
        description: 'Kolon boyuna donatı oranı ρmin–ρmax',
      );

  RegulationRule get columnBarCount => const RegulationRule(
        ruleCode: 'COL-N',
        standard: ts500,
        article: '7.4.1',
        description: 'Kolonda en az dört köşe donatısı',
      );

  RegulationRule get columnSpacing => const RegulationRule(
        ruleCode: 'COL-S',
        standard: ts500,
        article: '7.4.2',
        description: 'Kolon boyuna donatı net aralığı',
      );

  RegulationRule get columnCover => const RegulationRule(
        ruleCode: 'COL-C',
        standard: ts500,
        article: '7.7',
        description: 'Kolon paspayı',
      );

  RegulationRule get columnPlacement => const RegulationRule(
        ruleCode: 'COL-FIT',
        standard: ts500,
        article: '7.4.2',
        description: 'Donatıların kolon kesitine yerleşmesi',
      );

  RegulationRule get columnLap => const RegulationRule(
        ruleCode: 'COL-LAP',
        standard: tbdy2018,
        article: '7.3.3 / 7.5',
        description: 'Bindirme bölgesi — kapasite ve deprem değerlendirmesi',
      );

  RegulationRule get columnSeismic => const RegulationRule(
        ruleCode: 'COL-SIS',
        standard: tbdy2018,
        article: '7.3',
        description:
            'Kolon tahvili kesme, eğilme ve kapasite tasarımı için müellif kontrolü',
      );

  RegulationRule get stirrupGeometry => const RegulationRule(
        ruleCode: 'STR-GEO',
        standard: tbdy2018,
        article: '7.3.4 / 7.4',
        description: 'Etriye çapı, aralığı ve kol sayısı',
      );

  RegulationRule get stirrupChange => const RegulationRule(
        ruleCode: 'STR-CHG',
        standard: tbdy2018,
        article: '7.3.4 / 7.4',
        description: 'Etriye / çiroz değişikliği otomatik uygun sayılmaz',
      );

  RegulationRule get beamMinRebar => const RegulationRule(
        ruleCode: 'BM-MIN',
        standard: ts500,
        article: '7.3',
        description: 'Kirişte minimum çekme donatısı',
      );

  RegulationRule get beamPlacement => const RegulationRule(
        ruleCode: 'BM-FIT',
        standard: ts500,
        article: '7.4.2',
        description: 'Kiriş genişliğinde donatı sırası ve net mesafe',
      );

  RegulationRule get beamCover => const RegulationRule(
        ruleCode: 'BM-C',
        standard: ts500,
        article: '7.7',
        description: 'Kiriş paspayı',
      );

  RegulationRule get beamSupport => const RegulationRule(
        ruleCode: 'BM-SUP',
        standard: tbdy2018,
        article: '7.4',
        description: 'Mesnet / birleşim bölgesi — müellif kontrolü',
      );

  RegulationRule get beamStirrup => const RegulationRule(
        ruleCode: 'BM-STR',
        standard: tbdy2018,
        article: '7.4',
        description: 'Kiriş etriyesi kritik ve orta bölgede ayrı değerlendirilir',
      );
}
