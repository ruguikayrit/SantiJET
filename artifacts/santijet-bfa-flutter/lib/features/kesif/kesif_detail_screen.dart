import 'package:flutter/material.dart';

import '../../core/widgets/phase_placeholder.dart';

/// Keşif detayı — React Native `kesif/[id]` karşılığı.
class KesifDetailScreen extends StatelessWidget {
  const KesifDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return PhasePlaceholder(
      title: 'Keşif Detayı',
      phase: 'Faz 9',
      subtitle: 'Proje ID: $projectId',
    );
  }
}
