/// Hesap üyelik tipi — kayıt / giriş sırasında seçilir.
enum MembershipType {
  individual,
  corporate;

  String get label => switch (this) {
        MembershipType.individual => 'Bireysel',
        MembershipType.corporate => 'Kurumsal',
      };

  String get description => switch (this) {
        MembershipType.individual =>
          'Tek kullanıcı — tüm modüllere tam erişim',
        MembershipType.corporate =>
          'Firma hesabı — rolünüze göre sayfa ve işlem yetkileri',
      };

  static MembershipType fromStorage(String? raw) {
    return switch (raw) {
      'corporate' => MembershipType.corporate,
      _ => MembershipType.individual,
    };
  }

  String get storageValue => name;
}
