import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Varsayılan görev kategorileri — kullanıcı kendi kategorilerini ekleyebilir.
abstract final class TaskCategoryCatalog {
  static const List<String> defaults = [
    'Satın Alma',
    'Saha',
    'Ofis',
    'Görüşme',
  ];

  /// Kategorisi atanmamış acil görevler.
  static const uncategorized = 'Kategorisiz';

  /// Özet kart rengi — bilinen gruplar sabit, diğerleri döngüsel palet.
  static Color accentFor(String category) {
    switch (category.trim().toLowerCase()) {
      case 'satın alma':
        return AppColors.partial;
      case 'saha':
        return AppColors.warning;
      case 'ofis':
        return AppColors.info;
      case 'görüşme':
        return AppColors.success;
      case 'kategorisiz':
        return AppColors.inkMuted;
      default:
        final palette = [
          AppColors.electricBlue,
          AppColors.moduleInsaat,
          AppColors.moduleMekanik,
          AppColors.moduleElektrik,
        ];
        final hash = category.codeUnits.fold<int>(0, (h, c) => h + c);
        return palette[hash % palette.length];
    }
  }
}
