class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.currentSessionId,
  });

  final String id;
  final String email;
  final String displayName;
  final String passwordHash;
  final String currentSessionId;

  UserAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? passwordHash,
    String? currentSessionId,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'passwordHash': passwordHash,
        'currentSessionId': currentSessionId,
      };

  factory UserAccount.fromJson(Map<dynamic, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? '',
      passwordHash: json['passwordHash'] as String,
      currentSessionId: json['currentSessionId'] as String? ?? '',
    );
  }
}
