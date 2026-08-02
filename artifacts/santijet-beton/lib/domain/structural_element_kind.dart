import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Yapısal eleman türü — döküm kart renkleri ve sınıflandırma.
enum StructuralElementKind {
  temel('Temel'),
  kolonPerde('Perde & Kolon'),
  doseme('Döşeme'),
  istinat('İstinat Duvarı'),
  diger('Diğer');

  const StructuralElementKind(this.label);
  final String label;

  /// Serbest metin eleman adından tür çıkarır (Türkçe karakter toleranslı).
  static StructuralElementKind fromElementName(String name) {
    final n = _fold(name);
    if (n.isEmpty) return StructuralElementKind.diger;

    if (n.contains('istinat') || n.contains('retaining')) {
      return StructuralElementKind.istinat;
    }
    if (n.contains('doseme') || n.contains('slab')) {
      return StructuralElementKind.doseme;
    }
    if (n.contains('temel') ||
        n.contains('radye') ||
        n.contains('footing') ||
        n.contains('foundation')) {
      return StructuralElementKind.temel;
    }
    if (n.contains('kolon') ||
        n.contains('perde') ||
        n.contains('column') ||
        n.contains('shear')) {
      return StructuralElementKind.kolonPerde;
    }
    return StructuralElementKind.diger;
  }

  /// Kart sol şerit + m³ rozet rengi.
  Color get accentColor => switch (this) {
        StructuralElementKind.temel => AppColors.warning,
        StructuralElementKind.kolonPerde => AppColors.info,
        StructuralElementKind.doseme => AppColors.success,
        StructuralElementKind.istinat => AppColors.partial,
        StructuralElementKind.diger => AppColors.electricBlueLight,
      };

  static String _fold(String raw) {
    final lower = raw.trim().toLowerCase();
    final buf = StringBuffer();
    for (final rune in lower.runes) {
      final c = String.fromCharCode(rune);
      buf.write(switch (c) {
        'ş' || 'Ş' => 's',
        'ğ' || 'Ğ' => 'g',
        'ü' || 'Ü' => 'u',
        'ö' || 'Ö' => 'o',
        'ç' || 'Ç' => 'c',
        'ı' || 'İ' || 'I' => 'i',
        _ => c,
      });
    }
    return buf.toString();
  }
}
