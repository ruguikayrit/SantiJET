import '../inputs/element_inputs.dart';
import '../placement/placement_calculator.dart';
import '../rebar_math.dart';
import '../regulation/regulation_catalog.dart';
import '../result/tahvil_check.dart';
import 'check_helpers.dart';

class SlabTahvilCalculator {
  const SlabTahvilCalculator({this.catalog = const RegulationCatalog()});

  final RegulationCatalog catalog;

  TahvilResult evaluate(SlabTahvilInput input) {
    final error = _validate(input);
    if (error != null) return TahvilResult.invalid(error);

    final projectAs = RebarMath.areaPerMeterMm2(
      diameterMm: input.projectDiameterMm.toDouble(),
      spacingMm: input.projectSpacingMm,
    );
    final newAs = RebarMath.areaPerMeterMm2(
      diameterMm: input.newDiameterMm.toDouble(),
      spacingMm: input.newSpacingMm,
    );

    final b = CheckBuilder(catalog);
    final asCheck = b.compareAs(projectAs: projectAs, newAs: newAs, unit: 'mm²/m');
    b.add(asCheck);

    final maxS = catalog.slabMaxSpacingMm(input.thicknessMm);
    final spacingCheck = b.maxSpacing(
      newSpacingMm: input.newSpacingMm,
      limitMm: maxS,
      rule: catalog.slabMaxSpacing,
    );
    b.add(spacingCheck);

    final minCheck = b.minRatio(
      newAsPerMeter: newAs,
      thicknessMm: input.thicknessMm,
      minRatio: catalog.slabMinRatio,
      rule: catalog.slabMinRebar,
    );
    b.add(minCheck);

    final coverCheck = b.cover(
      coverMm: input.coverMm,
      minCoverMm: catalog.slabMinCoverMm,
      rule: catalog.slabCover,
    );
    b.add(coverCheck);

    final spacingPhysical = PlacementCalculator.spacingPhysicallyPossible(
      spacingMm: input.newSpacingMm,
      barDiameterMm: input.newDiameterMm.toDouble(),
      catalog: catalog,
    );
    final thicknessOk = PlacementCalculator.thicknessFitsLayers(
      thicknessMm: input.thicknessMm,
      coverMm: input.coverMm,
      barDiameterMm: input.newDiameterMm.toDouble(),
      bothLayers: true,
    );
    final fitOk = spacingPhysical && thicknessOk;
    b.add(
      TahvilCheck(
        id: 'placement',
        title: 'Fiziksel yerleşim',
        rule: catalog.slabPlacement,
        status: fitOk ? CheckStatus.passed : CheckStatus.failed,
        projectValue: input.layer.label,
        newValue: input.direction.label,
        message: fitOk
            ? 'Döşeme kalınlığı ve aralık uygun; ${input.layer.label} / ${input.direction.label} ayrı'
            : !spacingPhysical
                ? 'Aralık, donatı çapı ve net mesafe için yetersiz'
                : 'Döşeme kalınlığı paspayı ve donatı için yetersiz',
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
      parameter: 'Donatı aralığı',
      project: '${RebarMath.formatCm(input.projectSpacingMm / 10)} cm',
      replacement: '${RebarMath.formatCm(input.newSpacingMm / 10)} cm',
      mark: spacingCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Toplam As (1 m)',
      project: '${RebarMath.formatArea(projectAs)} mm²/m',
      replacement: '${RebarMath.formatArea(newAs)} mm²/m',
      mark: asCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Minimum donatı',
      mark: minCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Maksimum aralık',
      replacement: '≤ ${RebarMath.formatCm(maxS / 10)} cm',
      mark: spacingCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Paspayı',
      project: '${input.coverMm.toStringAsFixed(0)} mm',
      mark: coverCheck.status.mark,
    ));
    b.row(TahvilTableRow(
      parameter: 'Fiziksel yerleşim',
      mark: fitOk ? CheckStatus.passed.mark : CheckStatus.failed.mark,
    ));

    return TahvilResult(
      verdict: verdictFromChecks(b.checks),
      checks: b.checks,
      table: b.table,
      projectAs: projectAs,
      newAs: newAs,
      asUnit: 'mm²/m',
      projectLine:
          'Ø${input.projectDiameterMm} / ${RebarMath.formatCm(input.projectSpacingMm / 10)} cm',
      newLine:
          'Ø${input.newDiameterMm} / ${RebarMath.formatCm(input.newSpacingMm / 10)} cm',
      notes: [
        '${input.layer.label} · ${input.direction.label}',
        TahvilResult.disclaimer,
      ],
    );
  }

  String? _validate(SlabTahvilInput input) {
    return validatePositive('Döşeme kalınlığı', input.thicknessMm) ??
        validatePositive('Paspayı', input.coverMm) ??
        validateDiameter(input.projectDiameterMm) ??
        validateDiameter(input.newDiameterMm) ??
        validatePositive('Proje aralığı', input.projectSpacingMm) ??
        validatePositive('Yeni aralık', input.newSpacingMm);
  }
}
