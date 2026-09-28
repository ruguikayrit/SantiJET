import 'package:flutter/material.dart';

import '../../core/theme/pro_theme.dart';

/// Eski yayın adresini açmaz.
Widget moduleFrame({required String viewType}) {
  return ColoredBox(
    color: ProColors.canvas,
    child: Center(
      child: Text(
        'Bu modül bu uygulamada henüz yok.',
        key: Key('module-frame-$viewType'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: ProColors.textMuted, fontFamily: 'Inter'),
      ),
    ),
  );
}
