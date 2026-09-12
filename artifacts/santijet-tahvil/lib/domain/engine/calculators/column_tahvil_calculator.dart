import '../inputs/element_inputs.dart';
import '../placement/placement_calculator.dart';
import '../rebar_math.dart';
import '../regulation/regulation_catalog.dart';
import '../result/tahvil_check.dart';
import '../tahvil_element.dart';
import '../units.dart';
import 'check_helpers.dart';

class ColumnTahvilCalculator {
  const ColumnTahvilCalculator({this.catalog = const RegulationCatalog()});

  final RegulationCatalog catalog;

  TahvilResult evaluate(ColumnTahvilInput input) {
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
    final section = input.widthMm * input.heightMm;
    final projectRho = RebarMath.ratio(areaMm2: projectAs, sectionAreaMm2: section);
    final newRho = RebarMath.ratio(areaMm2: newAs, sectionAreaMm2: section);

    final b = CheckBuilder(catalog);
    final asCheck = b.compareAs(projectAs: projectAs, newAs: newAs, unit: 'mm²');
    b.add(asCheck);

    final rhoOk = Units.atLeast(newRho, catalog.columnMinRatio) &&
        Units.atMost(newRho, catalog.columnMaxRatio);
    b.add(
      TahvilCheck(
        id: 'ratio',
        title: 'Donatı oranı',
        rule: catalog.columnRatio,
        status: rhoOk ? CheckStatus.passed : CheckStatus.failed,
        projectValue: '%${RebarMath.formatRatioPercent(projectRho)}',
        newValue: '%${RebarMath.formatRatioPercent(newRho)}',
        message: rhoOk
            ? 'ρmin ${RebarMath.formatRatioPercent(catalog.columnMinRatio)}% – '
                'ρmax ${RebarMath.formatRatioPercent(catalog.columnMaxRatio)}%'
            : newRho < catalog.columnMinRatio
                ? 'Donatı oranı minimumun altında'
                : 'Donatı oranı maksimumu aşıyor (fazla donatı)',
      ),
    );

    final countOk = input.newCount >= catalog.columnMinBarCount;
    b.add(
      TahvilCheck(
        id: 'bar_count',
        title: 'Donatı adedi / dört yüz',
        rule: catalog.columnBarCount,
        status: countOk ? CheckStatus.passed : CheckStatus.failed,
        projectValue: '${input.projectCount}',
        newValue: '${input.newCount}',
        message: countOk
            ? 'En az ${catalog.columnMinBarCount} donatı (köşeler)'
            : 'Kolonda en az ${catalog.columnMinBarCount} boyuna donatı gerekir',
      ),
    );

    final coverCheck = b.cover(
      coverMm: input.coverMm,
      minCoverMm: catalog.columnMinCoverMm,
      rule: catalog.columnCover,
    );
    b.add(coverCheck);

    final fits = PlacementCalculator.columnFits(
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
        rule: catalog.columnPlacement,
        status: fits ? CheckStatus.passed : CheckStatus.failed,
        projectValue: '${input.widthMm.toStringAsFixed(0)}×${input.heightMm.toStringAsFixed(0)} mm',
        newValue: '${input.newCount}×Ø${input.newDiameterMm}',
        message: fits
            ? 'Donatılar kolon kesitine yerleşiyor'
            : 'Donatılar kolon kesitine sığmıyor',
      ),
    );

    final clear = catalog.minClearForBar(input.newDiameterMm.toDouble());
    final availB = PlacementCalculator.availableInnerMm(
      sectionMm: input.widthMm,
      coverMm: input.coverMm,
      stirrupDiameterMm: input.newStirrupDiameterMm.toDouble(),
    );
    final onB = PlacementCalculator.maxBarsInLayer(
      availableMm: availB,
      barDiameterMm: input.newDiameterMm.toDouble(),
      clearSpacingMm: clear,
    );
    final faceClear = onB >= 2
        ? PlacementCalculator.faceClearSpacingMm(
            availableMm: availB,
            barsOnFace: onB,
            barDiameterMm: input.newDiameterMm.toDouble(),
          )
        : 0.0;
    final clearOk = onB >= 2 && Units.atLeast(faceClear, clear);
    b.add(
      TahvilCheck(
        id: 'clear',
        title: 'Net aralık',
        rule: catalog.columnSpacing,
        status: clearOk ? CheckStatus.passed : CheckStatus.failed,
        newValue: 'min ${clear.toStringAsFixed(0)} mm',
        message: clearOk
            ? 'Net aralık sağlanıyor'
            : 'Boyuna donatılar arasında net aralık yetersiz',
      ),
    );

    _addStirrupChecks(b, input);

    if (input.hasLap) {
      b.add(
        b.engineer(
          id: 'lap',
          title: 'Bindirme bölgesi',
          rule: catalog.columnLap,
          message:
              'Bindirme bölgesinde donatı oranı, etriye ve bindirme boyu müellif kontrolü gerektirir.',
        ),
      );
    }

    b.add(
      b.engineer(
        id: 'seismic',
        title: 'Deprem / kapasite',
        rule: catalog.columnSeismic,
        message:
            'Kolon boyuna donatı tahvili kesme güvenliği, eğilme kapasitesi ve '
            'kapasite tasarımı için otomatik “uygun” sayılmaz.',
      ),
    );

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
      mark: countOk ? CheckStatus.passed.mark : CheckStatus.failed.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Toplam As',
      project: '${RebarMath.formatArea(projectAs)} mm²',
      replacement: '${RebarMath.formatArea(newAs)} mm²',
      mark: asCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Donatı oranı',
      project: '%${RebarMath.formatRatioPercent(projectRho)}',
      replacement: '%${RebarMath.formatRatioPercent(newRho)}',
      mark: rhoOk ? CheckStatus.passed.mark : CheckStatus.failed.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Paspayı',
      project: '${input.coverMm.toStringAsFixed(0)} mm',
      mark: coverCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Fiziksel yerleşim',
      mark: fits ? CheckStatus.passed.mark : CheckStatus.failed.mark,
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
      notes: [TahvilResult.disclaimer],
    );
  }

  void _addStirrupChecks(CheckBuilder b, ColumnTahvilInput input) {
    final minDia = catalog.minStirrupDiameterForLongBar(
      input.newDiameterMm.toDouble(),
    );
    final diaOk = Units.atLeast(input.newStirrupDiameterMm.toDouble(), minDia);
    final side = input.widthMm < input.heightMm ? input.widthMm : input.heightMm;
    final maxSpacing = input.stirrupZone == StirrupZone.confinement
        ? catalog.confinementStirrupMaxMm(
            minSectionSideMm: side,
            longBarMm: input.newDiameterMm.toDouble(),
          )
        : catalog.middleStirrupMaxMm(side);
    final spacingOk = Units.atMost(input.newStirrupSpacingMm, maxSpacing);

    b.add(
      TahvilCheck(
        id: 'stirrup',
        title: 'Etriye geometrisi',
        rule: catalog.stirrupGeometry,
        status: diaOk && spacingOk ? CheckStatus.passed : CheckStatus.failed,
        projectValue:
            'Ø${input.stirrupDiameterMm} / ${RebarMath.formatCm(input.stirrupSpacingMm / 10)} cm',
        newValue:
            'Ø${input.newStirrupDiameterMm} / ${RebarMath.formatCm(input.newStirrupSpacingMm / 10)} cm',
        message: !diaOk
            ? 'Etriye çapı en az Ø${minDia.toStringAsFixed(0)} olmalıdır'
            : !spacingOk
                ? '${input.stirrupZone.label} aralığı ${RebarMath.formatCm(maxSpacing / 10)} cm sınırını aşıyor'
                : 'Etriye çapı ve aralığı ${input.stirrupZone.label} için sınır içinde. '
                    'Kol sayısı: ${input.stirrupLegs}, çiroz: ${input.crosstieCount}',
      ),
    );

    final changed = input.stirrupDiameterMm != input.newStirrupDiameterMm ||
        (input.stirrupSpacingMm - input.newStirrupSpacingMm).abs() > 1e-6;
    if (changed) {
      final projectAsw = RebarMath.barAreaMm2(input.stirrupDiameterMm.toDouble()) *
          input.stirrupLegs;
      final newAsw = RebarMath.barAreaMm2(input.newStirrupDiameterMm.toDouble()) *
          input.stirrupLegs;
      b.add(
        b.engineer(
          id: 'stirrup_change',
          title: 'Etriye / çiroz değişikliği',
          rule: catalog.stirrupChange,
          projectValue: '${RebarMath.formatArea(projectAsw)} mm²/kesit',
          newValue: '${RebarMath.formatArea(newAsw)} mm²/kesit',
          message:
              'Alan artışı otomatik uygunluk değildir. Sarılma, kesme ve '
              'çiroz düzeni müellif kontrolü gerektirir.',
        ),
      );
    }
  }

  String? _validate(ColumnTahvilInput input) {
    return validatePositive('Kolon genişliği', input.widthMm) ??
        validatePositive('Kolon yüksekliği', input.heightMm) ??
        validatePositive('Kat yüksekliği', input.storyHeightMm) ??
        validatePositive('Paspayı', input.coverMm) ??
        validateDiameter(input.projectDiameterMm) ??
        validateDiameter(input.newDiameterMm) ??
        validateCount('Proje donatı adedi', input.projectCount) ??
        validateCount('Yeni donatı adedi', input.newCount) ??
        validateDiameter(input.stirrupDiameterMm) ??
        validateDiameter(input.newStirrupDiameterMm) ??
        validatePositive('Proje etriye aralığı', input.stirrupSpacingMm) ??
        validatePositive('Yeni etriye aralığı', input.newStirrupSpacingMm) ??
        validateCount('Etriye kol sayısı', input.stirrupLegs);
  }
}
