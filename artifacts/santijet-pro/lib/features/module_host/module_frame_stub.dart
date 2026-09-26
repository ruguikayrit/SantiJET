import 'package:flutter/material.dart';

import '../../core/theme/pro_theme.dart';

/// VM testleri ve web dışı derleme. Asıl ekran web önizlemede açılır.
Widget moduleFrame({required String viewType, required String url}) {
  return ColoredBox(
    color: ProColors.canvas,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          url,
          key: Key('module-frame-$viewType'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: ProColors.textMuted, fontFamily: 'Inter'),
        ),
      ),
    ),
  );
}
