import 'package:flutter/material.dart';

import '../../../core/widgets/phase_placeholder.dart';

/// Ayarlar — Faz 12'de uygulanacaktır
/// (tema seçimi, JSON yedek dışa/içe aktarma, hukuki linkler, sürüm bilgisi).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhasePlaceholder(title: 'Ayarlar', phase: 'Faz 12');
  }
}
