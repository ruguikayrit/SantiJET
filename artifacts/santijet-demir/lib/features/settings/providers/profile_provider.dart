import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

final profileDisplayNameProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final auth = ref.watch(authProvider);
  final custom = settings.profileName.trim();
  if (custom.isNotEmpty) return custom;
  return auth.user?.displayName ?? 'Kullanıcı';
});

final profileProfessionProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.profileProfession.trim();
});

final profileRoleProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.profileRole.trim();
});

final profileInitialProvider = Provider<String>((ref) {
  final name = ref.watch(profileDisplayNameProvider).trim();
  if (name.isEmpty) return 'U';

  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';

  final first = parts.first.substring(0, 1).toUpperCase();
  if (parts.length == 1) return first;

  final last = parts.last.substring(0, 1).toUpperCase();
  return '$first$last';
});
