import '../../../data/rebar_weight.dart';
import '../inputs/element_inputs.dart';
import '../rebar_math.dart';
import '../regulation/regulation_catalog.dart';
import '../result/tahvil_check.dart';
import 'beam_tahvil_calculator.dart';
import 'column_tahvil_calculator.dart';
import 'foundation_tahvil_calculator.dart';
import 'slab_tahvil_calculator.dart';

/// Çap seçilince adet/aralık kombinasyonlarını eleman kurallarıyla dener.
class TahvilSuggester {
  const TahvilSuggester({this.catalog = const RegulationCatalog()});

  final RegulationCatalog catalog;

  List<TahvilSuggestion> suggestFoundation({
    required FoundationTahvilInput base,
    required int newDiameterMm,
  }) {
    final out = <TahvilSuggestion>[];
    final calc = FoundationTahvilCalculator(catalog: catalog);
    for (var s = 50.0; s <= catalog.foundationMaxSpacingCapMm + 1e-9; s += 25) {
      final result = calc.evaluate(
        FoundationTahvilInput(
          kind: base.kind,
          widthMm: base.widthMm,
          lengthMm: base.lengthMm,
          thicknessMm: base.thicknessMm,
          coverMm: base.coverMm,
          projectDiameterMm: base.projectDiameterMm,
          projectSpacingMm: base.projectSpacingMm,
          newDiameterMm: newDiameterMm,
          newSpacingMm: s,
          layer: base.layer,
          direction: base.direction,
          includeAnchorageReview: base.includeAnchorageReview,
        ),
      );
      if (!result.isValid || result.projectAs == null || result.newAs == null) {
        continue;
      }
      out.add(
        TahvilSuggestion(
          label:
              'Ø$newDiameterMm / ${RebarMath.formatCm(s / 10)} cm',
          result: result,
          excessAs: result.newAs! - result.projectAs!,
        ),
      );
    }
    return _rank(out);
  }

  List<TahvilSuggestion> suggestSlab({
    required SlabTahvilInput base,
    required int newDiameterMm,
  }) {
    final out = <TahvilSuggestion>[];
    final calc = SlabTahvilCalculator(catalog: catalog);
    for (var s = 50.0; s <= catalog.slabMaxSpacingCapMm + 1e-9; s += 25) {
      final result = calc.evaluate(
        SlabTahvilInput(
          thicknessMm: base.thicknessMm,
          coverMm: base.coverMm,
          projectDiameterMm: base.projectDiameterMm,
          projectSpacingMm: base.projectSpacingMm,
          newDiameterMm: newDiameterMm,
          newSpacingMm: s,
          layer: base.layer,
          direction: base.direction,
        ),
      );
      if (!result.isValid || result.projectAs == null || result.newAs == null) {
        continue;
      }
      out.add(
        TahvilSuggestion(
          label: 'Ø$newDiameterMm / ${RebarMath.formatCm(s / 10)} cm',
          result: result,
          excessAs: result.newAs! - result.projectAs!,
        ),
      );
    }
    return _rank(out);
  }

  List<TahvilSuggestion> suggestColumn({
    required ColumnTahvilInput base,
    required int newDiameterMm,
  }) {
    final out = <TahvilSuggestion>[];
    final calc = ColumnTahvilCalculator(catalog: catalog);
    for (var n = catalog.columnMinBarCount; n <= catalog.columnMaxBarsHint; n++) {
      final result = calc.evaluate(
        ColumnTahvilInput(
          widthMm: base.widthMm,
          heightMm: base.heightMm,
          storyHeightMm: base.storyHeightMm,
          coverMm: base.coverMm,
          projectDiameterMm: base.projectDiameterMm,
          projectCount: base.projectCount,
          newDiameterMm: newDiameterMm,
          newCount: n,
          stirrupDiameterMm: base.stirrupDiameterMm,
          stirrupSpacingMm: base.stirrupSpacingMm,
          newStirrupDiameterMm: base.newStirrupDiameterMm,
          newStirrupSpacingMm: base.newStirrupSpacingMm,
          stirrupZone: base.stirrupZone,
          stirrupLegs: base.stirrupLegs,
          crosstieCount: base.crosstieCount,
          hasLap: base.hasLap,
        ),
      );
      if (!result.isValid || result.projectAs == null || result.newAs == null) {
        continue;
      }
      out.add(
        TahvilSuggestion(
          label: '$n×Ø$newDiameterMm',
          result: result,
          excessAs: result.newAs! - result.projectAs!,
        ),
      );
    }
    return _rank(out);
  }

  List<TahvilSuggestion> suggestBeam({
    required BeamTahvilInput base,
    required int newDiameterMm,
  }) {
    final out = <TahvilSuggestion>[];
    final calc = BeamTahvilCalculator(catalog: catalog);
    for (var n = 2; n <= catalog.beamMaxBarsHint; n++) {
      final result = calc.evaluate(
        BeamTahvilInput(
          widthMm: base.widthMm,
          heightMm: base.heightMm,
          coverMm: base.coverMm,
          region: base.region,
          projectDiameterMm: base.projectDiameterMm,
          projectCount: base.projectCount,
          newDiameterMm: newDiameterMm,
          newCount: n,
          stirrupDiameterMm: base.stirrupDiameterMm,
          stirrupSpacingMm: base.stirrupSpacingMm,
          newStirrupDiameterMm: base.newStirrupDiameterMm,
          newStirrupSpacingMm: base.newStirrupSpacingMm,
          stirrupZone: base.stirrupZone,
          stirrupLegs: base.stirrupLegs,
        ),
      );
      if (!result.isValid || result.projectAs == null || result.newAs == null) {
        continue;
      }
      out.add(
        TahvilSuggestion(
          label: '$n×Ø$newDiameterMm',
          result: result,
          excessAs: result.newAs! - result.projectAs!,
        ),
      );
    }
    return _rank(out);
  }

  List<int> nearbyDiameters(int projectDiameterMm) {
    return RebarWeight.standardDiameters
        .where((d) => d != projectDiameterMm)
        .toList();
  }

  List<TahvilSuggestion> _rank(List<TahvilSuggestion> items) {
    int rank(TahvilVerdict v) => switch (v) {
          TahvilVerdict.suitable => 0,
          TahvilVerdict.engineerReview => 1,
          TahvilVerdict.notSuitable => 2,
        };
    final copy = [...items]..sort((a, b) {
        final vr = rank(a.result.verdict).compareTo(rank(b.result.verdict));
        if (vr != 0) return vr;
        final aOk = a.isAcceptable;
        final bOk = b.isAcceptable;
        if (aOk != bOk) return aOk ? -1 : 1;
        final aExcess = a.excessAs < 0 ? double.infinity : a.excessAs;
        final bExcess = b.excessAs < 0 ? double.infinity : b.excessAs;
        return aExcess.compareTo(bExcess);
      });
    return copy;
  }
}
