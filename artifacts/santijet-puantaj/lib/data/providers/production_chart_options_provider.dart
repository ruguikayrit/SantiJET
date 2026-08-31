import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../services/production_chart_options.dart';

class ProductionChartOptionsNotifier
    extends StateNotifier<ProductionChartOptions> {
  ProductionChartOptionsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'production_chart_options';

  static ProductionChartOptions _load(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return ProductionChartOptions.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    return const ProductionChartOptions();
  }

  void save(ProductionChartOptions options) {
    state = options;
    _box.put(_key, jsonEncode(options.toJson()));
  }
}

final productionChartOptionsProvider = StateNotifierProvider<
    ProductionChartOptionsNotifier, ProductionChartOptions>((ref) {
  return ProductionChartOptionsNotifier(ref.watch(settingsBoxProvider));
});
