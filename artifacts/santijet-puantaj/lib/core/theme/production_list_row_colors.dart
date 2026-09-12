import 'package:flutter/material.dart';

import 'app_colors.dart';

/// İmalat / Verim listelerinde çift–tek satır arka planı (tüm temalar).
abstract final class ProductionListRowColors {
  static Color at(int index) =>
      index.isEven ? AppColors.cardSurface : AppColors.cardSurfaceHighlight;
}
