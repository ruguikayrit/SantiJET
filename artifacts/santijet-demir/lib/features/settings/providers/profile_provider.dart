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
  final profession = settings.profileProfession.trim();
  return profession.isNotEmpty ? profession : '';
});

final profileInitialProvider = Provider<String>((ref) {
  final name = ref.watch(profileDisplayNameProvider).trim();
  if (name.isEmpty) return 'U';
  return name[0].toUpperCase();
});
