import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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

  static Color accentFor(String tag) {
    switch (normalize(tag)) {
      case insaat:
        return AppColors.moduleInsaat;
      case elektrik:
        return AppColors.moduleElektrik;
      case mekanik:
        return AppColors.moduleMekanik;
      default:
        return AppColors.inkMuted;
    }
  }
}
