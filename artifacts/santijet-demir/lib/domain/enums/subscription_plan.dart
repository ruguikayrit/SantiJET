/// Ücretli abonelik planı — kurumsal rol (MembershipType) ile ayrı eksen.
enum SubscriptionPlan {
  /// Satın alınmamış / bilinmeyen.
  none,

  /// Sipariş, teslimat, sayım, mukayese, metraj.
  demirTakip,

  /// Paket 1 + hesap/analiz/rapor + tahmin motoru.
  demirTakipAnaliz;

  String get label => switch (this) {
        SubscriptionPlan.none => 'Plan yok',
        SubscriptionPlan.demirTakip => 'Demir Takip',
        SubscriptionPlan.demirTakipAnaliz => 'Demir Takip & Analiz & Tahmin',
      };

  String get shortLabel => switch (this) {
        SubscriptionPlan.none => 'Yok',
        SubscriptionPlan.demirTakip => 'Demir Takip',
        SubscriptionPlan.demirTakipAnaliz => 'Analiz & Tahmin',
      };

  bool get includesAnalysis => this == SubscriptionPlan.demirTakipAnaliz;

  bool get includesPrediction => this == SubscriptionPlan.demirTakipAnaliz;

  bool get isPaid =>
      this == SubscriptionPlan.demirTakip ||
      this == SubscriptionPlan.demirTakipAnaliz;

  static SubscriptionPlan fromStorage(String? raw) {
    return switch (raw) {
      'demirTakipAnaliz' || 'analiz' || 'pro' =>
        SubscriptionPlan.demirTakipAnaliz,
      'demirTakip' || 'core' || 'basic' => SubscriptionPlan.demirTakip,
      'none' => SubscriptionPlan.none,
      // Eski hesaplar: alan yoksa temel paket.
      null || '' => SubscriptionPlan.demirTakip,
      _ => SubscriptionPlan.demirTakip,
    };
  }

  String get storageValue => name;
}
