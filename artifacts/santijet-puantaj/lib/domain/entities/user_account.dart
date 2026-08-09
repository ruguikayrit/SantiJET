/// Bulut oturumu kullanıcı hesabı (Demir ile uyumlu minimum alanlar).
class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  UserAccount copyWith({
    String? id,
    String? email,
    String? displayName,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
      };

  factory UserAccount.fromJson(Map<dynamic, dynamic> json) => UserAccount(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
      );
}
