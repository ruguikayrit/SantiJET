import 'package:flutter/material.dart';

import '../../../core/widgets/phase_placeholder.dart';

/// Analiz karşılaştırma — React Native `analiz-karsilastir` karşılığı.
/// Detaylı karşılaştırma tablosu ilgili fazda uygulanacaktır.
class KarsilastirScreen extends StatelessWidget {
  const KarsilastirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhasePlaceholder(title: 'Karşılaştırma', phase: 'Faz 8');
  }
}
