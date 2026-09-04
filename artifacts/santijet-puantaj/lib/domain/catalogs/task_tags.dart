import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../enums/attendance_status.dart';

/// Sabit görev etiketleri — disiplin (İnşaat / Elektrik / Mekanik).
abstract final class TaskTagCatalog {
  static const insaat = 'İnşaat';
  static const elektrik = 'Elektrik';
  static const mekanik = 'Mekanik';

  static const List<String> all = [insaat, elektrik, mekanik];

  /// Özet kart başlığı (büyük harf).
  static String cardLabel(String tag) => switch (normalize(tag)) {
        insaat => 'İNŞAAT',
        elektrik => 'ELEKTRİK',
        mekanik => 'MEKANİK',
        _ => tag.toUpperCase(),
      };

  /// Kayıtlı / girilen değeri katalog adına indirger.
  static String normalize(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final lower = t.toLowerCase();
    for (final tag in all) {
      if (tag.toLowerCase() == lower) return tag;
    }
    return t;
  }

  static bool isKnown(String raw) =>
      all.any((t) => t.toLowerCase() == raw.trim().toLowerCase());

  /// Ana sayfa Günlük Puantaj özet kartlarıyla aynı palet:
  /// İnşaat→Mevcut, Elektrik→Yarım, Mekanik→Yok.
  static Color accentFor(String tag) {
    switch (normalize(tag)) {
      case insaat:
        return AttendanceStatus.present.color;
      case elektrik:
        return AttendanceStatus.half.color;
      case mekanik:
        return AttendanceStatus.absent.color;
      default:
        return AppColors.inkMuted;
    }
  }
}
