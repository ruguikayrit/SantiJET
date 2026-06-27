import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/domain/entities/app_settings.dart';

const _settingsKey = 'app_settings';

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box('settings');
});

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return AppSettingsNotifier(box);
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._box)
      : super(_loadSettings(_box));

  final Box _box;

  static AppSettings _loadSettings(Box box) {
    final raw = box.get(_settingsKey);
    if (raw is Map) {
      return AppSettings.fromJson(raw);
    }
    return AppSettings();
  }

  Future<void> _persist() async {
    await _box.put(_settingsKey, state.toJson());
  }

  Future<void> updateCompany({
    String? companyName,
    String? taxNo,
    String? address,
    String? contactEmail,
    String? contactPhone,
  }) async {
    state = state.copyWith(
      companyName: companyName,
      taxNo: taxNo,
      address: address,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
    );
    await _persist();
  }

  Future<void> updateProject({
    String? projectName,
    String? projectCode,
    String? projectLocation,
    DateTime? projectStartDate,
    DateTime? projectEndDate,
    double? projectProgress,
  }) async {
    state = state.copyWith(
      projectName: projectName,
      projectCode: projectCode,
      projectLocation: projectLocation,
      projectStartDate: projectStartDate,
      projectEndDate: projectEndDate,
      projectProgress: projectProgress,
    );
    await _persist();
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> setWeightUnit(String unit) async {
    state = state.copyWith(weightUnit: unit);
    await _persist();
  }

  Future<void> toggleNotification(String key, bool value) async {
    state = switch (key) {
      'stock' => state.copyWith(notifyStock: value),
      'orders' => state.copyWith(notifyOrders: value),
      'deliveries' => state.copyWith(notifyDeliveries: value),
      'reports' => state.copyWith(notifyReports: value),
      'analysis' => state.copyWith(notifyAnalysis: value),
      'critical' => state.copyWith(notifyCritical: value),
      _ => state,
    };
    await _persist();
  }

  Future<String> exportBackup() async {
    return state.toJson().toString();
  }

  Future<void> restoreBackup(Map<dynamic, dynamic> json) async {
    state = AppSettings.fromJson(json);
    await _persist();
  }

  Future<void> updateProfile({
    required String profileName,
    required String profileProfession,
  }) async {
    state = state.copyWith(
      profileName: profileName.trim(),
      profileProfession: profileProfession.trim(),
    );
    await _persist();
  }

  Future<void> clearAllLocalData() async {
    await Hive.box('projects').clear();
    await _box.clear();
    state = AppSettings();
    await _persist();
  }
}
