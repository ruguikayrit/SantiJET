import 'package:flutter/material.dart';

/// Günlük puantaj durumu — santiye-takip `Attendance.status` ile birebir.
enum AttendanceStatus {
  present('present', 'Mevcut', 'M', 8, Color(0xFF16A34A)),
  half('half', 'Yarım Gün', 'Y', 4, Color(0xFFD97706)),
  giris('giris', 'Giriş', 'G', 0, Color(0xFF2563EB)),
  cikis('cikis', 'Çıkış', 'Ç', 0, Color(0xFF7C3AED)),
  izinli('izinli', 'İzinli', 'İ', 0, Color(0xFF0EA5E9)),
  raporlu('raporlu', 'Raporlu', 'R', 0, Color(0xFF8B5CF6)),
  mazeret('mazeret', 'Mazeret', 'Mz', 0, Color(0xFFF59E0B)),
  tatil('tatil', 'Res. Tatil', 'T', 0, Color(0xFF64748B)),
  absent('absent', 'Yok', 'X', 0, Color(0xFFDC2626));

  const AttendanceStatus(
    this.jsonValue,
    this.label,
    this.short,
    this.hours,
    this.color,
  );

  final String jsonValue;
  final String label;
  final String short;
  final int hours;
  final Color color;

  bool get isWorkedDay =>
      this == AttendanceStatus.present || this == AttendanceStatus.half;

  /// Cetvel “Genel Toplam” — yok / giriş / çıkış hariç.
  bool get countsInGeneralTotal =>
      this != AttendanceStatus.absent &&
      this != AttendanceStatus.giris &&
      this != AttendanceStatus.cikis;

  /// Personel işe giriş / çıkış günü işaretleri.
  bool get isEmploymentMarker =>
      this == AttendanceStatus.giris || this == AttendanceStatus.cikis;

  static AttendanceStatus? tryParse(String? value) {
    if (value == null) return null;
    for (final s in AttendanceStatus.values) {
      if (s.jsonValue == value) return s;
    }
    return null;
  }

  static AttendanceStatus parse(String value) =>
      tryParse(value) ?? AttendanceStatus.absent;
}
