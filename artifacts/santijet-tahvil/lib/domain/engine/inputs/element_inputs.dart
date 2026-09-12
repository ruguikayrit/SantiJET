import '../../../data/rebar_weight.dart';
import '../tahvil_element.dart';

class FoundationTahvilInput {
  const FoundationTahvilInput({
    required this.kind,
    required this.widthMm,
    required this.lengthMm,
    required this.thicknessMm,
    required this.coverMm,
    required this.projectDiameterMm,
    required this.projectSpacingMm,
    required this.newDiameterMm,
    required this.newSpacingMm,
    required this.layer,
    required this.direction,
    this.includeAnchorageReview = true,
  });

  final FoundationKind kind;
  final double widthMm;
  final double lengthMm;
  final double thicknessMm;
  final double coverMm;
  final int projectDiameterMm;
  final double projectSpacingMm;
  final int newDiameterMm;
  final double newSpacingMm;
  final RebarLayer layer;
  final RebarDirection direction;
  final bool includeAnchorageReview;
}

class ColumnTahvilInput {
  const ColumnTahvilInput({
    required this.widthMm,
    required this.heightMm,
    required this.storyHeightMm,
    required this.coverMm,
    required this.projectDiameterMm,
    required this.projectCount,
    required this.newDiameterMm,
    required this.newCount,
    required this.stirrupDiameterMm,
    required this.stirrupSpacingMm,
    required this.newStirrupDiameterMm,
    required this.newStirrupSpacingMm,
    required this.stirrupZone,
    this.stirrupLegs = 2,
    this.crosstieCount = 0,
    this.hasLap = false,
  });

  final double widthMm;
  final double heightMm;
  final double storyHeightMm;
  final double coverMm;
  final int projectDiameterMm;
  final int projectCount;
  final int newDiameterMm;
  final int newCount;
  final int stirrupDiameterMm;
  final double stirrupSpacingMm;
  final int newStirrupDiameterMm;
  final double newStirrupSpacingMm;
  final StirrupZone stirrupZone;
  final int stirrupLegs;
  final int crosstieCount;
  final bool hasLap;
}

class BeamTahvilInput {
  const BeamTahvilInput({
    required this.widthMm,
    required this.heightMm,
    required this.coverMm,
    required this.region,
    required this.projectDiameterMm,
    required this.projectCount,
    required this.newDiameterMm,
    required this.newCount,
    required this.stirrupDiameterMm,
    required this.stirrupSpacingMm,
    required this.newStirrupDiameterMm,
    required this.newStirrupSpacingMm,
    required this.stirrupZone,
    this.stirrupLegs = 2,
  });

  final double widthMm;
  final double heightMm;
  final double coverMm;
  final BeamRegion region;
  final int projectDiameterMm;
  final int projectCount;
  final int newDiameterMm;
  final int newCount;
  final int stirrupDiameterMm;
  final double stirrupSpacingMm;
  final int newStirrupDiameterMm;
  final double newStirrupSpacingMm;
  final StirrupZone stirrupZone;
  final int stirrupLegs;
}

class SlabTahvilInput {
  const SlabTahvilInput({
    required this.thicknessMm,
    required this.coverMm,
    required this.projectDiameterMm,
    required this.projectSpacingMm,
    required this.newDiameterMm,
    required this.newSpacingMm,
    required this.layer,
    required this.direction,
  });

  final double thicknessMm;
  final double coverMm;
  final int projectDiameterMm;
  final double projectSpacingMm;
  final int newDiameterMm;
  final double newSpacingMm;
  final RebarLayer layer;
  final RebarDirection direction;
}

String? validatePositive(String name, double value) {
  if (value <= 0) return '$name sıfır veya negatif olamaz.';
  return null;
}

String? validateCount(String name, int value) {
  if (value <= 0) return '$name sıfır veya negatif olamaz.';
  return null;
}

String? validateDiameter(int diameterMm) {
  if (diameterMm <= 0) return 'Donatı çapı Ø0 veya negatif olamaz.';
  if (!RebarWeight.isStandard(diameterMm)) {
    return 'Ø$diameterMm standart çap listesinde değil.';
  }
  return null;
}
