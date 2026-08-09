import 'package:flutter/material.dart';

/// Malzeme talep durumu — ŞantiJET Pro RN `MaterialRequest.status`.
enum RequestStatus {
  pending('Beklemede', 0xFFF59E0B),
  approved('Onaylandı', 0xFF16A34A),
  delivered('Teslim Edildi', 0xFF2563EB),
  rejected('Reddedildi', 0xFFDC2626);

  const RequestStatus(this.label, this.colorValue);

  final String label;
  final int colorValue;

  /// Soft badge background (RN REQUEST_STATUS.bg).
  Color get badgeBg => Color(colorValue).withValues(alpha: 0.15);

  static RequestStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    // Eski seed değerleri → yeni modele map.
    switch (raw) {
      case 'taslak':
      case 'teklifte':
        return RequestStatus.pending;
      case 'siparis':
      case 'kismi':
        return RequestStatus.approved;
      case 'kapandi':
        return RequestStatus.delivered;
    }
    for (final v in RequestStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
