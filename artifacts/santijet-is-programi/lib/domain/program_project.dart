import 'dart:math';

/// Cihazda tutulan şantiye / proje. Buluta çıkmaz.
class ProgramProject {
  const ProgramProject({
    required this.id,
    required this.name,
    required this.code,
    this.notes,
  });

  final String id;
  final String name;

  /// Yerel iş kodu. Paylaşım veya bulut senkronu yoktur.
  final String code;
  final String? notes;

  ProgramProject copyWith({
    String? name,
    String? code,
    String? notes,
  }) => ProgramProject(
    id: id,
    name: name ?? this.name,
    code: code ?? this.code,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'notes': notes,
  };

  factory ProgramProject.fromJson(Map<String, dynamic> json) => ProgramProject(
    id: json['id'] as String,
    name: json['name'] as String,
    code: (json['code'] as String? ?? '').trim(),
    notes: json['notes'] as String?,
  );
}

class LocalProfile {
  const LocalProfile({this.displayName = '', this.role = ''});

  final String displayName;
  final String role;

  bool get isEmpty => displayName.trim().isEmpty && role.trim().isEmpty;

  LocalProfile copyWith({String? displayName, String? role}) => LocalProfile(
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
  );

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'role': role,
  };

  factory LocalProfile.fromJson(Map<String, dynamic>? json) => LocalProfile(
    displayName: json?['displayName'] as String? ?? '',
    role: json?['role'] as String? ?? '',
  );
}

/// `SJ` + 4 okunur karakter. Çakışmayı çağıran taraf kontrol eder.
String generateWorkCode({int seed = 0}) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = seed == 0 ? Random() : Random(seed);
  final body = List.generate(
    4,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
  return 'SJ$body';
}
