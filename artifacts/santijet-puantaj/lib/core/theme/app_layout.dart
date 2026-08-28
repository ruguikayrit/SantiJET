import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Kabuk içi scroll + FAB hizalama sabitleri.
abstract final class AppLayout {
  /// Extended FAB (~56) + kenar boşluğu (16) + alt özet satırı nefesi.
  static const fabScrollClearance = 100.0;

  static double scrollBottom({
    bool clearFab = false,
    double extra = 0,
  }) =>
      (clearFab ? fabScrollClearance : AppSpacing.xxl) + extra;

  static EdgeInsets scrollPadding({
    double left = AppSpacing.md,
    double top = 0,
    double right = AppSpacing.md,
    bool clearFab = false,
    double extraBottom = 0,
  }) =>
      EdgeInsets.fromLTRB(
        left,
        top,
        right,
        scrollBottom(clearFab: clearFab, extra: extraBottom),
      );
}
