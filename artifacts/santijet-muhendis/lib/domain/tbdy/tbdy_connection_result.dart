/// Tek bir uygunluk kontrolü.
class ComplianceCheck {
  const ComplianceCheck({
    required this.id,
    required this.label,
    required this.passed,
    required this.detail,
  });

  final String id;
  final String label;
  final bool passed;
  final String detail;
}

/// TBDY-2018 birleşim hesabı çıktısı.
class TbdyConnectionResult {
  const TbdyConnectionResult({
    required this.cpr,
    required this.cprRaw,
    required this.mprKNm,
    required this.lhM,
    required this.vgKn,
    required this.vhKn,
    required this.shM,
    required this.mfKNm,
    required this.vuKn,
    required this.webSlenderness,
    required this.webSlendernessLimit,
    required this.phiVnKn,
    required this.checks,
  });

  final double cpr;
  final double cprRaw;
  final double mprKNm;
  final double lhM;
  final double vgKn;
  final double vhKn;

  /// Plastik mafsalın kolon yüzüne uzaklığı [m] — bu detayda 0.
  final double shM;
  final double mfKNm;
  final double vuKn;
  final double webSlenderness;
  final double webSlendernessLimit;
  final double phiVnKn;
  final List<ComplianceCheck> checks;

  bool get allPassed => checks.every((c) => c.passed);
}
