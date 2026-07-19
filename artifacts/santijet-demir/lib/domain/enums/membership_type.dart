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
          'Tek kullanıcı — onay süreci yok, tüm modüllere tam erişim',
        MembershipType.corporate =>
          'Firma hesabı — rolünüze göre sayfa, onay ve işlem yetkileri',
      };

  static MembershipType fromStorage(String? raw) {
    return switch (raw) {
      'corporate' => MembershipType.corporate,
      _ => MembershipType.individual,
    };
  }

  String get storageValue => name;
}
