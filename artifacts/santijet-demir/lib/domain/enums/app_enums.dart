enum BottomNavTab {
  dashboard('Dashboard', '/dashboard'),
  orders('Siparişler', '/orders'),
  incomingRebar('Gelen Demir', '/incoming-rebar'),
  fieldCount('Saha Sayım', '/field-count'),
  analysis('Analiz', '/analysis');

  const BottomNavTab(this.label, this.path);

  final String label;
  final String path;
}

enum OrderStatus {
  draft('Taslak', 0xFF64748B),
  pendingApproval('Onay Bek.', 0xFFF59E0B),
  submitted('Verildi', 0xFF3B82F6),
  inTransit('Yolda', 0xFF0EA5E9),
  completed('Tamamlandı', 0xFF10B981);

  const OrderStatus(this.label, this.colorValue);

  final String label;
  final int colorValue;
}

enum DeliveryStatus {
  received('Teslim Alındı', 0xFF10B981),
  partial('Kısmi', 0xFFA855F7),
  missing('Eksik', 0xFFEF4444),
  excess('Fazla', 0xFFF59E0B),
  pending('Beklemede', 0xFF64748B);

  const DeliveryStatus(this.label, this.colorValue);

  final String label;
  final int colorValue;
}

enum AlertSeverity {
  critical('Kritik', 0xFFEF4444),
  warning('Uyarı', 0xFFF59E0B),
  info('Bilgi', 0xFFFBBF24);

  const AlertSeverity(this.label, this.colorValue);

  final String label;
  final int colorValue;
}
