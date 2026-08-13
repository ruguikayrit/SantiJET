import 'tbdy_connection_input.dart';
import 'tbdy_connection_result.dart';

/// TBDY-2018 Tam Penetrasyonlu Küt Kaynaklı Kiriş & Kolon Birleşim Hesabı.
///
/// Formüller Excel doğrulama örneğiyle (S235, HEB 260, IPE 300, w=9, L=4.5)
/// hizalanmıştır.
abstract final class TbdyConnectionCalculator {
  /// Tablo 9B.3 — kiriş yüksekliği üst sınırı [mm].
  static const double maxBeamDepthMm = 920;

  /// Tablo 9B.3 — kiriş flanş kalınlığı üst sınırı [mm].
  static const double maxBeamFlangeThicknessMm = 25;

  /// Tipik özel moment çerçevesi açıklık/yükseklik aralığı.
  static const double minSpanToDepth = 7;
  static const double maxSpanToDepth = 20;

  /// Gövde narinlik limiti katsayısı: λ = k · √(E / (Ry·Fy)).
  static const double webSlendernessFactor = 2.65;

  static TbdyConnectionResult calculate(TbdyConnectionInput input) {
    final grade = input.steelGrade;
    final beam = input.beam;
    final column = input.column;

    final cprRaw = (grade.fy + grade.fu) / (2 * grade.fy);
    final cpr = cprRaw > 1.2 ? 1.2 : cprRaw;

    // Mpr [kNm] = Cpr · Ry · Fy [N/mm²] · Wplx [cm³] / 1000
    final mprKNm = cpr * grade.ry * grade.fy * beam.wplxCm3 / 1000;

    // Lh = L − d_kolon  (m)
    final lhM = input.spanLengthM - column.depthMm / 1000;
    if (lhM <= 0) {
      throw ArgumentError(
        'Net açıklık Lh pozitif olmalı (L > kolon yüksekliği).',
      );
    }

    final vgKn = input.distributedLoadKnPerM * lhM / 2;
    final vhKn = (2 * mprKNm / lhM) + vgKn;

    // Tam penetrasyonlu küt kaynak detayında plastik mafsal kolon yüzünde (Sh=0).
    const shM = 0.0;
    final mfKNm = mprKNm + vhKn * shM;
    final vuKn = vhKn;

    final webSlenderness =
        beam.clearWebHeightMm / beam.webThicknessMm;
    final expectedFy = grade.ry * grade.fy;
    final webSlendernessLimit =
        webSlendernessFactor * _sqrt(input.modulusE / expectedFy);

    final awMm2 = beam.webAreaMm2;
    final phiVnKn =
        input.phiShear * 0.6 * grade.fy * awMm2 * input.cv1 / 1000;

    final spanToDepth = (input.spanLengthM * 1000) / beam.depthMm;

    final checks = <ComplianceCheck>[
      ComplianceCheck(
        id: 'beam_depth',
        label: 'Kiriş yüksekliği (Tablo 9B.3)',
        passed: beam.depthMm <= maxBeamDepthMm,
        detail:
            'd = ${_fmt(beam.depthMm, 0)} mm ≤ ${_fmt(maxBeamDepthMm, 0)} mm',
      ),
      ComplianceCheck(
        id: 'beam_flange',
        label: 'Kiriş flanş kalınlığı (Tablo 9B.3)',
        passed: beam.flangeThicknessMm <= maxBeamFlangeThicknessMm,
        detail:
            'tf = ${_fmt(beam.flangeThicknessMm, 1)} mm ≤ ${_fmt(maxBeamFlangeThicknessMm, 0)} mm',
      ),
      ComplianceCheck(
        id: 'span_depth',
        label: 'Kiriş açıklık / yükseklik oranı',
        passed: spanToDepth >= minSpanToDepth &&
            spanToDepth <= maxSpanToDepth,
        detail:
            'L/d = ${_fmt(spanToDepth, 1)} (${_fmt(minSpanToDepth, 0)}–${_fmt(maxSpanToDepth, 0)})',
      ),
      ComplianceCheck(
        id: 'web_slenderness',
        label: 'Kiriş gövde narinliği',
        passed: webSlenderness <= webSlendernessLimit,
        detail:
            'h/tw = ${_fmt(webSlenderness, 1)} ≤ ${_fmt(webSlendernessLimit, 1)}',
      ),
      ComplianceCheck(
        id: 'shear_capacity',
        label: 'Kesme kapasitesi',
        passed: phiVnKn >= vuKn,
        detail:
            'φVn = ${_fmt(phiVnKn, 2)} kN ≥ Vu = ${_fmt(vuKn, 2)} kN',
      ),
    ];

    return TbdyConnectionResult(
      cpr: cpr,
      cprRaw: cprRaw,
      mprKNm: mprKNm,
      lhM: lhM,
      vgKn: vgKn,
      vhKn: vhKn,
      shM: shM,
      mfKNm: mfKNm,
      vuKn: vuKn,
      webSlenderness: webSlenderness,
      webSlendernessLimit: webSlendernessLimit,
      phiVnKn: phiVnKn,
      checks: checks,
    );
  }

  static double _sqrt(double value) {
    if (value <= 0) return 0;
    var x = value;
    for (var i = 0; i < 12; i++) {
      x = 0.5 * (x + value / x);
    }
    return x;
  }

  static String _fmt(double v, int digits) {
    return v.toStringAsFixed(digits);
  }
}
