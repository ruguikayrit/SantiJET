import '../rebar_math.dart';
import '../regulation/regulation_catalog.dart';
import '../regulation/regulation_rule.dart';
import '../result/tahvil_check.dart';
import '../units.dart';

class CheckBuilder {
  CheckBuilder(this.catalog);

  final RegulationCatalog catalog;
  final checks = <TahvilCheck>[];
  final table = <TahvilTableRow>[];

  void add(TahvilCheck check) => checks.add(check);

  void row(TahvilTableRow row) => table.add(row);

  TahvilCheck compareAs({
    required double projectAs,
    required double newAs,
    required String unit,
  }) {
    final ok = Units.atLeast(newAs, projectAs);
    return TahvilCheck(
      id: 'as',
      title: 'Toplam As',
      rule: catalog.asNotLessThanProject,
      status: ok ? CheckStatus.passed : CheckStatus.failed,
      projectValue: '${RebarMath.formatArea(projectAs)} $unit',
      newValue: '${RebarMath.formatArea(newAs)} $unit',
      message: ok
          ? 'Yeni As ≥ proje As'
          : 'Yeni As proje As değerinden küçük',
    );
  }

  TahvilCheck cover({
    required double coverMm,
    required double minCoverMm,
    required RegulationRule rule,
  }) {
    final ok = Units.atLeast(coverMm, minCoverMm);
    return TahvilCheck(
      id: 'cover',
      title: 'Paspayı',
      rule: rule,
      status: ok ? CheckStatus.passed : CheckStatus.failed,
      projectValue: '${coverMm.toStringAsFixed(0)} mm',
      newValue: 'min ${minCoverMm.toStringAsFixed(0)} mm',
      message: ok
          ? 'Paspayı minimum değeri sağlıyor'
          : 'Paspayı ${minCoverMm.toStringAsFixed(0)} mm altına düşemez',
    );
  }

  TahvilCheck minRatio({
    required double newAsPerMeter,
    required double thicknessMm,
    required double minRatio,
    required RegulationRule rule,
  }) {
    final requiredAs = minRatio * catalog.referenceStripMm * thicknessMm;
    final ok = Units.atLeast(newAsPerMeter, requiredAs);
    return TahvilCheck(
      id: 'min_rebar',
      title: 'Minimum donatı',
      rule: rule,
      status: ok ? CheckStatus.passed : CheckStatus.failed,
      projectValue: 'ρmin ${RebarMath.formatRatioPercent(minRatio)}%',
      newValue: '${RebarMath.formatArea(newAsPerMeter)} mm²/m',
      message: ok
          ? 'Minimum donatı sağlanıyor (≥ ${RebarMath.formatArea(requiredAs)} mm²/m)'
          : 'Minimum donatı sağlanmıyor (gerekli ${RebarMath.formatArea(requiredAs)} mm²/m)',
    );
  }

  TahvilCheck maxSpacing({
    required double newSpacingMm,
    required double limitMm,
    required RegulationRule rule,
  }) {
    final ok = Units.atMost(newSpacingMm, limitMm);
    return TahvilCheck(
      id: 'max_spacing',
      title: 'Maksimum aralık',
      rule: rule,
      status: ok ? CheckStatus.passed : CheckStatus.failed,
      projectValue: '—',
      newValue: '${RebarMath.formatCm(newSpacingMm / 10)} cm',
      message: ok
          ? 'Aralık ≤ ${RebarMath.formatCm(limitMm / 10)} cm'
          : 'Aralık ${RebarMath.formatCm(limitMm / 10)} cm sınırını aşıyor',
    );
  }

  TahvilCheck engineer({
    required String id,
    required String title,
    required RegulationRule rule,
    required String message,
    String? projectValue,
    String? newValue,
  }) {
    return TahvilCheck(
      id: id,
      title: title,
      rule: rule,
      status: CheckStatus.engineerReview,
      projectValue: projectValue,
      newValue: newValue,
      message: message,
    );
  }

  TahvilCheck info({
    required String id,
    required String title,
    required RegulationRule rule,
    required String message,
    String? projectValue,
    String? newValue,
  }) {
    return TahvilCheck(
      id: id,
      title: title,
      rule: rule,
      status: CheckStatus.info,
      projectValue: projectValue,
      newValue: newValue,
      message: message,
    );
  }
}
