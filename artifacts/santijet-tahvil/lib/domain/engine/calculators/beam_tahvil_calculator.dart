import '../inputs/element_inputs.dart';
import '../placement/placement_calculator.dart';
import '../rebar_math.dart';
import '../regulation/regulation_catalog.dart';
import '../result/tahvil_check.dart';
import '../tahvil_element.dart';
import '../units.dart';
import 'check_helpers.dart';

class BeamTahvilCalculator {
  const BeamTahvilCalculator({this.catalog = const RegulationCatalog()});

  final RegulationCatalog catalog;

  TahvilResult evaluate(BeamTahvilInput input) {
    final error = _validate(input);
    if (error != null) return TahvilResult.invalid(error);

    final projectAs = RebarMath.totalAreaMm2(
      diameterMm: input.projectDiameterMm.toDouble(),
      count: input.projectCount,
    );
    final newAs = RebarMath.totalAreaMm2(
      diameterMm: input.newDiameterMm.toDouble(),
      count: input.newCount,
    );
    final d = input.heightMm - input.coverMm - input.newStirrupDiameterMm -
        input.newDiameterMm / 2;
    final minAs = catalog.beamMinRatio * input.widthMm * (d > 0 ? d : input.heightMm);

    final b = CheckBuilder(catalog);
    final asCheck = b.compareAs(projectAs: projectAs, newAs: newAs, unit: 'mm²');
    b.add(asCheck);

    final minOk = Units.atLeast(newAs, minAs);
    b.add(
      TahvilCheck(
        id: 'min_rebar',
        title: 'Minimum donatı',
        rule: catalog.beamMinRebar,
        status: minOk ? CheckStatus.passed : CheckStatus.failed,
        projectValue: input.region.label,
        newValue: '${RebarMath.formatArea(minAs)} mm²',
        message: minOk
            ? '${input.region.label} için minimum donatı sağlanıyor'
            : '${input.region.label} için minimum donatı sağlanmıyor',
      ),
    );

    final coverCheck = b.cover(
      coverMm: input.coverMm,
      minCoverMm: catalog.beamMinCoverMm,
      rule: catalog.beamCover,
    );
    b.add(coverCheck);

    final fit = PlacementCalculator.beamFit(
      widthMm: input.widthMm,
      heightMm: input.heightMm,
      coverMm: input.coverMm,
      stirrupDiameterMm: input.newStirrupDiameterMm.toDouble(),
      barDiameterMm: input.newDiameterMm.toDouble(),
      count: input.newCount,
      catalog: catalog,
    );
    b.add(
      TahvilCheck(
        id: 'placement',
        title: 'Fiziksel yerleşim',
        rule: catalog.beamPlacement,
        status: fit.fits ? CheckStatus.passed : CheckStatus.failed,
        projectValue: '${input.widthMm.toStringAsFixed(0)} mm',
        newValue: '${fit.layers} sıra · max ${fit.maxPerLayer} ad/sıra',
        message: fit.fits
            ? 'Donatılar kiriş genişliğine sığıyor'
            : 'Yeni donatı fiziksel olarak kirişe sığmıyor',
      ),
    );

    _addStirrupChecks(b, input, d);

    if (input.region.requiresEngineerReview) {
      b.add(
        b.engineer(
          id: 'region',
          title: input.region.label,
          rule: catalog.beamSupport,
          message:
              '${input.region.label} tahvili kolon-kiriş birleşimi, kenetlenme '
              've kapasite tasarımı için müellif kontrolü gerektirir. '
              'Sonuç diğer bölgelere aktarılmaz.',
        ),
      );
    }

    b.add(
      b.info(
        id: 'weight',
        title: 'Çelik ağırlığı (bilgi)',
        rule: catalog.asNotLessThanProject,
        projectValue:
            '${RebarMath.kgPerMeter(input.projectDiameterMm).toStringAsFixed(3)} kg/m',
        newValue:
            '${RebarMath.kgPerMeter(input.newDiameterMm).toStringAsFixed(3)} kg/m',
        message: 'kg eşitliği tahvil kararı değildir.',
      ),
    );

    b.row(TahvilTableRow(
      parameter: 'Donatı çapı',
      project: 'Ø${input.projectDiameterMm}',
      replacement: 'Ø${input.newDiameterMm}',
      mark: '—',
    ));
    b.row(TahvilTableRow(
      parameter: 'Donatı adedi',
      project: '${input.projectCount}',
      replacement: '${input.newCount}',
      mark: '✓',
    ));
    b.row(TahvilTableRow(
      parameter: 'Toplam As',
      project: '${RebarMath.formatArea(projectAs)} mm²',
      replacement: '${RebarMath.formatArea(newAs)} mm²',
      mark: asCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Minimum donatı',
      mark: minOk ? CheckStatus.passed.mark : CheckStatus.failed.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Paspayı',
      project: '${input.coverMm.toStringAsFixed(0)} mm',
      mark: coverCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Fiziksel yerleşim',
      mark: fit.fits ? CheckStatus.passed.mark : CheckStatus.failed.mark,
    ));

    return TahvilResult(
      verdict: verdictFromChecks(b.checks),
      checks: b.checks,
      table: b.table,
      projectAs: projectAs,
      newAs: newAs,
      asUnit: 'mm²',
      projectLine: '${input.projectCount}×Ø${input.projectDiameterMm}',
      newLine: '${input.newCount}×Ø${input.newDiameterMm}',
      notes: [
        input.region.label,
        TahvilResult.disclaimer,
      ],
    );
  }

  void _addStirrupChecks(CheckBuilder b, BeamTahvilInput input, double d) {
    final minDia = catalog.minStirrupDiameterForLongBar(
      input.newDiameterMm.toDouble(),
    );
    final diaOk = Units.atLeast(input.newStirrupDiameterMm.toDouble(), minDia);
    final effective = d > 0 ? d : input.heightMm * 0.8;
    final maxSpacing = input.stirrupZone == StirrupZone.confinement
        ? catalog.beamCriticalStirrupMaxMm(
            effectiveDepthMm: effective,
            longBarMm: input.newDiameterMm.toDouble(),
          )
        : catalog.beamMiddleStirrupMaxMm(effective);
    final spacingOk = Units.atMost(input.newStirrupSpacingMm, maxSpacing);

    b.add(
      TahvilCheck(
        id: 'stirrup',
        title: 'Etriye',
        rule: catalog.beamStirrup,
        status: diaOk && spacingOk ? CheckStatus.passed : CheckStatus.failed,
        projectValue:
            'Ø${input.stirrupDiameterMm} / ${RebarMath.formatCm(input.stirrupSpacingMm / 10)} cm',
        newValue:
            'Ø${input.newStirrupDiameterMm} / ${RebarMath.formatCm(input.newStirrupSpacingMm / 10)} cm',
        message: !diaOk
            ? 'Etriye çapı yetersiz (min Ø${minDia.toStringAsFixed(0)})'
            : !spacingOk
                ? '${input.stirrupZone.label} aralığı ${RebarMath.formatCm(maxSpacing / 10)} cm sınırını aşıyor'
                : 'Etriye çap, aralık ve ${input.stirrupLegs} kol ayrı değerlendirildi.',
      ),
    );

    final changed = input.stirrupDiameterMm != input.newStirrupDiameterMm ||
        (input.stirrupSpacingMm - input.newStirrupSpacingMm).abs() > 1e-6;
    if (changed) {
      b.add(
        b.engineer(
          id: 'stirrup_change',
          title: 'Etriye değişikliği',
          rule: catalog.stirrupChange,
          message:
              'Etriye tahvili kg eşitliği ile yapılmaz. Kesme güvenliği '
              'müellif kontrolü gerektirir.',
        ),
      );
    }
  }

  String? _validate(BeamTahvilInput input) {
    return validatePositive('Kiriş genişliği', input.widthMm) ??
        validatePositive('Kiriş yüksekliği', input.heightMm) ??
        validatePositive('Paspayı', input.coverMm) ??
        validateDiameter(input.projectDiameterMm) ??
        validateDiameter(input.newDiameterMm) ??
        validateCount('Proje donatı adedi', input.projectCount) ??
        validateCount('Yeni donatı adedi', input.newCount) ??
        validateDiameter(input.stirrupDiameterMm) ??
        validateDiameter(input.newStirrupDiameterMm) ??
        validatePositive('Proje etriye aralığı', input.stirrupSpacingMm) ??
        validatePositive('Yeni etriye aralığı', input.newStirrupSpacingMm);
  }
}
