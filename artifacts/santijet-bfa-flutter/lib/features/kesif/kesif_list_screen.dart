import 'package:flutter/material.dart';

import '../../core/widgets/phase_placeholder.dart';

/// Keşif listesi — React Native `kesif/index` karşılığı.
class KesifListScreen extends StatelessWidget {
  const KesifListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhasePlaceholder(title: 'Keşif', phase: 'Faz 9');
  }
}
