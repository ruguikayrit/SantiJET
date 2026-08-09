/// Malzeme talep durumu.
enum RequestStatus {
  taslak,
  teklifte,
  siparis,
  kismi,
  kapandi;

  String get label => switch (this) {
        RequestStatus.taslak => 'Taslak',
        RequestStatus.teklifte => 'Teklifte',
        RequestStatus.siparis => 'Sipariş',
        RequestStatus.kismi => 'Kısmi',
        RequestStatus.kapandi => 'Kapandı',
      };

  static RequestStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in RequestStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
