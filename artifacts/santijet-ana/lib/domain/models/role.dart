import 'package:equatable/equatable.dart';

import 'page_key.dart';

class Role extends Equatable {
  const Role({
    required this.id,
    required this.name,
    required this.isAdmin,
    required this.permissions,
  });

  final String id;
  final String name;
  final bool isAdmin;
  final Map<String, Permission> permissions;

  Permission permissionFor(String pageKey) =>
      permissions[pageKey] ?? Permission.none;

  Role copyWith({
    String? id,
    String? name,
    bool? isAdmin,
    Map<String, Permission>? permissions,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      isAdmin: isAdmin ?? this.isAdmin,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isAdmin': isAdmin,
        'permissions': {
          for (final e in permissions.entries) e.key: e.value.wire,
        },
      };

  factory Role.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final perms = <String, Permission>{};
    if (rawPerms is Map) {
      for (final k in allPageKeys) {
        final v = rawPerms[k] ??
            (k == 'dosyalar' ? rawPerms['proje-arsivi'] : null);
        perms[k] = PermissionX.fromWire(v);
      }
    } else {
      for (final k in allPageKeys) {
        perms[k] = Permission.none;
      }
    }
    return Role(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isAdmin: json['isAdmin'] == true,
      permissions: perms,
    );
  }

  static List<Role> defaultRoles() {
    return defaultRolesRaw.map((raw) {
      final perms = <String, Permission>{};
      final p = raw['permissions'] as Map<String, Permission>;
      for (final k in allPageKeys) {
        perms[k] = p[k] ?? Permission.none;
      }
      return Role(
        id: raw['id'] as String,
        name: raw['name'] as String,
        isAdmin: raw['isAdmin'] as bool,
        permissions: perms,
      );
    }).toList();
  }

  @override
  List<Object?> get props => [id, name, isAdmin, permissions];
}
