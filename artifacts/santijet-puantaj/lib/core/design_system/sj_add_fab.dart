import 'package:flutter/material.dart';

/// Puantaj · İmalat · Görev — ortak yuvarlak + ekleme FAB'ı.
///
/// Renk ve boyut [ThemeData.floatingActionButtonTheme] ile gelir
/// (electric blue zemin, beyaz + ikon).
class SJAddFab extends StatelessWidget {
  const SJAddFab({
    required this.onPressed,
    this.tooltip = 'Ekle',
    this.heroTag,
    super.key,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      tooltip: tooltip,
      child: const Icon(Icons.add),
    );
  }
}
