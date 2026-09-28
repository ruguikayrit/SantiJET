import 'package:flutter/material.dart';

import '../../core/theme/pro_theme.dart';
import '../../modules/pro_module.dart';

/// Eski uygulama kabuğu. Uzak sayfa açmaz.
class ModuleHostScreen extends StatelessWidget {
  const ModuleHostScreen({super.key, required this.module});

  final ProModule module;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.canvas,
      body: Center(
        child: Text(
          '${module.label} bu uygulamada henüz yok.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Inter', color: ProColors.textMuted),
        ),
      ),
    );
  }
}
