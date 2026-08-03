import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../../domain/entities/company_info.dart';

class CompanyInfoNotifier extends StateNotifier<CompanyInfo> {
  CompanyInfoNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'companyInfo';

  static CompanyInfo _load(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return CompanyInfo.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return const CompanyInfo();
  }

  void _persist() => _box.put(_key, jsonEncode(state.toJson()));

  void update({
    String? name,
    String? taxNo,
    String? address,
    String? email,
    String? phone,
  }) {
    state = state.copyWith(
      name: name,
      taxNo: taxNo,
      address: address,
      email: email,
      phone: phone,
    );
    _persist();
  }

  void replace(CompanyInfo info) {
    state = info;
    _persist();
  }

  void clear() {
    state = const CompanyInfo();
    _box.delete(_key);
  }
}

final companyInfoProvider =
    StateNotifierProvider<CompanyInfoNotifier, CompanyInfo>((ref) {
  return CompanyInfoNotifier(ref.watch(settingsBoxProvider));
});
