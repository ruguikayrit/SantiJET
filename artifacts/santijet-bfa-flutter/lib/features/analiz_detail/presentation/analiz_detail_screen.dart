import 'package:flutter/material.dart';

import '../../../core/widgets/phase_placeholder.dart';

/// Analiz detay sayfası (uygulamanın en kritik ekranı) — Faz 8'de uygulanacaktır
/// (poz bilgisi, özet, metraj, anlık maliyet, kalem tablosu, PDF/Excel, favori,
/// kopyala, düzenle).
class AnalizDetailScreen extends StatelessWidget {
  const AnalizDetailScreen({required this.analizId, super.key});

  final String analizId;

  @override
  Widget build(BuildContext context) {
    return PhasePlaceholder(
      title: 'Analiz Detayı',
      phase: 'Faz 8',
      subtitle: 'Analiz ID: $analizId',
    );
  }
}
