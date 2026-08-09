/// Malzeme talep durumu — Demir `OrderStatus` deseni.
enum RequestStatus {
  taslak('Taslak', 0xFF64748B),
  teklifte('Teklifte', 0xFF0EA5E9),
  siparis('Sipariş', 0xFF3B82F6),
  kismi('Kısmi', 0xFFF59E0B),
  kapandi('Kapandı', 0xFF10B981);

  const RequestStatus(this.label, this.colorValue);

  final String label;
  final int colorValue;

  RequestStatus? get nextStatus => switch (this) {
        RequestStatus.taslak => RequestStatus.teklifte,
        RequestStatus.teklifte => RequestStatus.siparis,
        RequestStatus.siparis => RequestStatus.kismi,
        RequestStatus.kismi => RequestStatus.kapandi,
        RequestStatus.kapandi => null,
      };

  String get actionLabel => switch (this) {
        RequestStatus.taslak => 'Teklife Gönder',
        RequestStatus.teklifte => 'Sipariş Ver',
        RequestStatus.siparis => 'Teslim Al',
        RequestStatus.kismi => 'Kapat',
        RequestStatus.kapandi => '',
      };

  bool get canCancel =>
      this == RequestStatus.taslak || this == RequestStatus.teklifte;

  static RequestStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in RequestStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
