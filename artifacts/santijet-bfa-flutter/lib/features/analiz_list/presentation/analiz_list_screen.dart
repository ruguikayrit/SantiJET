import 'package:flutter/material.dart';

import '../../../core/widgets/phase_placeholder.dart';

/// Analiz listesi — Faz 7'de uygulanacaktır
/// (13.436 kayıt için indeksli/sayfalı liste, arama, kategori filtresi, favoriler).
class AnalizListScreen extends StatelessWidget {
  const AnalizListScreen({this.modul, this.query, super.key});

  final String? modul;
  final String? query;

  @override
  Widget build(BuildContext context) {
    return PhasePlaceholder(
      title: 'Analiz Listesi',
      phase: 'Faz 7',
      subtitle: 'Modül: ${modul ?? "—"} · Arama: ${query ?? "—"}',
    );
  }
}
