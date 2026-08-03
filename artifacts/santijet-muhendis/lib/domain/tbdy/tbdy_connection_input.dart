import 'steel_grade.dart';
import 'steel_profile.dart';

/// TBDY-2018 tam penetrasyonlu küt kaynaklı kiriş-kolon birleşim girdisi.
class TbdyConnectionInput {
  const TbdyConnectionInput({
    required this.steelGrade,
    required this.column,
    required this.beam,
    required this.distributedLoadKnPerM,
    required this.spanLengthM,
    this.mountingBoltCount = 2,
    this.mountingBoltDiameterMm = 16,
    this.modulusE = 200000,
    this.phiShear = 1.0,
    this.cv1 = 1.0,
  });

  final SteelGrade steelGrade;
  final SteelProfile column;
  final SteelProfile beam;

  /// Düzgün yayılı yük w [kN/m].
  final double distributedLoadKnPerM;

  /// Kiriş açıklığı L [m].
  final double spanLengthM;

  final int mountingBoltCount;
  final int mountingBoltDiameterMm;

  /// Elastisite modülü E [N/mm²].
  final double modulusE;

  /// Kesme dayanımı azaltma katsayısı φ.
  final double phiShear;

  /// Gövde kesme katsayısı Cv1 (h/tw limiti içinde 1.0).
  final double cv1;
}
